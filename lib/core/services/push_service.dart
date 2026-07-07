import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Push notifications via **ntfy.sh self-hosted** (open-source, MIT)
/// + `flutter_local_notifications` (apresentação).
///
/// Arquitetura (sem Firebase):
///
/// ```
///   ┌──────────┐   1. UPSERT  ┌──────────┐
///   │   App    │ ───────────► │ Backend  │
///   │ Flutter  │              │  (NTFY)  │
///   └────┬─────┘   topic UUID └────┬─────┘
///        │                         │ 2. publish
///        │ 3. subscribe WSS        ▼
///        └─────────────────────► ntfy.sh
///                                  │
///                                  └─► JSON: {title, message, click}
/// ```
///
/// 1. App gera UUID v4 local (uma vez · persistido em SharedPreferences).
/// 2. Faz UPSERT no backend via `/me/push-token` com o UUID como `endpoint`.
/// 3. Conecta WSS em `<NTFY_BASE_URL>/<topic>/ws` em foreground.
/// 4. Quando backend cria notificação no banco, dispatcher publica em ntfy.
/// 5. App recebe via WSS → mostra notif visual + emite deepLink ao tocar.
///
/// **Limitações**:
/// - WSS só fica ativo em foreground. Para background real precisa:
///   - iOS: APNs próprio (out-of-scope)
///   - Android: app ntfy instalado + UnifiedPush
/// - Para MVP, foreground + abertura periódica de notificações basta.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _log = Logger(printer: PrettyPrinter(methodCount: 0));
  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// URL base do servidor ntfy. Configurável via `--dart-define=NTFY_BASE_URL=...`
  /// Default DEV: `http://localhost:8080` (Docker self-host).
  static const _ntfyBaseUrl = String.fromEnvironment(
    'NTFY_BASE_URL',
    defaultValue: 'http://184.107.179.209:8080',
  );

  /// Chave do topic UUID no SharedPreferences.
  static const _topicPrefsKey = 'ntfy_topic_v1';

  /// Stream de deep links disparados por toque em notificação.
  /// O router escuta isso e faz `context.go(link)`.
  final _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get onDeepLink => _deepLinkController.stream;

  /// Topic ntfy do dispositivo. Mantém o nome `fcmToken` por compatibilidade
  /// com `main.dart` e `auth_repository.dart`. Conceitualmente é o `endpoint`
  /// que o backend usa como nome do topic no ntfy.
  String? fcmToken;

  /// Endpoint do topic (alias semântico de [fcmToken]).
  String? get topicEndpoint => fcmToken;

  /// URL completa de subscribe WSS (gerada pelo backend ao registrar).
  String? subscribeUrl;

  /// Chamado quando o topic é gerado/recuperado. App registra no backend.
  void Function(String token)? onTokenRefresh;

  /// Canal Android para notificações UNISISM.
  static const _channel = AndroidNotificationChannel(
    'unisism_paciente_default',
    'Avisos do UNISISM',
    description:
        'Atualizações sobre encaminhamento, TFD e Secretaria de Saúde.',
    importance: Importance.high,
  );

  /// Estado do WebSocket.
  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  Future<void> init() async {
    if (_initialized) return;

    // ─── 1. Local notifications ────────────────────────────────
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final link = resp.payload;
        if (link != null && link.isNotEmpty) {
          _deepLinkController.add(link);
        }
      },
    );

    await _createChannel();

    // ─── 2. Topic UUID local ───────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    var topic = prefs.getString(_topicPrefsKey);
    if (topic == null || topic.isEmpty) {
      topic = 'unisism-${const Uuid().v4().replaceAll('-', '')}';
      await prefs.setString(_topicPrefsKey, topic);
      _log.i('Topic ntfy gerado: ${topic.substring(0, 20)}...');
    } else {
      _log.i('Topic ntfy recuperado: ${topic.substring(0, 20)}...');
    }
    fcmToken = topic;
    subscribeUrl = _buildSubscribeUrl(topic);

    // Avisa imediatamente (main.dart registra no backend)
    onTokenRefresh?.call(topic);

    // ─── 3. Conecta WebSocket ──────────────────────────────────
    _connectWebSocket();

    _initialized = true;
  }

  String _buildSubscribeUrl(String topic) {
    final base = _ntfyBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    return '$base/$topic/ws';
  }

  void _connectWebSocket() {
    final topic = fcmToken;
    if (topic == null) return;

    _reconnectTimer?.cancel();
    final url = _buildSubscribeUrl(topic);

    try {
      _ws = WebSocketChannel.connect(Uri.parse(url));
      _log.i('WSS conectando: $url');
      _reconnectAttempt = 0;

      _wsSub = _ws!.stream.listen(
        _onWsMessage,
        onError: (Object e) {
          _log.w('WSS erro: $e');
          _scheduleReconnect();
        },
        onDone: () {
          _log.w('WSS fechou');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _log.w('WSS falhou em conectar: $e');
      _scheduleReconnect();
    }
  }

  /// Backoff exponencial: 2s, 4s, 8s, 16s, 30s (cap).
  void _scheduleReconnect() {
    _wsSub?.cancel();
    _ws?.sink.close();
    _ws = null;

    _reconnectAttempt = (_reconnectAttempt + 1).clamp(1, 5);
    final delay = Duration(seconds: 2 * (1 << (_reconnectAttempt - 1)));
    final capped = delay > const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : delay;

    _log.i('WSS reconectando em ${capped.inSeconds}s');
    _reconnectTimer = Timer(capped, _connectWebSocket);
  }

  /// Mensagem ntfy chega como JSON. O backend (`NtfyPushProvider`) envia o
  /// corpo aninhado em `message` (string JSON) com:
  /// ```json
  /// {
  ///   "id": "abc123",
  ///   "event": "message",
  ///   "topic": "unisism-xxx",
  ///   "title": "Encaminhamento aprovado",
  ///   "click": "/encaminhamento/uuid",        // header Click do ntfy
  ///   "message": "{\"message\":\"corpo real\",\"meta\":{\"deepLink\":\"...\"}}"
  /// }
  /// ```
  /// Estratégia: usa `click` se presente; senão extrai `meta.deepLink` do JSON
  /// interno. O texto exibido é `meta.message` se houver, senão raw.
  Future<void> _onWsMessage(dynamic raw) async {
    try {
      final str = raw is String ? raw : utf8.decode(raw as List<int>);
      _log.i('WSS recv: ${str.length > 120 ? "${str.substring(0, 120)}..." : str}');
      final json = jsonDecode(str) as Map<String, dynamic>;
      final event = json['event'] as String?;

      // ntfy envia eventos open/keepalive/poll_request — só msg interessa
      if (event != 'message') {
        _log.d('WSS event ignorado: $event');
        return;
      }

      final title = (json['title'] as String?) ?? 'UNISISM';
      var body = (json['message'] as String?) ?? '';
      // Prioriza header `Click` do ntfy; fallback pro meta.deepLink interno
      String? click = json['click'] as String?;

      // Tenta des-aninhar o body (backend envia JSON dentro de message)
      try {
        final inner = jsonDecode(body);
        if (inner is Map<String, dynamic>) {
          if (inner['message'] is String) {
            body = inner['message'] as String;
          }
          final meta = inner['meta'];
          if (meta is Map<String, dynamic>) {
            final innerDeep = meta['deepLink'];
            if ((click == null || click.isEmpty) && innerDeep is String) {
              click = innerDeep;
            }
          }
        }
      } catch (_) {
        // body não é JSON — usa raw direto (provavelmente publish manual)
      }

      _log.i('📨 push: "$title" · click=${click ?? "-"}');

      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'unisism_paciente_default',
            'Avisos do UNISISM',
            channelDescription:
                'Atualizações sobre encaminhamento, TFD e Secretaria de Saúde.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: click,
      );
    } catch (e) {
      _log.w('Falha ao processar mensagem WSS: $e');
    }
  }

  Future<void> _createChannel() async {
    if (!Platform.isAndroid) return;
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
  }

  /// Mostra uma notificação local manualmente (útil pra testes/lembretes).
  Future<void> showLocal({
    required String titulo,
    required String corpo,
    String? deepLink,
  }) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      corpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'unisism_paciente_default',
          'Avisos do UNISISM',
          channelDescription:
              'Atualizações sobre encaminhamento, TFD e Secretaria de Saúde.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: deepLink,
    );
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _wsSub?.cancel();
    _ws?.sink.close();
    _deepLinkController.close();
  }
}
