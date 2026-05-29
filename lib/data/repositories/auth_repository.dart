import '../api/api_client.dart';
import '../models/paciente.dart';
import '../models/sessao.dart';
import 'mock/mock_seed.dart';

/// Auth do paciente. Contrato esperado do backend:
///
/// POST  /auth/paciente/login              { cpf, senha }              → Sessao
/// POST  /auth/paciente/refresh            { refreshToken }            → Sessao
/// POST  /auth/paciente/logout                                          → 204
/// GET   /auth/paciente/me                                              → Paciente
/// POST  /auth/paciente/esqueci-senha      { cpf }                      → 204
/// POST  /auth/paciente/redefinir-senha    { token, novaSenha }         → 204
/// POST  /auth/paciente/registrar-dispositivo { fcmToken, plataforma }  → 204
abstract class AuthRepository {
  Future<Sessao> login({required String cpf, required String senha});
  Future<Sessao> refresh();
  Future<void> logout();
  Future<Paciente> me();
  Future<void> esqueciSenha({required String cpf});
  Future<void> redefinirSenha({required String token, required String novaSenha});
  Future<void> registrarDispositivo({required String fcmToken, required String plataforma});
}

class AuthRepositoryHttp implements AuthRepository {
  AuthRepositoryHttp(this.api);
  final ApiClient api;

  @override
  Future<Sessao> login({required String cpf, required String senha}) async {
    final r = await api.post<Map<String, dynamic>>(
      '/auth/paciente/login',
      body: {'cpf': cpf, 'senha': senha},
    );
    final sessao = Sessao.fromJson(r);
    await api.setTokens(access: sessao.accessToken, refresh: sessao.refreshToken);
    return sessao;
  }

  @override
  Future<Sessao> refresh() async {
    final refresh = await api.getRefreshToken();
    if (refresh == null) throw StateError('No refresh token');
    final r = await api.post<Map<String, dynamic>>(
      '/auth/paciente/refresh',
      body: {'refreshToken': refresh},
    );
    final sessao = Sessao.fromJson(r);
    await api.setTokens(access: sessao.accessToken, refresh: sessao.refreshToken);
    return sessao;
  }

  @override
  Future<void> logout() async {
    try {
      await api.post('/auth/paciente/logout');
    } finally {
      await api.clearTokens();
    }
  }

  @override
  Future<Paciente> me() async {
    final r = await api.get<Map<String, dynamic>>('/auth/paciente/me');
    return Paciente.fromJson(r);
  }

  @override
  Future<void> esqueciSenha({required String cpf}) async {
    await api.post('/auth/paciente/esqueci-senha', body: {'cpf': cpf});
  }

  @override
  Future<void> redefinirSenha({required String token, required String novaSenha}) async {
    await api.post('/auth/paciente/redefinir-senha',
        body: {'token': token, 'novaSenha': novaSenha});
  }

  @override
  Future<void> registrarDispositivo({
    required String fcmToken,
    required String plataforma,
  }) async {
    await api.post('/auth/paciente/registrar-dispositivo',
        body: {'fcmToken': fcmToken, 'plataforma': plataforma});
  }
}

class AuthRepositoryMock implements AuthRepository {
  AuthRepositoryMock(this.api);
  final ApiClient api;

  @override
  Future<Sessao> login({required String cpf, required String senha}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (senha != 'senha123') {
      throw StateError('Credenciais inválidas. Use senha123 para entrar (mock).');
    }
    const access = 'mock-access-token';
    const refresh = 'mock-refresh-token';
    await api.setTokens(access: access, refresh: refresh);
    return Sessao(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      paciente: MockSeed.paciente,
    );
  }

  @override
  Future<Sessao> refresh() async {
    return Sessao(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      paciente: MockSeed.paciente,
    );
  }

  @override
  Future<void> logout() async {
    await api.clearTokens();
  }

  @override
  Future<Paciente> me() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockSeed.paciente;
  }

  @override
  Future<void> esqueciSenha({required String cpf}) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> redefinirSenha({required String token, required String novaSenha}) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<void> registrarDispositivo({
    required String fcmToken,
    required String plataforma,
  }) async {
    // no-op no mock
  }
}
