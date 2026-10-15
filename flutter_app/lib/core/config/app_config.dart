enum ApiMode { mock, server }

class AppConfig {
  final ApiMode apiMode;
  final String apiBaseUrl;
  final String serviceTimeZone;

  const AppConfig({
    this.apiMode = const String.fromEnvironment('ESEL_API_MODE') == 'mock'
        ? ApiMode.mock
        : ApiMode.server,
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/api',
    ),
    this.serviceTimeZone = 'Asia/Seoul',
  });

  static AppConfig current = const AppConfig();

  bool get isMock => apiMode == ApiMode.mock;
  bool get isServer => apiMode == ApiMode.server;
}
