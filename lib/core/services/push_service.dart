import 'dart:async';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

/// Handler de mensagens em background — tem que ser top-level (não closure).
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM bg] ${message.notification?.title}');
}

/// Push notifications: FCM (transporte) + flutter_local_notifications (apresentação).
///
/// Padrão:
/// 1. Em background, o sistema mostra a notificação automaticamente.
/// 2. Em foreground, recebemos via FCM e re-mostramos com `flutter_local_notifications`
///    pra parecer notificação do sistema (caso contrário só aparece no app).
/// 3. Em ambos, ao tocar, o `data.deepLink` é emitido via [onDeepLink].
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _log = Logger(printer: PrettyPrinter(methodCount: 0));
  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Stream de deep links disparados por toque em notificação.
  /// O router escuta isso e faz `context.go(link)`.
  final _deepLinkController = StreamController<String>.broadcast();
  Stream<String> get onDeepLink => _deepLinkController.stream;

  /// FCM token atual. Null se Firebase não estiver inicializado.
  String? fcmToken;

  /// Chamado quando o token muda. App registra no backend.
  void Function(String token)? onTokenRefresh;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Local notifications — funciona mesmo sem Firebase
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

    // 2. Firebase — best effort. Sem google-services.json, vai falhar e seguimos sem push.
    try {
      await Firebase.initializeApp();
      await _setupFirebase();
    } catch (e) {
      _log.w('Firebase não inicializado (push remoto desabilitado): $e');
    }

    _initialized = true;
  }

  Future<void> _setupFirebase() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    // Token inicial
    fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      _log.i('FCM token: ${fcmToken!.substring(0, 18)}...');
      onTokenRefresh?.call(fcmToken!);
    }
    messaging.onTokenRefresh.listen((t) {
      fcmToken = t;
      onTokenRefresh?.call(t);
    });

    // Foreground → re-emite como local notification
    FirebaseMessaging.onMessage.listen((msg) async {
      final n = msg.notification;
      if (n == null) return;
      final payload = msg.data['deepLink']?.toString();
      await _local.show(
        msg.messageId.hashCode,
        n.title ?? 'UNISISM',
        n.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            color: const Color.fromARGB(255, 30, 58, 138),
          ),
          iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        payload: payload,
      );
    });

    // Tap a partir do background (app aberto via notificação)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final link = msg.data['deepLink']?.toString();
      if (link != null && link.isNotEmpty) _deepLinkController.add(link);
    });

    // App aberto a partir de notificação (cold start)
    final initial = await messaging.getInitialMessage();
    final link = initial?.data['deepLink']?.toString();
    if (link != null && link.isNotEmpty) {
      // Pequeno delay pra garantir router montado
      Future.delayed(const Duration(milliseconds: 300), () => _deepLinkController.add(link));
    }

    await _createChannel();
  }

  static const _channel = AndroidNotificationChannel(
    'unisism_paciente_default',
    'Avisos do UNISISM',
    description: 'Atualizações sobre encaminhamento, TFD e Secretaria de Saúde.',
    importance: Importance.high,
  );

  Future<void> _createChannel() async {
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
  }

  /// Mostra uma notificação local manualmente (útil pra testes / lembretes).
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
          channelDescription: 'Atualizações sobre encaminhamento, TFD e Secretaria de Saúde.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      payload: deepLink,
    );
  }

  void dispose() => _deepLinkController.close();
}
