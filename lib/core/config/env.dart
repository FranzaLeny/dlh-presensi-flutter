// ====================================
// Environment Configuration
// ====================================

class AppConfig {
  AppConfig._();

  /// Base URL API backend
  static const String apiUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://localhost:5000');

  /// Base URL Better Auth
  static const String betterAuthUrl = String.fromEnvironment(
    'BETTER_AUTH_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// Timeout HTTP request (dalam detik)
  static const int httpTimeoutSeconds = 15;

  /// Versi aplikasi
  static const String appVersion = '1.0.0';
}
