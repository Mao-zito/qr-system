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
  static const Color _naranjaClaro = Color(0xFF5B7FFF);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Objeto Encontrado', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${objeto.nombre}', style: const TextStyle(fontSize: 14)),
            if (objeto.descripcion != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Descripción: ${objeto.descripcion}', style: const TextStyle(fontSize: 14)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('QR: ${objeto.qrCode}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _registrarEscaneo(objeto, qrCode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _naranjaClaro,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Registrar Escaneo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Registrar Escaneo', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ubicacionController,
              decoration: InputDecoration(
                labelText: 'Ubicación',
                hintText: 'Ej: Almacén 1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _naranjaClaro, width: 2),
                ),
                prefixIcon: const Icon(Icons.location_on),
                prefixIconColor: _naranjaClaro,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dispositivoController,
              decoration: InputDecoration(
                labelText: 'Dispositivo',
                hintText: 'Ej: Móvil',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _naranjaClaro, width: 2),
                ),
                prefixIcon: const Icon(Icons.devices),
                prefixIconColor: _naranjaClaro,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
              backgroundColor: _naranjaClaro,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: _naranjaClaro,
        elevation: 0,
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
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Apunta la cámara al código QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
