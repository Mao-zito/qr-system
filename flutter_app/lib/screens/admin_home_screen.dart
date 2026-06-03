import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'admin_alumnos_screen.dart';
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
  int _selectedIndex = 0;
  
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco = Color(0xFFFAFAFA);

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

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminAlumnosScreen()),
      ).then((_) {
        setState(() => _selectedIndex = 0);
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PerfilScreen()),
      ).then((_) {
        setState(() => _selectedIndex = 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Panel Admin'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PerfilScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.usuario,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: _naranjaVivo),
                    const SizedBox(width: 12),
                    const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cards de estadísticas
            Container(
              color: _naranjaVivo,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  _buildStatCard('Total', '${_escaneos.length}', Icons.qr_code_scanner),
                  const SizedBox(width: 12),
                  _buildStatCard('Hoy', '${_escaneosHoy()}', Icons.today),
                ],
              ),
            ),
            // Filtros
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  TextField(
                    controller: _busquedaController,
                    onChanged: (_) => _filtrar(),
                    decoration: InputDecoration(
                      hintText: 'Buscar alumno, código, objeto...',
                      prefixIcon: const Icon(Icons.search_outlined),
                      prefixIconColor: _naranjaVivo,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _seleccionarFecha,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _fechaFiltro == null
                              ? 'Filtrar por fecha'
                              : '${_fechaFiltro!.day}/${_fechaFiltro!.month}/${_fechaFiltro!.year}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_fechaFiltro != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _limpiarFiltros,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar'),
                          style: TextButton.styleFrom(foregroundColor: _naranjaVivo),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        onPressed: _cargarEscaneos,
                        icon: const Icon(Icons.refresh_outlined, size: 22),
                        color: _naranjaVivo,
                        tooltip: 'Actualizar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Lista de escaneos
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
                      ),
                    )
                  : _escaneosFiltrados.isEmpty
                      ? Center(
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
                                  Icons.inbox_outlined,
                                  size: 60,
                                  color: _naranjaVivo.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No hay escaneos',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarEscaneos,
                          color: _naranjaVivo,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            itemCount: _escaneosFiltrados.length,
                            itemBuilder: (context, index) {
                              final e = _escaneosFiltrados[index];
                              final fecha = _formatearFecha(e['fecha_hora']?.toString() ?? '');
                              final nombreCompleto = '${e['alumno'] ?? ''} ${e['apellido'] ?? ''}'.trim();
                              final isEntrada = e['tipo_evento'] == 'ENTRADA';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildEscaneoCard(
                                  e,
                                  nombreCompleto,
                                  fecha,
                                  isEntrada,
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assessment_outlined, size: 26),
              activeIcon: Icon(Icons.assessment, size: 26),
              label: 'Escaneos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined, size: 26),
              activeIcon: Icon(Icons.group, size: 26),
              label: 'Alumnos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined, size: 26),
              activeIcon: Icon(Icons.person, size: 26),
              label: 'Perfil',
            ),
          ],
          selectedItemColor: _naranjaVivo,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: _naranjaVivo,
              ),
          unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
        ),
      ),
    );
  }

  Widget _buildEscaneoCard(
    dynamic escaneo,
    String nombreCompleto,
    String fecha,
    bool isEntrada,
  ) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDetalleEscaneoScreen(escaneo: escaneo),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _naranjaVivo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_2,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              escaneo['objeto'] ?? 'Sin nombre',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1F1F1F),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isEntrada
                                  ? const Color(0xFF00D084).withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isEntrada ? 'ENTRADA' : 'SALIDA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isEntrada ? const Color(0xFF00D084) : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$nombreCompleto • ${escaneo['ubicacion'] ?? 'Sin ubicación'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fecha,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _naranjaVivo.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String valor, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  valor,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
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