import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/objeto_model.dart';
import '../services/api_service.dart';

class QrScanScreen extends StatefulWidget {
  final String token;

  const QrScanScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _apiService = ApiService();
  MobileScannerController? _controller;
  bool _isProcessing = false;
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _apiService.setToken(widget.token);
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _procesarQr(String qrCode) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Buscar el objeto por QR
    final result = await _apiService.buscarPorQr(qrCode);

    if (mounted) {
      if (result['success']) {
        final objeto = result['data'] as Objeto;
        _mostrarConfirmacionEscaneo(objeto, qrCode);
      } else {
        _mostrarError(result['error']);
        setState(() => _isProcessing = false);
      }
    }
  }

  void _mostrarConfirmacionEscaneo(Objeto objeto, String qrCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Objeto Encontrado',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _naranjaVivo,
              ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogInfoRow('📦 Nombre', objeto.nombre),
              if (objeto.descripcion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildDialogInfoRow('📝 Descripción', objeto.descripcion!),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildDialogInfoRow('QR', objeto.qrCode),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _registrarEscaneo(objeto, qrCode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _naranjaVivo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Text(
              'Registrar Escaneo',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _naranjaVivo,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
        ),
      ],
    );
  }

  Future<void> _registrarEscaneo(Objeto objeto, String qrCode) async {
    _mostrarDialogoEscaneo(objeto.id, qrCode);
  }

  void _mostrarDialogoEscaneo(int objetoId, String qrCode) {
    final _ubicacionController = TextEditingController();
    final _dispositivoController = TextEditingController(text: 'Móvil');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Registrar Escaneo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: _naranjaVivo,
              ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  hintText: 'Ej: Almacén 1',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: _naranjaVivo),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dispositivoController,
                decoration: InputDecoration(
                  labelText: 'Dispositivo',
                  hintText: 'Ej: Móvil',
                  prefixIcon: const Icon(Icons.devices_outlined, color: _naranjaVivo),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final resultEscaneo = await _apiService.registrarEscaneo(
                qrCode,
                _ubicacionController.text,
                _dispositivoController.text,
              );

              if (mounted) {
                if (resultEscaneo['success']) {
                  _mostrarExito('Escaneo registrado correctamente');
                } else {
                  _mostrarError(resultEscaneo['error']);
                }
                setState(() => _isProcessing = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _naranjaVivo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Text(
              'Guardar',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green.shade500,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red.shade500,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (!_isProcessing) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _procesarQr(barcode.rawValue!);
                    break;
                  }
                }
              }
            },
          ),
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _naranjaVivo, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, color: _naranjaVivo, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Apunta la cámara al código QR',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
