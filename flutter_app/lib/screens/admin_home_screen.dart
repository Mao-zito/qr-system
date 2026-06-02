import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'admin_detalle_escaneo_screen.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String usuario;
  final String token;

  const AdminHomeScreen({Key? key, required this.usuario, required this.token}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _apiService = ApiService();
  List<dynamic> _escaneos = [];
  List<dynamic> _escaneosFiltrados = [];
  bool _isLoading = true;
  final _busquedaController = TextEditingController();
  DateTime? _fechaFiltro;
  static const Color _naranjaClaro = Color(0xFF5B7FFF);

  @override
  void initState() {
    super.initState();
    _apiService.setToken(widget.token);
    _cargarEscaneos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarEscaneos() async {
    setState(() => _isLoading = true);
    final result = await _apiService.obtenerHistorialAdmin();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _escaneos = result['data'];
          _escaneosFiltrados = _escaneos;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Error al cargar escaneos'), backgroundColor: Colors.red),
          );
        }
        _isLoading = false;
      });
    }
  }

  void _filtrar() {
    final query = _busquedaController.text.toLowerCase();
    setState(() {
      _escaneosFiltrados = _escaneos.where((e) {
        final objeto = (e['objeto'] ?? '').toLowerCase();
        final alumno = (e['alumno'] ?? '').toLowerCase();
        final apellido = (e['apellido'] ?? '').toLowerCase();
        final codigo = (e['codigo_estudiante'] ?? '').toLowerCase();
        final ubicacion = (e['ubicacion'] ?? '').toLowerCase();
        final fecha = e['fecha_hora']?.toString() ?? '';

        final coincideTexto = query.isEmpty ||
            objeto.contains(query) ||
            alumno.contains(query) ||
            apellido.contains(query) ||
            codigo.contains(query) ||
            ubicacion.contains(query);

        final coincideFecha = _fechaFiltro == null ||
            fecha.startsWith(
              '${_fechaFiltro!.year}-'
              '${_fechaFiltro!.month.toString().padLeft(2, '0')}-'
              '${_fechaFiltro!.day.toString().padLeft(2, '0')}',
            );

        return coincideTexto && coincideFecha;
      }).toList();
    });
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaFiltro = fecha);
      _filtrar();
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaFiltro = null;
      _busquedaController.clear();
      _escaneosFiltrados = _escaneos;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('nombre');
    await prefs.remove('rol');
    _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: _naranjaClaro,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PerfilScreen()),
                  );
                },
                child: Text(
                  widget.usuario,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _naranjaClaro,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  _buildStatCard('Total', '${_escaneos.length}', Icons.qr_code_scanner),
                  const SizedBox(width: 12),
                  _buildStatCard('Hoy', '${_escaneosHoy()}', Icons.today),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _busquedaController,
                    onChanged: (_) => _filtrar(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por alumno, código, objeto...',
                      prefixIcon: const Icon(Icons.search),
                      prefixIconColor: _naranjaClaro,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _seleccionarFecha,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaFiltro == null
                              ? 'Filtrar por fecha'
                              : '${_fechaFiltro!.day}/${_fechaFiltro!.month}/${_fechaFiltro!.year}',
                        ),
                      ),
                      if (_fechaFiltro != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _limpiarFiltros,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar'),
                          style: TextButton.styleFrom(
                            foregroundColor: _naranjaClaro,
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        onPressed: _cargarEscaneos,
                        icon: const Icon(Icons.refresh),
                        color: _naranjaClaro,
                        tooltip: 'Actualizar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_naranjaClaro),
                      ),
                    )
                  : _escaneosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text('No hay escaneos', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarEscaneos,
                          color: _naranjaClaro,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _escaneosFiltrados.length,
                            itemBuilder: (context, index) {
                              final e = _escaneosFiltrados[index];
                              final fecha = _formatearFecha(e['fecha_hora']?.toString() ?? '');
                              final nombreCompleto = '${e['alumno'] ?? ''} ${e['apellido'] ?? ''}'.trim();
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE8E8E8),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _naranjaClaro.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.qr_code_2,
                                        color: _naranjaClaro,
                                        size: 22,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e['objeto'] ?? 'Sin nombre',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF1F1F1F),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: e['tipo_evento'] == 'ENTRADA'
                                                ? const Color(0xFF00D084).withOpacity(0.15)
                                                : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            e['tipo_evento'] ?? 'ENTRADA',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: e['tipo_evento'] == 'ENTRADA'
                                                  ? const Color(0xFF00D084)
                                                  : Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '$nombreCompleto • ${e['ubicacion'] ?? 'Sin ubicación'} • $fecha',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF888888),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: _naranjaClaro.withOpacity(0.5),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminDetalleEscaneoScreen(escaneo: e),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String valor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _escaneosHoy() {
    final hoy = DateTime.now();
    return _escaneos.where((e) {
      try {
        final fechaStr = e['fecha_hora']?.toString() ?? '';
        if (fechaStr.isEmpty) return false;
        final fecha = DateTime.parse(fechaStr);
        return fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day;
      } catch (_) { return false; }
    }).length;
  }

  String _formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return fecha; }
  }
}