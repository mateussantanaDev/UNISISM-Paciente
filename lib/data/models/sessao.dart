import 'paciente.dart';

/// Sessão autenticada.
///
/// Backend real (`POST /v1/paciente-app/auth/login` v0.18.0+) retorna:
/// ```json
/// {
///   "token": "...",
///   "refreshToken": "...",
///   "expiresIn": 1800,
///   "refreshExpiresIn": 2592000,
///   "paciente": {...}
/// }
/// ```
///
/// O app converte para o shape interno `{accessToken, refreshToken, expiresAt}`.
/// Backends antigos sem refresh fazem `refreshToken=""` e o middleware Dio
/// cai pro `onUnauthorized` quando o access vencer.
class Sessao {
  const Sessao({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.refreshExpiresAt,
    required this.paciente,
  });

  final String accessToken;

  /// Vazio quando o backend não suporta refresh.
  final String refreshToken;

  /// Quando o **access token** vence.
  final DateTime expiresAt;

  /// Quando o **refresh token** vence. Null em backends sem refresh.
  final DateTime? refreshExpiresAt;

  final Paciente paciente;

  bool get hasRefreshToken => refreshToken.isNotEmpty;

  /// Shape do backend real (`/v1/paciente-app/auth/{login,refresh}` v0.18.0+).
  factory Sessao.fromJson(Map<String, dynamic> j) {
    final expiresIn = (j['expiresIn'] as num?)?.toInt() ?? 0;
    final refreshExpiresIn = (j['refreshExpiresIn'] as num?)?.toInt();
    final now = DateTime.now();
    return Sessao(
      // Backend usa `token`, mantém compat com `accessToken` caso o app role mock.
      accessToken: (j['token'] ?? j['accessToken']) as String,
      refreshToken: (j['refreshToken'] as String?) ?? '',
      expiresAt: j['expiresAt'] != null
          ? DateTime.parse(j['expiresAt'] as String)
          : now.add(Duration(seconds: expiresIn)),
      refreshExpiresAt: refreshExpiresIn != null
          ? now.add(Duration(seconds: refreshExpiresIn))
          : null,
      paciente: Paciente.fromJson(j['paciente'] as Map<String, dynamic>),
    );
  }
}
