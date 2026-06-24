class EnvConfig {
  EnvConfig._();

  static const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

  static bool get isStg => _flavor == 'stg';
  static bool get isProd => _flavor == 'prod';

  static String get baseUrl {
    switch (_flavor) {
      case 'stg':
        return 'https://stg.console.feros.in/api/v1';
      case 'dev':
        return 'http://192.168.1.100:8080/api/v1';
      default:
        return 'https://console.feros.in/api/v1';
    }
  }

  static bool get isDebug => _flavor == 'dev';
}
