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
  bool _isLoading = true;
  final _busquedaController = TextEditingController();

  String? _filtroEstado;

  static const Color _naranjaVivo    = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco         = Color(0xFFFAFAFA);

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
        if (result['success']) _alumnos = result['data'];
        _isLoading = false;
      });
    }
  }

  // ✅ lista filtrada por texto + estado
  List<dynamic> get _alumnosFiltrados {
    final query = _busquedaController.text.toLowerCase();
    return _alumnos.where((a) {
      final nombre   = (a['nombre']            ?? '').toLowerCase();
      final apellido = (a['apellido']           ?? '').toLowerCase();
      final codigo   = (a['codigo_estudiante']  ?? '').toLowerCase();

      final coincideTexto = query.isEmpty ||
          nombre.contains(query) ||
          apellido.contains(query) ||
          codigo.contains(query);

      final coincideEstado = _filtroEstado == null ||
          (_filtroEstado == 'ENTRADA' && a['ultimo_evento'] == 'ENTRADA') ||
          (_filtroEstado == 'FUERA'   && (a['ultimo_evento'] == 'SALIDA' || a['ultimo_evento'] == null));

      return coincideTexto && coincideEstado;
    }).toList();
  }

  int get _dentroCount => _alumnos.where((a) => a['ultimo_evento'] == 'ENTRADA').length;
  int get _fueraCount  => _alumnos.where((a) => a['ultimo_evento'] != 'ENTRADA').length;

  @override
  Widget build(BuildContext context) {
    final lista = _alumnosFiltrados;

    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Alumnos'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
        actions: [
          IconButton(
            onPressed: _cargarAlumnos,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Stats clickeables
          Container(
            color: _naranjaVivo,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Row(
              children: [
                _buildStatCard('Dentro', '$_dentroCount', Icons.login_outlined,  Colors.green, 'ENTRADA'),
                const SizedBox(width: 12),
                _buildStatCard('Fuera',  '$_fueraCount',  Icons.logout_outlined, Colors.red,   'FUERA'),
              ],
            ),
          ),

          // Búsqueda + filtro activo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _busquedaController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o código...',
                    prefixIcon: Icon(Icons.search_outlined, color: _naranjaVivo),
                    prefixIconColor: _naranjaVivo,
                  ),
                ),
                // ✅ chips de filtro
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFiltroChip('Todos',  null),
                    const SizedBox(width: 8),
                    _buildFiltroChip('Dentro', 'ENTRADA'),
                    const SizedBox(width: 8),
                    _buildFiltroChip('Fuera',  'FUERA'),
                    const Spacer(),
                    Text(
                      '${lista.length} alumno${lista.length != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo)))
                : lista.isEmpty
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
                              child: Icon(Icons.people_outline, size: 60, color: _naranjaVivo.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 14),
                            Text('No hay alumnos',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarAlumnos,
                        color: _naranjaVivo,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                          itemCount: lista.length,
                          itemBuilder: (context, index) {
                            final a = lista[index];
                            final nombreCompleto = '${a['nombre'] ?? ''} ${a['apellido'] ?? ''}'.trim();
                            final estaAdentro = a['ultimo_evento'] == 'ENTRADA';
                            final sinRegistro = a['ultimo_evento'] == null;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAlumnoCard(a, nombreCompleto, estaAdentro, sinRegistro),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ✅ stat card clickeable
  Widget _buildStatCard(String label, String valor, IconData icon, Color accentColor, String filtroValor) {
    final activo = _filtroEstado == filtroValor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() =>
            _filtroEstado = _filtroEstado == filtroValor ? null : filtroValor),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: activo ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activo ? accentColor : Colors.white.withOpacity(0.25),
              width: activo ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: activo ? accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: activo ? accentColor : Colors.white, size: 22),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: activo ? Colors.grey.shade600 : Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      )),
                  Text(valor,
                      style: TextStyle(
                        color: activo ? accentColor : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String label, String? valor) {
    final activo = _filtroEstado == valor;
    final color  = valor == null ? _naranjaVivo
        : valor == 'ENTRADA' ? Colors.green
        : Colors.red;

    return GestureDetector(
      onTap: () => setState(() => _filtroEstado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: activo ? Colors.white : color,
            )),
      ),
    );
  }

  Widget _buildAlumnoCard(dynamic alumno, String nombreCompleto, bool estaAdentro, bool sinRegistro) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, spreadRadius: 2)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => AdminDetalleAlumnoScreen(alumno: alumno))),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
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
                        ? MemoryImage(base64Decode(alumno['foto_perfil'])) : null,
                    child: alumno['foto_perfil'] == null
                        ? Icon(
                            sinRegistro ? Icons.person_outline
                                : estaAdentro ? Icons.login_outlined : Icons.logout_outlined,
                            color: sinRegistro ? Colors.grey.shade700
                                : estaAdentro ? Colors.green.shade700 : Colors.red.shade700,
                            size: 28)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombreCompleto,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700, color: const Color(0xFF1F1F1F)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('🎓 ${alumno['codigo_estudiante'] ?? 'Sin código'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600, fontWeight: FontWeight.w400),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sinRegistro ? Colors.grey.withOpacity(0.15)
                              : estaAdentro ? Colors.green.withOpacity(0.15)
                              : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sinRegistro ? 'Sin registros' : estaAdentro ? 'Dentro' : 'Fuera',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: sinRegistro ? Colors.grey.shade700
                                : estaAdentro ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 16, color: _naranjaVivo.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}