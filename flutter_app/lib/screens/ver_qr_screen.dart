import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/objeto_model.dart';

class VerQrScreen extends StatefulWidget {
  final Objeto objeto;

  const VerQrScreen({Key? key, required this.objeto}) : super(key: key);

  @override
  State<VerQrScreen> createState() => _VerQrScreenState();
}

class _VerQrScreenState extends State<VerQrScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _compartiendo = false;

  Future<void> _compartirQr() async {
    setState(() => _compartiendo = true);
    try {
      final Uint8List? imagen = await _screenshotController.capture();
      if (imagen == null) return;

      final directorio = await getTemporaryDirectory();
      final archivo = File('${directorio.path}/qr_${widget.objeto.qrCode}.png');
      await archivo.writeAsBytes(imagen);

      await Share.shareXFiles(
        [XFile(archivo.path)],
        text: 'Mi QR para ${widget.objeto.nombre} - ${widget.objeto.qrCode}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Código QR'),
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OBJETO',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666))),
                      const SizedBox(height: 8),
                      Text(widget.objeto.nombre,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333))),
                      if (widget.objeto.descripcion != null &&
                          widget.objeto.descripcion!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('DESCRIPCIÓN',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF666666))),
                        const SizedBox(height: 4),
                        Text(widget.objeto.descripcion!,
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF555555))),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // QR con Screenshot wrapper
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Text(widget.objeto.nombre,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      QrImageView(
                        data: widget.objeto.qrCode,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(widget.objeto.qrCode,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFF666666))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CÓMO USAR',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B))),
                    SizedBox(height: 12),
                    Text(
                      '1. Muestra este código QR al ingresar a la universidad\n\n'
                      '2. El personal de seguridad lo escaneará\n\n'
                      '3. Se registrará el ingreso en el sistema\n\n'
                      '4. Puedes ver tu historial de ingresos en cualquier momento',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _compartiendo ? null : _compartirQr,
                  icon: _compartiendo
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.share),
                  label: Text(_compartiendo ? 'Compartiendo...' : 'Compartir QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}