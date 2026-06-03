import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/objeto_model.dart';
import '../services/api_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({Key? key}) : super(key: key);

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  late Future<List<Escaneo>> _futureHistorial;
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _futureHistorial = _cargarHistorial();
  }

  Future<List<Escaneo>> _cargarHistorial() async {
    final resultado = await ApiService().obtenerMiHistorial(limite: 100);
    if (resultado['success']) {
      return resultado['data'] as List<Escaneo>;
    } else {
      throw Exception(resultado['error'] ?? 'Error al cargar historial');
    }
  }

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Mi Historial de Ingresos'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Escaneo>>(
          future: _futureHistorial,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Error al cargar historial',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _futureHistorial = _cargarHistorial();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final escaneos = snapshot.data ?? [];

            if (escaneos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _naranjaVivo.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        size: 60,
                        color: _naranjaVivo.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No hay registros de ingreso',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tus ingresos aparecerán aquí',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _futureHistorial = _cargarHistorial();
                });
                await _futureHistorial;
              },
              color: _naranjaVivo,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: escaneos.length,
                itemBuilder: (context, index) {
                  final escaneo = escaneos[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildEscaneoCard(escaneo),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEscaneoCard(Escaneo escaneo) {
    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con objeto y fecha
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _naranjaVivo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        _naranjaVivo.withOpacity(0.15),
                        _naranjaNaranja.withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.backpack_outlined,
                      color: _naranjaVivo,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        escaneo.objeto ?? 'Objeto',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatearFecha(escaneo.fechaHora ?? DateTime.now()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 14),
            // Ubicación y Dispositivo
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UBICACIÓN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        escaneo.ubicacion ?? 'Entrada principal',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISPOSITIVO',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        escaneo.dispositivo ?? 'ESP32',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF333333),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}