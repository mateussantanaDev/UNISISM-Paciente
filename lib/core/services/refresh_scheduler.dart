import 'dart:async';
import 'package:logger/logger.dart';

import '../../data/repositories/auth_repository.dart';

/// Agenda refresh **proativo** do access token quando faltar ~5 min pra
/// expirar. Evita o cenário "401 → retry com refresh → atraso percebido".
///
/// Uso típico (em `main.dart`):
/// ```dart
/// final scheduler = RefreshScheduler(authRepo);
/// scheduler.schedule(expiresAt: sessao.expiresAt);
/// // ao logout: scheduler.cancel();
/// ```
///
/// Cada refresh bem-sucedido **reagenda** automaticamente (loop perpétuo
/// até logout). Se o refresh falhar, o próximo 401 cai no retry reativo do
/// `ApiClient.interceptor` como fallback.
class RefreshScheduler {
  RefreshScheduler(this._auth);

  final AuthRepository _auth;
  final _log = Logger(printer: PrettyPrinter(methodCount: 0));

  Timer? _timer;

  /// Margem antes do `expiresAt`. 5 min — bate com o doc do backend §4.2.
  static const Duration _margem = Duration(minutes: 5);

  /// Atraso mínimo entre tentativas (se algo der errado).
  static const Duration _minDelay = Duration(seconds: 30);

  /// Reagenda baseado num `expiresAt` específico (chamar após login/refresh).
  void schedule({required DateTime expiresAt}) {
    cancel();
    final agora = DateTime.now();
    final alvo = expiresAt.subtract(_margem);
    final delay = alvo.isAfter(agora)
        ? alvo.difference(agora)
        : _minDelay;
    _log.i('⏱ Refresh proativo agendado pra ${_fmt(delay)} de agora');
    _timer = Timer(delay, _run);
  }

  /// Cancela o timer ativo. Chamar no logout.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _run() async {
    try {
      _log.i('⏱ Disparando refresh proativo');
      final sessao = await _auth.refresh();
      // Reagenda baseado no novo expiresAt.
      schedule(expiresAt: sessao.expiresAt);
    } catch (e) {
      _log.w('⏱ Refresh proativo falhou ($e) — fallback reativo cuida no 401');
      // Não reagenda. Próximo 401 trata.
    }
  }

  static String _fmt(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}min';
    if (d.inMinutes > 0) return '${d.inMinutes}min ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}
