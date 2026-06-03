class ApiConstants {
  static const String baseUrl =
      'https://qr-system-production-a93f.up.railway.app';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/registro';

  static const String objetosEndpoint = '/objetos';
  static const String objetosPorIdEndpoint = '/objetos';
  static const String objetosPorQrEndpoint = '/objetos/qr';

  static const String escaneoEndpoint = '/escaneos';
  static const String historialEscaneoEndpoint = '/escaneos/historial';

  static const int timeoutSeconds = 30;
}