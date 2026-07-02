import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/api_exception.dart';
import '../data/models/paciente.dart';
import 'providers.dart';

/// Estado de autenticação global.
class AuthState {
  const AuthState({
    this.status = AuthStatus.checking,
    this.paciente,
    this.errorMessage,
  });

  final AuthStatus status;
  final Paciente? paciente;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && paciente != null;
  bool get isLoading =>
      status == AuthStatus.checking || status == AuthStatus.signingIn;

  /// True quando o paciente está logado mas ainda com a senha provisória
  /// (= CPF dígitos). O router força fluxo bloqueante em
  /// `/perfil/trocar-senha` enquanto isso for `true`.
  bool get requiresPasswordChange =>
      isAuthenticated && (paciente?.senhaProvisoria ?? false);

  AuthState copyWith({
    AuthStatus? status,
    Paciente? paciente,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      paciente: paciente ?? this.paciente,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

enum AuthStatus { checking, signingIn, authenticated, unauthenticated, error }

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(checkSession);
    return const AuthState();
  }

  Future<void> checkSession() async {
    final api = ref.read(apiClientProvider);
    final auth = ref.read(authRepositoryProvider);
    final has = await api.hasSession();
    if (!has) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final me = await auth.me();
      state = AuthState(status: AuthStatus.authenticated, paciente: me);
    } catch (_) {
      await api.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String cpf, required String senha}) async {
    state = state.copyWith(status: AuthStatus.signingIn, clearError: true);
    try {
      final sessao = await ref.read(authRepositoryProvider).login(
            cpf: cpf,
            senha: senha,
          );
      state = AuthState(
        status: AuthStatus.authenticated,
        paciente: sessao.paciente,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _humanize(e),
      );
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Troca a senha do paciente autenticado. Após sucesso, refaz `me()` pra
  /// que o estado reflita `senhaProvisoria=false` — o router então libera
  /// navegação fora de `/perfil/trocar-senha`.
  ///
  /// Lança em caso de erro pra UI tratar inline (não muda o estado).
  Future<void> trocarSenha({
    required String senhaAtual,
    required String novaSenha,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.trocarSenha(senhaAtual: senhaAtual, novaSenha: novaSenha);
    // Confirma que o backend zerou `senhaProvisoria`.
    try {
      final me = await repo.me();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        paciente: me,
      );
    } catch (_) {
      // Sem rede pra refetch — zera local mesmo assim.
      final atual = state.paciente;
      if (atual != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          paciente: atual.copyWith(senhaProvisoria: false),
        );
      }
    }
  }

  String _humanize(Object e) {
    if (e is ApiException) return e.mensagemAmigavel;
    return 'Não conseguimos entrar. Tente de novo.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
