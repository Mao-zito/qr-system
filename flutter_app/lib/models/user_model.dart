class User {
  final int? id;
  final String nombre;
  final String correo;
  final String rol;
  final String token;

  User({
    this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'usuario',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'token': token,
    };
  }
}

class LoginRequest {
  final String correo;
  final String contrasena;

  LoginRequest({
    required this.correo,
    required this.contrasena,
  });

  Map<String, dynamic> toJson() {
    return {
      'correo': correo,
      'contraseña': contrasena,
    };
  }
}

class RegistroRequest {
  final String nombre;
  final String correo;
  final String contrasena;
  final String rol;

  RegistroRequest({
    required this.nombre,
    required this.correo,
    required this.contrasena,
    this.rol = 'usuario',
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'correo': correo,
      'contraseña': contrasena,
      'rol': rol,
    };
  }
}
