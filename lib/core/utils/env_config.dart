class EnvConfig {
  EnvConfig._();

  // Toggle this for dev vs prod
  static const _env = _Env.dev;

  static String get baseUrl {
    switch (_env) {
      case _Env.dev:
        return 'http://192.168.1.100:8080/api/v1'; // update to your local IP
      case _Env.prod:
        return 'https://api.feros.in/api/v1';
    }
  }

  static bool get isDebug => _env == _Env.dev;
}

enum _Env { dev, prod }
