class ApiConstants {
  // Cambiar 'localhost' por la IP del servidor si accedes desde otro dispositivo
  static const String baseUrl = 'http://192.168.0.142:8000';
  
  // Endpoints de autenticación
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/registro';
  
  // Endpoints de objetos
  static const String objetosEndpoint = '/objetos';
  static const String objetosPorIdEndpoint = '/objetos';
  static const String objetosPorQrEndpoint = '/objetos/qr';
  
  // Endpoints de escaneos
  static const String escaneoEndpoint = '/escaneos';
  static const String historialEscaneoEndpoint = '/escaneos/historial';
  
  // Timeout en segundos
  static const int timeoutSeconds = 30;
}
