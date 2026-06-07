import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminMlScreen extends StatefulWidget {
  const AdminMlScreen({Key? key}) : super(key: key);

  @override
  State<AdminMlScreen> createState() => _AdminMlScreenState();
}

class _AdminMlScreenState extends State<AdminMlScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _resumen;
  List<dynamic> _perfiles = [];
  List<dynamic> _anomalias = [];

  bool _cargandoResumen   = true;
  bool _cargandoPerfiles  = true;
  bool _cargandoAnomalias = true;

  // Filtro activo en perfiles
  String? _filtroPerfilActivo;

  // Buscador anomalías
  final _busquedaController = TextEditingController();
  List<dynamic> _anomaliasFiltradas = [];

  static const Color _naranjaVivo    = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco         = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    _cargarResumen();
    _cargarPerfiles();
    _cargarAnomalias();
  }

  Future<void> _cargarResumen() async {
    setState(() => _cargandoResumen = true);
    final result = await _apiService.obtenerMlResumen();
    if (mounted) {
      setState(() {
        if (result['success']) _resumen = result['data'];
        _cargandoResumen = false;
      });
    }
  }

  Future<void> _cargarPerfiles() async {
    setState(() => _cargandoPerfiles = true);
    final result = await _apiService.obtenerMlPerfiles();
    if (mounted) {
      setState(() {
        if (result['success']) _perfiles = result['data'];
        _cargandoPerfiles = false;
      });
    }
  }

  Future<void> _cargarAnomalias() async {
    setState(() => _cargandoAnomalias = true);
    final result = await _apiService.obtenerMlAnomalias();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _anomalias = result['data'];
          _anomaliasFiltradas = _anomalias;
        }
        _cargandoAnomalias = false;
      });
    }
  }

  void _filtrarAnomalias(String query) {
    setState(() {
      _anomaliasFiltradas = _anomalias.where((a) {
        final nombre   = '${a['nombre'] ?? ''} ${a['apellido'] ?? ''}'.toLowerCase();
        final motivo   = (a['motivo'] ?? '').toLowerCase();
        final objeto   = (a['objeto'] ?? '').toLowerCase();
        final codigo   = (a['codigo_estudiante'] ?? '').toLowerCase();
        return query.isEmpty ||
            nombre.contains(query) ||
            motivo.contains(query) ||
            objeto.contains(query) ||
            codigo.contains(query);
      }).toList();
    });
  }

  // ✅ navegar a perfiles con filtro aplicado
  void _irAPerfilesFiltrado(String perfil) {
    setState(() => _filtroPerfilActivo = perfil);
    _tabController.animateTo(1);
  }

  List<dynamic> get _perfilesFiltrados {
    if (_filtroPerfilActivo == null) return _perfiles;
    return _perfiles.where((p) => p['perfil'] == _filtroPerfilActivo).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Análisis ML'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _cargarTodo,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Resumen'),
            Tab(icon: Icon(Icons.people_outline,     size: 20), text: 'Perfiles'),
            Tab(icon: Icon(Icons.warning_amber_outlined, size: 20), text: 'Anomalías'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumenTab(bottomPadding),
          _buildPerfilesTab(bottomPadding),
          _buildAnomaliasTab(bottomPadding),
        ],
      ),
    );
  }

  // ── TAB 1: RESUMEN ──────────────────────────────────────────────────────────

  Widget _buildResumenTab(double bottomPadding) {
    if (_cargandoResumen) {
      return const Center(child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
      ));
    }
    if (_resumen == null) return _buildError(_cargarResumen);

    final perfiles  = Map<String, dynamic>.from(_resumen!['perfiles'] ?? {});
    final porMotivo = List<dynamic>.from(_resumen!['anomalias_por_motivo'] ?? []);
    final ultima    = _resumen!['ultima_actualizacion'] ?? 'N/A';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPadding + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_naranjaVivo, _naranjaNaranja],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _naranjaVivo.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_outlined, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                const Text('Machine Learning', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('KMeans + Isolation Forest', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Text('Última actualización: $ultima', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('CLASIFICACIÓN DE ALUMNOS'),
          const SizedBox(height: 6),
          Text('Toca un grupo para ver los alumnos', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 12),

          // ✅ rectángulos clickeables que navegan a perfiles filtrado
          Row(
            children: [
              _buildPerfilStat('Normal',    perfiles['Normal']?.toString()    ?? '0', Colors.green,  () => _irAPerfilesFiltrado('Normal')),
              const SizedBox(width: 10),
              _buildPerfilStat('Irregular', perfiles['Irregular']?.toString() ?? '0', Colors.orange, () => _irAPerfilesFiltrado('Irregular')),
              const SizedBox(width: 10),
              _buildPerfilStat('Ausente',   perfiles['Ausente']?.toString()   ?? '0', Colors.red,    () => _irAPerfilesFiltrado('Ausente')),
            ],
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('ANOMALÍAS DETECTADAS'),
          const SizedBox(height: 12),
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.warning_amber_outlined, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_resumen!['total_anomalias'] ?? 0}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red)),
                        Text('escaneos sospechosos',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                if (porMotivo.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 12),
                  ...porMotivo.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(child: Text(m['motivo'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 13))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('${m['total']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: PERFILES ─────────────────────────────────────────────────────────

  Widget _buildPerfilesTab(double bottomPadding) {
    if (_cargandoPerfiles) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo)));
    }
    if (_perfiles.isEmpty) return _buildError(_cargarPerfiles);

    final lista = _perfilesFiltrados;

    return Column(
      children: [
        // ✅ filtros por perfil
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              _buildFiltroChip('Todos',     null),
              const SizedBox(width: 8),
              _buildFiltroChip('Normal',    'Normal'),
              const SizedBox(width: 8),
              _buildFiltroChip('Irregular', 'Irregular'),
              const SizedBox(width: 8),
              _buildFiltroChip('Ausente',   'Ausente'),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
        // contador
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                '${lista.length} alumno${lista.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
              if (_filtroPerfilActivo != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _filtroPerfilActivo = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _naranjaVivo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Limpiar filtro', style: TextStyle(fontSize: 11, color: _naranjaVivo, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.close, size: 12, color: _naranjaVivo),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: lista.isEmpty
              ? Center(child: Text('No hay alumnos con este perfil', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 24),
                  itemCount: lista.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPerfilCard(lista[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String? valor) {
    final activo = _filtroPerfilActivo == valor;
    final color  = valor == null ? _naranjaVivo
        : valor == 'Normal'    ? Colors.green
        : valor == 'Irregular' ? Colors.orange
        : Colors.red;

    return GestureDetector(
      onTap: () => setState(() => _filtroPerfilActivo = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: activo ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilCard(dynamic p) {
    final perfil = p['perfil'] ?? 'Normal';
    final color  = _colorPerfil(perfil);
    final icono  = _iconoPerfil(perfil);

    return GestureDetector(
      // ✅ dialog de detalle al tocar
      onTap: () => _mostrarDetalleAlumno(p),
      child: Container(
        decoration: _cardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(13)),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1F1F1F)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text('🎓 ${p['codigo_estudiante'] ?? ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(height: 6),
                    // ✅ chips en wrap para evitar overflow
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildMiniChip('${p['total_escaneos']} escaneos', Colors.grey.shade200, Colors.grey.shade700),
                        _buildMiniChip('${p['dias_activo']} días',        Colors.grey.shade200, Colors.grey.shade700),
                        _buildMiniChip('${p['frecuencia_semanal']}/sem',  color.withOpacity(0.15), color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(perfil, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleAlumno(dynamic p) {
    final perfil = p['perfil'] ?? 'Normal';
    final color  = _colorPerfil(perfil);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_iconoPerfil(perfil), color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim(),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetalleRow('Perfil',         perfil,                           color),
            _buildDetalleRow('Código',         p['codigo_estudiante'] ?? '-',    Colors.grey.shade700),
            _buildDetalleRow('Correo',         p['correo'] ?? '-',               Colors.grey.shade700),
            _buildDetalleRow('Total escaneos', '${p['total_escaneos']}',         Colors.grey.shade700),
            _buildDetalleRow('Días activo',    '${p['dias_activo']} días',       Colors.grey.shade700),
            _buildDetalleRow('Hora promedio',  '${p['hora_promedio']}:00h',      Colors.grey.shade700),
            _buildDetalleRow('Freq. semanal',  '${p['frecuencia_semanal']} escaneos/sem', Colors.grey.shade700),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: _naranjaVivo, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(String label, String valor, Color colorValor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(valor, style: TextStyle(fontSize: 13, color: colorValor, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );

  // ── TAB 3: ANOMALÍAS ────────────────────────────────────────────────────────

  Widget _buildAnomaliasTab(double bottomPadding) {
    if (_cargandoAnomalias) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo)));
    }
    if (_anomalias.isEmpty) return _buildError(_cargarAnomalias);

    return Column(
      children: [
        // ✅ buscador
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _busquedaController,
            onChanged: _filtrarAnomalias,
            decoration: const InputDecoration(
              hintText: 'Buscar por alumno, objeto, motivo...',
              prefixIcon: Icon(Icons.search_outlined),
              prefixIconColor: _naranjaVivo,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text('${_anomaliasFiltradas.length} anomalía${_anomaliasFiltradas.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: _anomaliasFiltradas.isEmpty
              ? Center(child: Text('Sin resultados', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 24),
                  itemCount: _anomaliasFiltradas.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildAnomaliaCard(_anomaliasFiltradas[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAnomaliaCard(dynamic a) {
    final fecha = _formatearFecha(a['fecha_hora']?.toString() ?? '');

    return GestureDetector(
      // ✅ dialog de detalle al tocar
      onTap: () => _mostrarDetalleAnomalia(a, fecha),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.04), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.warning_amber_outlined, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a['nombre'] ?? ''} ${a['apellido'] ?? ''}'.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1F1F1F)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(a['motivo'] ?? '', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('📦 ${a['objeto'] ?? ''}  🕐 $fecha',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 11), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleAnomalia(dynamic a, String fecha) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            const Text('Detalle anomalía', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.red)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetalleRow('Alumno',    '${a['nombre'] ?? ''} ${a['apellido'] ?? ''}'.trim(), Colors.grey.shade800),
            _buildDetalleRow('Código',    a['codigo_estudiante'] ?? '-',    Colors.grey.shade700),
            _buildDetalleRow('Objeto',    a['objeto'] ?? '-',               Colors.grey.shade700),
            _buildDetalleRow('Motivo',    a['motivo'] ?? '-',               Colors.red),
            _buildDetalleRow('Fecha',     fecha,                            Colors.grey.shade700),
            _buildDetalleRow('Ubicación', a['ubicacion'] ?? '-',            Colors.grey.shade700),
            _buildDetalleRow('Evento',    a['tipo_evento'] ?? '-',          Colors.grey.shade700),
            _buildDetalleRow('Score ML',  '${a['score']}',                  Colors.red.shade300),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: _naranjaVivo, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _naranjaVivo, letterSpacing: 0.8),
  );

  Widget _buildPerfilStat(String label, String valor, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 11, color: color.withOpacity(0.6)),
                const SizedBox(width: 3),
                Text('ver', style: TextStyle(fontSize: 10, color: color.withOpacity(0.6))),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildMiniChip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
  );

  Widget _buildError(VoidCallback onRetry) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text('Error al cargar datos', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      ],
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    color: Colors.white,
    border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, spreadRadius: 2)],
  );

  Color _colorPerfil(String perfil) {
    switch (perfil) {
      case 'Normal':    return Colors.green;
      case 'Irregular': return Colors.orange;
      case 'Ausente':   return Colors.red;
      default:          return Colors.grey;
    }
  }

  IconData _iconoPerfil(String perfil) {
    switch (perfil) {
      case 'Normal':    return Icons.check_circle_outline;
      case 'Irregular': return Icons.warning_amber_outlined;
      case 'Ausente':   return Icons.person_off_outlined;
      default:          return Icons.person_outline;
    }
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