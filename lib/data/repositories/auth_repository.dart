import '../api/api_client.dart';
import '../models/paciente.dart';
import '../models/sessao.dart';

/// Auth do paciente. Backend real é `unisism-ubs@0.18.0+` em
/// **`/v1/paciente-app/*`**. 100% wired contra HTTP real — sem mock.
///
/// Endpoints consumidos:
///   POST  /paciente-app/auth/login              { cpf, senha } → Sessao
///   POST  /paciente-app/auth/refresh            { refreshToken } → Sessao    (v0.18.0+)
///   POST  /paciente-app/auth/logout                              → 204
///   POST  /paciente-app/auth/trocar-senha       { senhaAtual, novaSenha } → 204
///   POST  /paciente-app/auth/esqueci-senha      { cpf } → 204 (anti-enum, v0.11.0+)
///   POST  /paciente-app/auth/redefinir-senha    { token, novaSenha } → 204   (v0.11.0+)
///   POST  /paciente-app/auth/ativar-conta       { cpf, dataNascimento, senha } → 204  (legado)
///   GET   /paciente-app/me                                      → Paciente
///   POST  /paciente-app/me/push-token  { endpoint, provider:'NTFY', plataforma } → 204
abstract class AuthRepository {
  Future<Sessao> login({required String cpf, required String senha});
  Future<Sessao> refresh();
  Future<void> logout();
  Future<Paciente> me();
  Future<void> esqueciSenha({required String cpf});
  Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
  });
  Future<void> registrarDispositivo({
    required String fcmToken,
    required String plataforma,
  });
  Future<void> revogarDispositivo({String? endpoint});
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  });
}

class AuthRepositoryHttp implements AuthRepository {
  AuthRepositoryHttp(this.api);
  final ApiClient api;

  /// CPF para envio: backend aceita formatado, mas mandamos só dígitos
  /// pra evitar logs sujos e divergência de hashing.
  static String _digits(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');

  @override
  Future<Sessao> login({required String cpf, required String senha}) async {
    final r = await api.post<Map<String, dynamic>>(
      '/paciente-app/auth/login',
      body: {'cpf': _digits(cpf), 'senha': senha},
    );
    final sessao = Sessao.fromJson(r);
    await api.setTokens(
      access: sessao.accessToken,
      refresh: sessao.refreshToken,
    );
    return sessao;
  }

  @override
  Future<Sessao> refresh() async {
    final refresh = await api.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw StateError('Sem refresh token. Faça login novamente.');
    }
    final r = await api.post<Map<String, dynamic>>(
      '/paciente-app/auth/refresh',
      body: {'refreshToken': refresh},
    );
    final sessao = Sessao.fromJson(r);
    await api.setTokens(
      access: sessao.accessToken,
      refresh: sessao.refreshToken,
    );
    return sessao;
  }

  @override
  Future<void> logout() async {
    // Revoga push token ANTES do logout (depois invalida o JWT).
    try {
      await revogarDispositivo();
    } catch (_) {/* não crítico — backend tem cron de cleanup */}
    try {
      await api.post('/paciente-app/auth/logout');
    } finally {
      await api.clearTokens();
    }
  }

  @override
  Future<Paciente> me() async {
    final r = await api.get<Map<String, dynamic>>('/paciente-app/me');
    return Paciente.fromJson(r);
  }

  @override
  Future<void> esqueciSenha({required String cpf}) async {
    // Backend v0.11.0+ — resposta sempre 204 (anti-enumeration).
    // Rate-limit 3/h por CPF+IP é tratado no servidor (429 RATE_LIMIT).
    await api.post(
      '/paciente-app/auth/esqueci-senha',
      body: {'cpf': _digits(cpf)},
    );
  }

  @override
  Future<void> redefinirSenha({
    required String token,
    required String novaSenha,
  }) async {
    // Backend v0.11.0+. App recebe `token` via deep-link do email.
    // Erros possíveis:
    //   404 TOKEN_INVALIDO · 401 TOKEN_EXPIRADO · 409 TOKEN_JA_USADO
    //   422 SENHA_FRACA · 422 SENHA_IGUAL_ATUAL · 429 RATE_LIMIT
    await api.post(
      '/paciente-app/auth/redefinir-senha',
      body: {'token': token, 'novaSenha': novaSenha},
    );
  }

  @override
  Future<void> registrarDispositivo({
    required String fcmToken,
    required String plataforma,
  }) async {
    // Push via ntfy.sh self-hosted (v0.18+ · sem Firebase).
    // `fcmToken` aqui é, na verdade, o topic UUID gerado pelo app.
    // Backend faz UPSERT em paciente_dispositivos e retorna subscribeUrl WSS.
    final platf = plataforma.toLowerCase().contains('ios') ? 'ios' : 'android';
    try {
      await api.post<Map<String, dynamic>>(
        '/paciente-app/me/push-token',
        body: {
          'endpoint': fcmToken,
          'provider': 'NTFY',
          'plataforma': platf,
        },
      );
    } catch (_) {
      // Falha silenciosa: push é nice-to-have, não pode derrubar login.
    }
  }

  @override
  Future<void> revogarDispositivo({String? endpoint}) async {
    // DELETE /paciente-app/me/push-token { endpoint? }
    // Sem endpoint: remove TODOS os dispositivos da conta (logout total).
    // Com endpoint: remove só o específico.
    try {
      await api.dio.delete<dynamic>(
        '/paciente-app/me/push-token',
        data: endpoint != null ? {'endpoint': endpoint} : null,
      );
    } catch (_) {/* falha silenciosa — cron faz cleanup */}
  }

  @override
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    await api.post(
      '/paciente-app/auth/trocar-senha',
      body: {'senhaAtual': senhaAtual, 'novaSenha': novaSenha},
    );
  }
}

