import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/objeto_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String? _token;

  void setToken(String token) {
    _token = token;
  }

  String? getToken() {
    return _token;
  }

  void logout() {
    _token = null;
  }

  // Headers comunes
  Map<String, String> _getHeaders({bool withAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // AUTENTICACIÓN
  Future<Map<String, dynamic>> login(
    String correo,
    String contrasena,
  ) async {
    try {
      final url = Uri.parse('http://192.168.0.142:8000/auth/login');

      print('🔐 [LOGIN] URL: $url');
      print('🔐 [LOGIN] Headers: ${_getHeaders(withAuth: false)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({
          'correo': correo,
          'contrasena': contrasena,
        }),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('🔐 [LOGIN] Status Code: ${response.statusCode}');
      print('🔐 [LOGIN] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        print('🔐 [LOGIN] ✅ Token obtenido exitosamente');
        return {'success': true, 'data': data};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al iniciar sesión';
        print('🔐 [LOGIN] ❌ Error: $errorMsg');
        return {
          'success': false,
          'error': errorMsg
        };
      }
    } on TimeoutException {
      print('🔐 [LOGIN] ⏱️ Timeout: Tiempo de conexión agotado');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('🔐 [LOGIN] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  Future<Map<String, dynamic>> registro(
    String nombre,
    String correo,
    String contrasena,
    String rol,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');
      print('📝 [REGISTRO] URL: $url');
      print('📝 [REGISTRO] Headers: ${_getHeaders(withAuth: false)}');
      
      final response = await http.post(
        url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'contrasena': contrasena,
          'rol': rol,
        }),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('📝 [REGISTRO] Status Code: ${response.statusCode}');
      print('📝 [REGISTRO] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('📝 [REGISTRO] ✅ Usuario registrado exitosamente');
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al registrar';
        print('📝 [REGISTRO] ❌ Error: $errorMsg');
        return {
          'success': false,
          'error': errorMsg
        };
      }
    } on TimeoutException {
      print('📝 [REGISTRO] ⏱️ Timeout: Tiempo de conexión agotado');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('📝 [REGISTRO] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }
  
Future<Map<String, dynamic>> obtenerHistorialAdmin({int limite = 500}) async {
  try {
    final url = Uri.parse('http://192.168.0.142:8000/escaneos/?limite=$limite');
    print('👮 [ADMIN_HISTORIAL] URL: $url');
    print('👮 [ADMIN_HISTORIAL] Headers: ${_getHeaders()}');  // 👈
    print('👮 [ADMIN_HISTORIAL] Token actual: $_token');      // 👈
    final response = await http.get(
      url,
      headers: _getHeaders(),
    ).timeout(Duration(seconds: ApiConstants.timeoutSeconds));
    print('👮 [ADMIN_HISTORIAL] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'error': 'Error al obtener historial'};
    }
  } on TimeoutException {
    return {'success': false, 'error': 'Tiempo de conexión agotado'};
  } catch (e) {
    return {'success': false, 'error': 'Error: $e'};
  }
}


  // OBJETOS - ALUMNO
  Future<Map<String, dynamic>> obtenerMisObjetos() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosEndpoint}/mis-objetos');
      print('📦 [MIS_OBJETOS] URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('📦 [MIS_OBJETOS] Status Code: ${response.statusCode}');
      print('📦 [MIS_OBJETOS] Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final objetos = data.map((obj) => Objeto.fromJson(obj)).toList();
        print('📦 [MIS_OBJETOS] ✅ Objetos obtenidos: ${objetos.length}');
        return {'success': true, 'data': objetos};
      } else if (response.statusCode == 401) {
        print('📦 [MIS_OBJETOS] ❌ No autorizado');
        return {
          'success': false,
          'error': 'No autorizado'
        };
      } else {
        print('📦 [MIS_OBJETOS] ❌ Error desconocido');
        return {
          'success': false,
          'error': 'Error al obtener objetos'
        };
      }
    } on TimeoutException {
      print('📦 [MIS_OBJETOS] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('📦 [MIS_OBJETOS] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  // OBJETOS - CREAR
  Future<Map<String, dynamic>> registrarObjeto(
    String nombre,
    String? descripcion,
    int? categoriaId,
  ) async {
    try {
      final body = {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (categoriaId != null) 'categoria_id': categoriaId,
      };
      
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosEndpoint}/');
      print('➕ [REGISTRAR_OBJETO] URL: $url');
      print('➕ [REGISTRAR_OBJETO] Body: $body');

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('➕ [REGISTRAR_OBJETO] Status Code: ${response.statusCode}');
      print('➕ [REGISTRAR_OBJETO] Response: ${response.body}');

      if (response.statusCode == 200) {
        print('➕ [REGISTRAR_OBJETO] ✅ Objeto registrado exitosamente');
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al registrar objeto';
        print('➕ [REGISTRAR_OBJETO] ❌ Error: $errorMsg');
        return {
          'success': false,
          'error': errorMsg
        };
      }
    } on TimeoutException {
      print('➕ [REGISTRAR_OBJETO] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('➕ [REGISTRAR_OBJETO] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  // OBJETOS - OBTENER TODOS (ADMIN)
  Future<Map<String, dynamic>> obtenerObjetos() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosEndpoint}/');
      print('📦 [TODOS_OBJETOS] URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('📦 [TODOS_OBJETOS] Status Code: ${response.statusCode}');
      print('📦 [TODOS_OBJETOS] Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final objetos = data.map((obj) => Objeto.fromJson(obj)).toList();
        print('📦 [TODOS_OBJETOS] ✅ Total objetos: ${objetos.length}');
        return {'success': true, 'data': objetos};
      } else {
        print('📦 [TODOS_OBJETOS] ❌ Error desconocido');
        return {
          'success': false,
          'error': 'Error al obtener objetos'
        };
      }
    } on TimeoutException {
      print('📦 [TODOS_OBJETOS] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('📦 [TODOS_OBJETOS] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  Future<Map<String, dynamic>> obtenerObjeto(int objetoId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosPorIdEndpoint}/$objetoId');
      print('📦 [OBTENER_OBJETO] URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('📦 [OBTENER_OBJETO] Status Code: ${response.statusCode}');
      print('📦 [OBTENER_OBJETO] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 [OBTENER_OBJETO] ✅ Objeto obtenido');
        return {'success': true, 'data': Objeto.fromJson(data)};
      } else {
        print('📦 [OBTENER_OBJETO] ❌ Objeto no encontrado');
        return {
          'success': false,
          'error': 'Objeto no encontrado'
        };
      }
    } on TimeoutException {
      print('📦 [OBTENER_OBJETO] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('📦 [OBTENER_OBJETO] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  Future<Map<String, dynamic>> buscarPorQr(String qrCode) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosPorQrEndpoint}/$qrCode');
      print('🔍 [BUSCAR_QR] URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('🔍 [BUSCAR_QR] Status Code: ${response.statusCode}');
      print('🔍 [BUSCAR_QR] Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔍 [BUSCAR_QR] ✅ Objeto encontrado');
        return {'success': true, 'data': Objeto.fromJson(data)};
      } else if (response.statusCode == 404) {
        print('🔍 [BUSCAR_QR] ❌ QR no encontrado');
        return {
          'success': false,
          'error': 'Objeto QR no encontrado'
        };
      } else {
        print('🔍 [BUSCAR_QR] ❌ Error desconocido');
        return {
          'success': false,
          'error': 'Error al buscar objeto'
        };
      }
    } on TimeoutException {
      print('🔍 [BUSCAR_QR] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('🔍 [BUSCAR_QR] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  // ESCANEOS - MI HISTORIAL (ALUMNO)
  Future<Map<String, dynamic>> obtenerMiHistorial({int limite = 100}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.escaneoEndpoint}/mi-historial?limite=$limite');
      print('📊 [MI_HISTORIAL] URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('📊 [MI_HISTORIAL] Status Code: ${response.statusCode}');
      print('📊 [MI_HISTORIAL] Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final escaneos = data.map((e) => Escaneo.fromJson(e)).toList();
        print('📊 [MI_HISTORIAL] ✅ Escaneos obtenidos: ${escaneos.length}');
        return {'success': true, 'data': escaneos};
      } else if (response.statusCode == 401) {
        print('📊 [MI_HISTORIAL] ❌ No autorizado');
        return {
          'success': false,
          'error': 'No autorizado'
        };
      } else {
        print('📊 [MI_HISTORIAL] ❌ Error desconocido');
        return {
          'success': false,
          'error': 'Error al obtener historial'
        };
      }
    } on TimeoutException {
      print('📊 [MI_HISTORIAL] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('📊 [MI_HISTORIAL] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  // ESCANEOS - REGISTRAR (DESDE ESP32 - SIN TOKEN)
  Future<Map<String, dynamic>> registrarEscaneo(
    String qrCode,
    String? ubicacion,
    String dispositivo,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.escaneoEndpoint}/$qrCode');
      print('📝 [REGISTRAR_ESCANEO] URL: $url');
      print('📝 [REGISTRAR_ESCANEO] Ubicación: $ubicacion, Dispositivo: $dispositivo');
      
      final response = await http.post(
        url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({
          'ubicacion': ubicacion,
          'dispositivo': dispositivo,
        }),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('📝 [REGISTRAR_ESCANEO] Status Code: ${response.statusCode}');
      print('📝 [REGISTRAR_ESCANEO] Response: ${response.body}');

      if (response.statusCode == 200) {
        print('📝 [REGISTRAR_ESCANEO] ✅ Escaneo registrado exitosamente');
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al registrar escaneo';
        print('📝 [REGISTRAR_ESCANEO] ❌ Error: $errorMsg');
        return {
          'success': false,
          'error': errorMsg
        };
      }
    } on TimeoutException {
      print('📝 [REGISTRAR_ESCANEO] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('📝 [REGISTRAR_ESCANEO] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }

  Future<Map<String, dynamic>> obtenerHistorial(int objetoId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.historialEscaneoEndpoint}/$objetoId');
      print('📜 [HISTORIAL_ESCANEOS] URL: $url');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      ).timeout(
        Duration(seconds: ApiConstants.timeoutSeconds),
      );

      print('📜 [HISTORIAL_ESCANEOS] Status Code: ${response.statusCode}');
      print('📜 [HISTORIAL_ESCANEOS] Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final escaneos = data.map((e) => Escaneo.fromJson(e)).toList();
        print('📜 [HISTORIAL_ESCANEOS] ✅ Historial obtenido: ${escaneos.length} escaneos');
        return {'success': true, 'data': escaneos};
      } else {
        print('📜 [HISTORIAL_ESCANEOS] ❌ Error desconocido');
        return {
          'success': false,
          'error': 'Error al obtener historial'
        };
      }
    } on TimeoutException {
      print('📜 [HISTORIAL_ESCANEOS] ⏱️ Timeout');
      return {
        'success': false,
        'error': 'Tiempo de conexión agotado'
      };
    } catch (e) {
      print('📜 [HISTORIAL_ESCANEOS] ❌ Excepción: $e');
      return {
        'success': false,
        'error': 'Error: $e'
      };
    }
  }
}
