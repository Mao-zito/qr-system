import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminDetalleAlumnoScreen extends StatefulWidget {
  final Map<String, dynamic> alumno;

  const AdminDetalleAlumnoScreen({Key? key, required this.alumno}) : super(key: key);

  @override
  State<AdminDetalleAlumnoScreen> createState() => _AdminDetalleAlumnoScreenState();
}

class _AdminDetalleAlumnoScreenState extends State<AdminDetalleAlumnoScreen> {
  final _apiService = ApiService();
  List<dynamic> _historial = [];
  bool _isLoading = true;
  
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _isLoading = true);
    final result = await _apiService.obtenerHistorialAlumno(widget.alumno['id']);
    if (mounted) {
      setState(() {
        if (result['success']) {
          _historial = result['data'];
        }
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = '${widget.alumno['nombre'] ?? ''} ${widget.alumno['apellido'] ?? ''}'.trim();
    final estaAdentro = widget.alumno['ultimo_evento'] == 'ENTRADA';
    final sinRegistro = widget.alumno['ultimo_evento'] == null;

    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: Text(nombreCompleto),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info del alumno
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFE8E8E8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_naranjaVivo.withOpacity(0.3), _naranjaNaranja.withOpacity(0.3)],
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        backgroundImage: widget.alumno['foto_perfil'] != null
                            ? MemoryImage(base64Decode(widget.alumno['foto_perfil']))
                            : null,
                        child: widget.alumno['foto_perfil'] == null
                            ? Text(
                                (widget.alumno['nombre'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: _naranjaVivo,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreCompleto,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1F1F1F),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '🎓 ${widget.alumno['codigo_estudiante'] ?? 'Sin código'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            '📱 ${widget.alumno['telefono'] ?? 'Sin teléfono'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: sinRegistro
                                  ? Colors.grey.withOpacity(0.15)
                                  : estaAdentro
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              sinRegistro
                                  ? 'Sin registros'
                                  : estaAdentro
                                      ? 'Dentro'
                                      : 'Fuera',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sinRegistro
                                    ? Colors.grey.shade700
                                    : estaAdentro
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Título Historial
            Text(
              'HISTORIAL DE ACCESOS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _naranjaVivo,
                    letterSpacing: 0.8,
                  ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
                    ),
                  )
                : _historial.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _naranjaVivo.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history_outlined,
                                  size: 48,
                                  color: _naranjaVivo.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sin historial',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _historial.length,
                        itemBuilder: (context, index) {
                          final h = _historial[index];
                          final esEntrada = h['tipo_evento'] == 'ENTRADA';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildHistorialCard(h, esEntrada),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialCard(dynamic historial, bool esEntrada) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: esEntrada ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                esEntrada ? Icons.login_outlined : Icons.logout_outlined,
                color: esEntrada ? Colors.green.shade700 : Colors.red.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    historial['objeto'] ?? 'Sin objeto',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F1F1F),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${historial['ubicacion'] ?? 'Sin ubicación'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '🕐 ${_formatearFecha(historial['fecha_hora'] ?? '')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: esEntrada ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                historial['tipo_evento'] ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: esEntrada ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}