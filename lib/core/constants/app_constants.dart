/// Constantes globais.
class AppConstants {
  AppConstants._();

  /// Base URL da API. **Backend real `unisism-ubs@0.18.0` roda em `3333/v1`**.
  ///
  /// URLs por ambiente:
  ///   Mac / iOS Simulator     → `http://192.168.1.13:3333/v1`
  ///   Android Emulator         → `http://10.0.2.2:3333/v1`
  ///   Device físico Wi-Fi      → `http://<ip-mac>:3333/v1`
  ///   Produção                 → `https://api.unisism.aguasbelas.pe.gov.br/v1`
  ///
  /// Override via `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.0.101:3333/v1',
  );

  /// Versão do app exibida no footer / sobre.
  static const String appVersion = '1.0.0';
  static const String buildCode = '2026.06';

  /// Chaves do flutter_secure_storage.
  static const String kTokenAccess = 'unisism.token.access';
  static const String kTokenRefresh = 'unisism.token.refresh';
  static const String kFcmToken = 'unisism.fcm.token';
  static const String kBiometricEnabled = 'unisism.biometric.enabled';
}
