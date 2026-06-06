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

  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco = Color(0xFFFAFAFA);

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
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red.shade500,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Mi Código QR'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
        // ✅ título e ícono de back en blanco
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // ✅ sin SafeArea — el padding lo manejamos manualmente
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Info del objeto ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OBJETO',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _naranjaVivo,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.objeto.nombre,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F1F1F),
                        ),
                  ),
                  if (widget.objeto.descripcion != null &&
                      widget.objeto.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      'DESCRIPCIÓN',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _naranjaVivo,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.objeto.descripcion!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── QR con Screenshot wrapper ────────────────────────────────
            Screenshot(
              controller: _screenshotController,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.objeto.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: _naranjaVivo,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _naranjaVivo, width: 2.5),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: QrImageView(
                        data: widget.objeto.qrCode,
                        version: QrVersions.auto,
                        size: 220.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _naranjaVivo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.objeto.qrCode,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: _naranjaVivo,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Cómo usar ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _naranjaVivo.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _naranjaVivo.withOpacity(0.2), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CÓMO USAR',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _naranjaVivo,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _buildStep('1', 'Muestra este código QR al ingresar a la universidad'),
                  const SizedBox(height: 12),
                  _buildStep('2', 'El personal de seguridad lo escaneará'),
                  const SizedBox(height: 12),
                  _buildStep('3', 'Se registrará el ingreso en el sistema'),
                  const SizedBox(height: 12),
                  _buildStep('4', 'Puedes ver tu historial de ingresos en cualquier momento'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Botón compartir ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _compartiendo ? null : _compartirQr,
                icon: _compartiendo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.share_outlined),
                label: Text(
                  _compartiendo ? 'Compartiendo...' : 'Compartir QR',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String numero, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: _naranjaVivo,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              numero,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}