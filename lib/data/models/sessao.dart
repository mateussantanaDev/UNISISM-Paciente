import 'paciente.dart';

/// Sessão autenticada (resposta de `/auth/login` e `/auth/me`).
class Sessao {
  const Sessao({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.paciente,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final Paciente paciente;

  factory Sessao.fromJson(Map<String, dynamic> j) => Sessao(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        expiresAt: DateTime.parse(j['expiresAt'] as String),
        paciente: Paciente.fromJson(j['paciente'] as Map<String, dynamic>),
      );
}
