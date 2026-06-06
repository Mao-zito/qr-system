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

  static const Color _naranjaVivo   = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco        = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        if (result['success']) _anomalias = result['data'];
        _cargandoAnomalias = false;
      });
    }
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
            Tab(icon: Icon(Icons.people_outline, size: 20), text: 'Perfiles'),
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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
        ),
      );
    }
    if (_resumen == null) {
      return _buildError(_cargarResumen);
    }

    final perfiles = Map<String, dynamic>.from(_resumen!['perfiles'] ?? {});
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
              boxShadow: [
                BoxShadow(
                  color: _naranjaVivo.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_outlined, color: Colors.white, size: 32),
                const SizedBox(height: 10),
                const Text(
                  'Machine Learning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'KMeans + Isolation Forest',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Última actualización: $ultima',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cards de perfiles
          _buildSectionTitle('CLASIFICACIÓN DE ALUMNOS'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPerfilStat('Normal',    perfiles['Normal']?.toString()    ?? '0', Colors.green),
              const SizedBox(width: 10),
              _buildPerfilStat('Irregular', perfiles['Irregular']?.toString() ?? '0', Colors.orange),
              const SizedBox(width: 10),
              _buildPerfilStat('Ausente',   perfiles['Ausente']?.toString()   ?? '0', Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Anomalías
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
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber_outlined, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_resumen!['total_anomalias'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'escaneos sospechosos',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                            Expanded(
                              child: Text(
                                m['motivo'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${m['total']}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
        ),
      );
    }
    if (_perfiles.isEmpty) return _buildError(_cargarPerfiles);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
      itemCount: _perfiles.length,
      itemBuilder: (context, index) {
        final p = _perfiles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPerfilCard(p),
        );
      },
    );
  }

  Widget _buildPerfilCard(dynamic p) {
    final perfil  = p['perfil'] ?? 'Normal';
    final color   = _colorPerfil(perfil);
    final icono   = _iconoPerfil(perfil);

    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icono, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p['nombre'] ?? ''} ${p['apellido'] ?? ''}'.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1F1F1F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '🎓 ${p['codigo_estudiante'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMiniChip('${p['total_escaneos']} escaneos', Colors.grey.shade200, Colors.grey.shade700),
                      const SizedBox(width: 6),
                      _buildMiniChip('${p['dias_activo']} días', Colors.grey.shade200, Colors.grey.shade700),
                      const SizedBox(width: 6),
                      _buildMiniChip('${p['frecuencia_semanal']}/sem', color.withOpacity(0.15), color),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                perfil,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 3: ANOMALÍAS ────────────────────────────────────────────────────────

  Widget _buildAnomaliasTab(double bottomPadding) {
    if (_cargandoAnomalias) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
        ),
      );
    }
    if (_anomalias.isEmpty) return _buildError(_cargarAnomalias);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 24),
      itemCount: _anomalias.length,
      itemBuilder: (context, index) {
        final a = _anomalias[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildAnomaliaCard(a),
        );
      },
    );
  }

  Widget _buildAnomaliaCard(dynamic a) {
    final fecha = _formatearFecha(a['fecha_hora']?.toString() ?? '');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_outlined, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${a['nombre'] ?? ''} ${a['apellido'] ?? ''}'.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF1F1F1F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a['motivo'] ?? '',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '📦 ${a['objeto'] ?? ''} • 🕐 $fecha',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _naranjaVivo,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildPerfilStat(String label, String valor, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildMiniChip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
        ),
      );

  Widget _buildError(VoidCallback onRetry) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Error al cargar datos',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
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