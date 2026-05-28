import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminDetalleEscaneoScreen extends StatelessWidget {
  final Map<String, dynamic> escaneo;

  const AdminDetalleEscaneoScreen({Key? key, required this.escaneo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fecha = _formatearFecha(escaneo['fecha_hora']?.toString() ?? '');
    final nombreCompleto = '${escaneo['alumno'] ?? ''} ${escaneo['apellido'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Escaneo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('CÓDIGO QR',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 12),
                  QrImageView(
                    data: escaneo['qr_code'] ?? 'sin-qr',
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(escaneo['qr_code'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info del objeto
            _buildInfoCard('Objeto', [
              _buildInfoRow(Icons.backpack, 'Nombre', escaneo['objeto'] ?? 'Sin nombre'),
              _buildInfoRow(Icons.location_on, 'Ubicación', escaneo['ubicacion'] ?? 'Sin ubicación'),
              _buildInfoRow(Icons.devices, 'Dispositivo', escaneo['dispositivo'] ?? 'Desconocido'),
              _buildInfoRow(Icons.access_time, 'Fecha y hora', fecha),
            ]),
            const SizedBox(height: 16),

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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 12),
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