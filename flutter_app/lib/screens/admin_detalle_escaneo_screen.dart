import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminDetalleEscaneoScreen extends StatelessWidget {
  final Map<String, dynamic> escaneo;
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco = Color(0xFFFAFAFA);

  const AdminDetalleEscaneoScreen({Key? key, required this.escaneo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fecha = _formatearFecha(escaneo['fecha_hora']?.toString() ?? '');
    final nombreCompleto = '${escaneo['alumno'] ?? ''} ${escaneo['apellido'] ?? ''}'.trim();
    final esEntrada = escaneo['tipo_evento'] == 'ENTRADA';

    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Detalle del Escaneo'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // QR
            Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  border: Border.all(color: _naranjaVivo, width: 2.5),
                  borderRadius: BorderRadius.circular(24),
                  color: _naranjaVivo.withOpacity(0.08),
                ),
                child: Column(
                  children: [
                    Text(
                      'CÓDIGO QR',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _naranjaVivo,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: 18),
                    QrImageView(
                      data: escaneo['qr_code'] ?? 'sin-qr',
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      escaneo['qr_code'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w400,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Info del objeto
            _buildInfoCard(context, 'Objeto', [
              _buildInfoRow(context, Icons.backpack_outlined, 'Nombre', escaneo['objeto'] ?? 'Sin nombre'),
              _buildInfoRow(
                context,
                esEntrada ? Icons.login_outlined : Icons.logout_outlined,
                'Tipo',
                escaneo['tipo_evento'] ?? 'ENTRADA',
              ),
              _buildInfoRow(context, Icons.location_on_outlined, 'Ubicación', escaneo['ubicacion'] ?? 'Sin ubicación'),
              _buildInfoRow(context, Icons.devices_outlined, 'Dispositivo', escaneo['dispositivo'] ?? 'Desconocido'),
              _buildInfoRow(context, Icons.access_time_outlined, 'Fecha y hora', fecha),
            ]),
            const SizedBox(height: 20),

            // Info del alumno
            _buildInfoCard(context, 'Alumno', [
              _buildInfoRow(context, Icons.person_outline, 'Nombre completo', nombreCompleto.isEmpty ? 'Desconocido' : nombreCompleto),
              _buildInfoRow(context, Icons.badge_outlined, 'Código estudiante', escaneo['codigo_estudiante'] ?? 'Sin código'),
              _buildInfoRow(context, Icons.phone_outlined, 'Teléfono', escaneo['telefono'] ?? 'Sin teléfono'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String titulo, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _naranjaVivo,
                    letterSpacing: 0.8,
                  ),
            ),
            Divider(
              color: _naranjaVivo.withOpacity(0.15),
              height: 18,
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _naranjaVivo.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _naranjaVivo, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return fecha; }
  }
}