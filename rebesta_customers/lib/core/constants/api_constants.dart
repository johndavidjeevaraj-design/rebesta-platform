class ApiConstants {
  /// Single source of truth for the backend URL.
  ///
  /// Switch environment without editing code:
  ///   emulator      flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  ///   physical/LAN  flutter run --dart-define=API_BASE_URL=http://172.16.255.167:3000
  ///   production    flutter build apk --release --dart-define=API_BASE_URL=https://api.rebesta.com
  ///
  /// The default is only a dev fallback - always pass --dart-define for release.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

}