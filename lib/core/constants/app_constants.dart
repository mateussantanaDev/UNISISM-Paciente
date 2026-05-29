/// Constantes globais.
class AppConstants {
  AppConstants._();

  /// Base URL da API. Em produção viria de .env / --dart-define.
  /// Por enquanto fica no código pra facilitar dev — quando integrar com
  /// backend real, expor via `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Quando `true` o app roda com dados em memória (sem rede).
  /// Útil pra desenvolver UI antes do backend estar pronto.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  /// Versão do app exibida no footer / sobre.
  static const String appVersion = '0.1.0';
  static const String buildCode = '2026.05';

  /// Chaves do flutter_secure_storage.
  static const String kTokenAccess = 'unisism.token.access';
  static const String kTokenRefresh = 'unisism.token.refresh';
  static const String kFcmToken = 'unisism.fcm.token';
  static const String kBiometricEnabled = 'unisism.biometric.enabled';
}
