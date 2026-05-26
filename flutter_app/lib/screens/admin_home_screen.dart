import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'admin_detalle_escaneo_screen.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final String usuario;
  final String token;

  const AdminHomeScreen({
    Key? key,
    required this.usuario,
    required this.token,
  }) : super(key: key);

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
            SnackBar(
              content: Text(result['error'] ?? 'Error al cargar escaneos'),
              backgroundColor: Colors.red,
            ),
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
        final ubicacion = (e['ubicacion'] ?? '').toLowerCase();
        final fecha = e['fecha_hora']?.toString() ?? '';

        final coincideTexto = query.isEmpty ||
            objeto.contains(query) ||
            alumno.contains(query) ||
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
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                widget.usuario,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Cerrar Sesión'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.deepPurple,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildStatCard('Total', '${_escaneos.length}', Icons.qr_code_scanner),
                  const SizedBox(width: 12),
                  _buildStatCard('Hoy', '${_escaneosHoy()}', Icons.today),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _busquedaController,
                    onChanged: (_) => _filtrar(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por alumno, objeto, ubicación...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (_fechaFiltro != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _limpiarFiltros,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar'),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        onPressed: _cargarEscaneos,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualizar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _escaneosFiltrados.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No hay escaneos',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarEscaneos,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _escaneosFiltrados.length,
                            itemBuilder: (context, index) {
                              final e = _escaneosFiltrados[index];
                              final fecha = _formatearFecha(e['fecha_hora']?.toString() ?? '');
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple.shade100,
                                    child: const Icon(Icons.qr_code,
                                        color: Colors.deepPurple, size: 20),
                                  ),
                                  title: Text(
                                    e['objeto'] ?? 'Sin nombre',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('👤 ${e['alumno'] ?? 'Desconocido'}',
                                          style: const TextStyle(fontSize: 12)),
                                      Text('📍 ${e['ubicacion'] ?? 'Sin ubicación'}',
                                          style: const TextStyle(fontSize: 12)),
                                      Text('🕐 $fecha',
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: Colors.grey),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(valor,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
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
        return fecha.year == hoy.year &&
            fecha.month == hoy.month &&
            fecha.day == hoy.day;
      } catch (_) {
        return false;
      }
    }).length;
  }

  String _formatearFecha(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return fecha;
    }
  }
}