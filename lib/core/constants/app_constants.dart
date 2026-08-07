abstract final class AppConstants {
  static const String appName = 'Qaari SL Staff';

  /// Pass with `--dart-define=API_BASE_URL=http://HOST:8000`
  ///
  /// - Physical phone (USB tether): PC Ethernet / Samsung NDIS IPv4, e.g. `http://10.172.77.244:8000`
  /// - Emulator only: `http://10.0.2.2:8000`
  /// Hot reload does **not** apply a new dart-define — full restart required.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.172.77.244:8000',
  );

  static const String apiPrefix = '/api/staff';
}
