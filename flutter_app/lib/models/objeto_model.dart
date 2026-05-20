class Objeto {
  final int id;
  final String nombre;
  final String? descripcion;
  final int? categoriaId;
  final String qrCode;
  final DateTime? fechaCreacion;
  final String? estado;

  Objeto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    required this.qrCode,
    this.fechaCreacion,
    this.estado,
  });

  factory Objeto.fromJson(Map<String, dynamic> json) {
    return Objeto(
      id: int.tryParse(json['id'].toString()) ?? 0,
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'],
      categoriaId: json['categoria_id'] != null
          ? int.tryParse(json['categoria_id'].toString())
          : null,
      qrCode: json['qr_code'] ?? '',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'].toString())
          : null,
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria_id': categoriaId,
      'qr_code': qrCode,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'estado': estado,
    };
  }
}

class Escaneo {
  final int id;
  final int? objetoId;
  final String? objeto;
  final String? qrCode;
  final String? ubicacion;
  final String? dispositivo;
  final DateTime? fechaHora;

  Escaneo({
    required this.id,
    this.objetoId,
    this.objeto,
    this.qrCode,
    this.ubicacion,
    this.dispositivo,
    this.fechaHora,
  });

  factory Escaneo.fromJson(Map<String, dynamic> json) {
    return Escaneo(
      id: int.tryParse(json['id'].toString()) ?? 0,
      objetoId: json['objeto_id'] != null
          ? int.tryParse(json['objeto_id'].toString())
          : null,
      objeto: json['objeto'],
      qrCode: json['qr_code'],
      ubicacion: json['ubicacion'],
      dispositivo: json['dispositivo'],
      fechaHora: json['fecha_hora'] != null
          ? DateTime.tryParse(json['fecha_hora'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'objeto_id': objetoId,
      'objeto': objeto,
      'qr_code': qrCode,
      'ubicacion': ubicacion,
      'dispositivo': dispositivo,
      'fecha_hora': fechaHora?.toIso8601String(),
    };
  }
}