abstract final class AppConstants {
  static const String appName = 'Qaari SL Staff';

  /// Production staff APK default. Override for local/dev:
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
  /// Hot reload does **not** apply a new dart-define — full rebuild required.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://qaari.mahaysaa.com',
  );

  static const String apiPrefix = '/api/staff';
}
