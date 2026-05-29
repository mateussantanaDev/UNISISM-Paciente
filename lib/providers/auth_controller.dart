import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('senha123')) return 'CPF ou senha inválidos.';
    if (msg.contains('NETWORK')) return 'Sem conexão. Verifique sua internet.';
    return 'Não conseguimos entrar. Tente de novo.';
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
