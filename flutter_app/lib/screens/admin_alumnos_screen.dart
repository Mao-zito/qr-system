import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'admin_detalle_alumno_screen.dart';

class AdminAlumnosScreen extends StatefulWidget {
  const AdminAlumnosScreen({Key? key}) : super(key: key);

  @override
  State<AdminAlumnosScreen> createState() => _AdminAlumnosScreenState();
}

class _AdminAlumnosScreenState extends State<AdminAlumnosScreen> {
  final _apiService = ApiService();
  List<dynamic> _alumnos = [];
  List<dynamic> _alumnosFiltrados = [];
  bool _isLoading = true;
  final _busquedaController = TextEditingController();
  
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _cargarAlumnos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarAlumnos() async {
    setState(() => _isLoading = true);
    final result = await _apiService.obtenerAlumnos();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _alumnos = result['data'];
          _alumnosFiltrados = _alumnos;
        }
        _isLoading = false;
      });
    }
  }

  void _filtrar() {
    final query = _busquedaController.text.toLowerCase();
    setState(() {
      _alumnosFiltrados = _alumnos.where((a) {
        final nombre = (a['nombre'] ?? '').toLowerCase();
        final apellido = (a['apellido'] ?? '').toLowerCase();
        final codigo = (a['codigo_estudiante'] ?? '').toLowerCase();
        return query.isEmpty ||
            nombre.contains(query) ||
            apellido.contains(query) ||
            codigo.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dentroCount = _alumnos.where((a) => a['ultimo_evento'] == 'ENTRADA').length;
    final fueraCount = _alumnos.where((a) => a['ultimo_evento'] == 'SALIDA' || a['ultimo_evento'] == null).length;

    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Alumnos'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
        actions: [
          IconButton(
            onPressed: _cargarAlumnos,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Container(
            color: _naranjaVivo,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Row(
              children: [
                _buildStatCard(
                  'Dentro',
                  '$dentroCount',
                  Icons.login_outlined,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Fuera',
                  '$fueraCount',
                  Icons.logout_outlined,
                  Colors.red,
                ),
              ],
            ),
          ),

          // Búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              onChanged: (_) => _filtrar(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o código...',
                prefixIcon: const Icon(Icons.search_outlined, color: Color(0xFFFF6B00)),
              ),
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
                    ),
                  )
                : _alumnosFiltrados.isEmpty
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
                                Icons.people_outline,
                                size: 60,
                                color: _naranjaVivo.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No hay alumnos',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarAlumnos,
                        color: _naranjaVivo,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          itemCount: _alumnosFiltrados.length,
                          itemBuilder: (context, index) {
                            final a = _alumnosFiltrados[index];
                            final nombreCompleto = '${a['nombre'] ?? ''} ${a['apellido'] ?? ''}'.trim();
                            final estaAdentro = a['ultimo_evento'] == 'ENTRADA';
                            final sinRegistro = a['ultimo_evento'] == null;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAlumnoCard(
                                a,
                                nombreCompleto,
                                estaAdentro,
                                sinRegistro,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String valor, IconData icon, Color accentColor) {
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
              child: Icon(icon, color: accentColor, size: 22),
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

  Widget _buildAlumnoCard(
    dynamic alumno,
    String nombreCompleto,
    bool estaAdentro,
    bool sinRegistro,
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
                builder: (context) => AdminDetalleAlumnoScreen(alumno: alumno),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: sinRegistro
                          ? [Colors.grey.shade300, Colors.grey.shade400]
                          : estaAdentro
                              ? [Colors.green.shade200, Colors.green.shade300]
                              : [Colors.red.shade200, Colors.red.shade300],
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: alumno['foto_perfil'] != null
                        ? MemoryImage(base64Decode(alumno['foto_perfil']))
                        : null,
                    child: alumno['foto_perfil'] == null
                        ? Icon(
                            sinRegistro
                                ? Icons.person_outline
                                : estaAdentro
                                    ? Icons.login_outlined
                                    : Icons.logout_outlined,
                            color: sinRegistro
                                ? Colors.grey.shade700
                                : estaAdentro
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                            size: 28,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreCompleto,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🎓 ${alumno['codigo_estudiante'] ?? 'Sin código'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sinRegistro
                              ? Colors.grey.withOpacity(0.15)
                              : estaAdentro
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sinRegistro
                              ? 'Sin registros'
                              : estaAdentro
                                  ? 'Dentro'
                                  : 'Fuera',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sinRegistro
                                ? Colors.grey.shade700
                                : estaAdentro
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                          ),
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
}