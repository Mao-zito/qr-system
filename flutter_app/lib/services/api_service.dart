import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/objeto_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) => _token = token;
  String? getToken() => _token;
  void logout() => _token = null;

  Map<String, String> _getHeaders({bool withAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ─── AUTH ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/login');
      final response = await http.post(
        url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
      ).timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return {'success': true, 'data': data};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al iniciar sesión';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> registro(
    String nombre,
    String correo,
    String contrasena,
    String rol, {
    String? apellido,
    String? telefono,
    String? codigoEstudiante,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}');
      final response = await http.post(
        url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({
          'nombre': nombre,
          'apellido': apellido ?? '',
          'correo': correo,
          'contrasena': contrasena,
          'telefono': telefono ?? '',
          'codigo_estudiante': codigoEstudiante ?? '',
          'rol': rol,
        }),
      ).timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al registrar';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }
Future<Map<String, dynamic>> solicitarReset(String correo) async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/solicitar-reset');
    final response = await http.post(url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({'correo': correo}))
        .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
    if (response.statusCode == 200) return {'success': true};
    return {'success': false, 'error': jsonDecode(response.body)['detail'] ?? 'Error'};
  } on TimeoutException {
    return {'success': false, 'error': 'Tiempo de conexión agotado'};
  } catch (e) {
    return {'success': false, 'error': 'Error: $e'};
  }
}

Future<Map<String, dynamic>> verificarCodigoReset(String correo, String codigo) async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/verificar-codigo');
    final response = await http.post(url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({'correo': correo, 'codigo': codigo}))
        .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
    if (response.statusCode == 200) return {'success': true};
    return {'success': false, 'error': jsonDecode(response.body)['detail'] ?? 'Error'};
  } on TimeoutException {
    return {'success': false, 'error': 'Tiempo de conexión agotado'};
  } catch (e) {
    return {'success': false, 'error': 'Error: $e'};
  }
}

Future<Map<String, dynamic>> restablecerContrasena(String correo, String codigo, String nueva) async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/auth/restablecer-contrasena');
    final response = await http.post(url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({'correo': correo, 'codigo': codigo, 'nueva_contrasena': nueva}))
        .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
    if (response.statusCode == 200) return {'success': true};
    return {'success': false, 'error': jsonDecode(response.body)['detail'] ?? 'Error'};
  } on TimeoutException {
    return {'success': false, 'error': 'Tiempo de conexión agotado'};
  } catch (e) {
    return {'success': false, 'error': 'Error: $e'};
  }
}

  // ─── OBJETOS ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerMisObjetos() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosEndpoint}/mis-objetos');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data.map((o) => Objeto.fromJson(o)).toList()};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'No autorizado'};
      } else {
        return {'success': false, 'error': 'Error al obtener objetos'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> obtenerObjetos() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosEndpoint}/');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data.map((o) => Objeto.fromJson(o)).toList()};
      } else {
        return {'success': false, 'error': 'Error al obtener objetos'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> obtenerCategorias() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/categorias/');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data.map((c) => {'id': c['id'], 'nombre': c['nombre']}).toList(),
        };
      } else {
        return {'success': false, 'error': 'Error al obtener categorías'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> registrarObjeto(
    String nombre,
    String? descripcion,
    int? categoriaId,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosEndpoint}/');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'nombre': nombre,
          if (descripcion != null) 'descripcion': descripcion,
          if (categoriaId != null) 'categoria_id': categoriaId,
        }),
      ).timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al registrar objeto';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> obtenerObjeto(int objetoId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosPorIdEndpoint}/$objetoId');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true, 'data': Objeto.fromJson(jsonDecode(response.body))};
      } else {
        return {'success': false, 'error': 'Objeto no encontrado'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> buscarPorQr(String qrCode) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.objetosPorQrEndpoint}/$qrCode');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true, 'data': Objeto.fromJson(jsonDecode(response.body))};
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Objeto QR no encontrado'};
      } else {
        return {'success': false, 'error': 'Error al buscar objeto'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // ─── ESCANEOS ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerMiHistorial({int limite = 100}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.escaneoEndpoint}/mi-historial?limite=$limite');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data.map((e) => Escaneo.fromJson(e)).toList()};
      } else if (response.statusCode == 401) {
        return {'success': false, 'error': 'No autorizado'};
      } else {
        return {'success': false, 'error': 'Error al obtener historial'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> registrarEscaneo(
    String qrCode,
    String? ubicacion,
    String dispositivo,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.escaneoEndpoint}/$qrCode');
      final response = await http.post(
        url,
        headers: _getHeaders(withAuth: false),
        body: jsonEncode({'ubicacion': ubicacion, 'dispositivo': dispositivo}),
      ).timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al registrar escaneo';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> obtenerHistorial(int objetoId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.historialEscaneoEndpoint}/$objetoId');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data.map((e) => Escaneo.fromJson(e)).toList()};
      } else {
        return {'success': false, 'error': 'Error al obtener historial'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // ─── ADMIN ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerHistorialAdmin({int limite = 500}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/escaneos/?limite=$limite');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al obtener historial';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }
Future<Map<String, dynamic>> obtenerMlResumen() async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/ml/resumen');
    final response = await http.get(url, headers: _getHeaders())
        .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Error al obtener resumen ML'};
    }
  } on TimeoutException {
    return {'success': false, 'error': 'Tiempo de conexión agotado'};
  } catch (e) {
    return {'success': false, 'error': 'Error: $e'};
  }
}

Future<Map<String, dynamic>> obtenerMlPerfiles() async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/ml/perfiles');
    final response = await http.get(url, headers: _getHeaders())
        .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Error al obtener perfiles ML'};
    }
  } on TimeoutException {
    return {'success': false, 'error': 'Tiempo de conexión agotado'};
  } catch (e) {
    return {'success': false, 'error': 'Error: $e'};
  }
}

Future<Map<String, dynamic>> obtenerMlAnomalias() async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/ml/anomalias');
    final response = await http.get(url, headers: _getHeaders())
        .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {'success': false, 'error': 'Error al obtener anomalías ML'};
    }
  } on TimeoutException {
    return {'success': false, 'error': 'Tiempo de conexión agotado'};
  } catch (e) {
    return {'success': false, 'error': 'Error: $e'};
  }
}

  // ─── PERFIL ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerPerfil() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/perfil');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Error al obtener perfil'};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> actualizarPerfil({
    String? nombre,
    String? apellido,
    String? telefono,
    String? fotoPerfil,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/perfil');
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          if (nombre != null) 'nombre': nombre,
          if (apellido != null) 'apellido': apellido,
          if (telefono != null) 'telefono': telefono,
          if (fotoPerfil != null) 'foto_perfil': fotoPerfil,
        }),
      ).timeout(Duration(seconds: ApiConstants.timeoutSeconds));
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al actualizar';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> cambiarContrasena(
    String contrasenaActual,
    String contrasenaNueva,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/cambiar-contrasena');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'contrasena_actual': contrasenaActual,
          'contrasena_nueva': contrasenaNueva,
        }),
      ).timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al cambiar contraseña';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // ─── ALUMNOS ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> obtenerAlumnos() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/alumnos');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al obtener alumnos';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> obtenerHistorialAlumno(int usuarioId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/alumnos/$usuarioId/historial');
      final response = await http.get(url, headers: _getHeaders())
          .timeout(Duration(seconds: ApiConstants.timeoutSeconds));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Error al obtener historial';
        return {'success': false, 'error': errorMsg};
      }
    } on TimeoutException {
      return {'success': false, 'error': 'Tiempo de conexión agotado'};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }
}