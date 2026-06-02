import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminDetalleEscaneoScreen extends StatelessWidget {
  final Map<String, dynamic> escaneo;
  static const Color _naranjaClaro = Color(0xFF5B7FFF);

  const AdminDetalleEscaneoScreen({Key? key, required this.escaneo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fecha = _formatearFecha(escaneo['fecha_hora']?.toString() ?? '');
    final nombreCompleto = '${escaneo['alumno'] ?? ''} ${escaneo['apellido'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Detalle del Escaneo'),
        backgroundColor: _naranjaClaro,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // QR
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: _naranjaClaro, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: _naranjaClaro.withOpacity(0.05),
              ),
              child: Column(
                children: [
                  Text('CÓDIGO QR',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _naranjaClaro, fontSize: 12)),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: escaneo['qr_code'] ?? 'sin-qr',
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(escaneo['qr_code'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Info del objeto
            _buildInfoCard('Objeto', [
              _buildInfoRow(Icons.backpack, 'Nombre', escaneo['objeto'] ?? 'Sin nombre'),
              _buildInfoRow(
                escaneo['tipo_evento'] == 'ENTRADA' ? Icons.login : Icons.logout,
                'Tipo',
                escaneo['tipo_evento'] ?? 'ENTRADA',
              ),
              _buildInfoRow(Icons.location_on, 'Ubicación', escaneo['ubicacion'] ?? 'Sin ubicación'),
              _buildInfoRow(Icons.devices, 'Dispositivo', escaneo['dispositivo'] ?? 'Desconocido'),
              _buildInfoRow(Icons.access_time, 'Fecha y hora', fecha),
            ]),
            const SizedBox(height: 20),

            // Info del alumno
            _buildInfoCard('Alumno', [
              _buildInfoRow(Icons.person, 'Nombre completo', nombreCompleto.isEmpty ? 'Desconocido' : nombreCompleto),
              _buildInfoRow(Icons.badge, 'Código estudiante', escaneo['codigo_estudiante'] ?? 'Sin código'),
              _buildInfoRow(Icons.phone, 'Teléfono', escaneo['telefono'] ?? 'Sin teléfono'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String titulo, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: _naranjaClaro.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo.toUpperCase(),
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: _naranjaClaro)),
            Divider(color: _naranjaClaro.withOpacity(0.2), height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _naranjaClaro, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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