import 'package:flutter/material.dart';

import '../models/objeto_model.dart';
import '../services/api_service.dart';
import 'historial_screen.dart';
import 'perfil_screen.dart';
import 'registrar_objeto_screen.dart';
import 'ver_qr_screen.dart';

class HomeScreen extends StatefulWidget {
  final String usuario;
  final String token;

  const HomeScreen({
    Key? key,
    required this.usuario,
    required this.token,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  List<Objeto> _misObjetos = [];
  bool _isLoading = true;
  int _selectedIndex = 0;
  
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _blanco = Color(0xFFFAFAFA);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);

  @override
  void initState() {
    super.initState();
    _apiService.setToken(widget.token);
    _cargarMisObjetos();
  }

  Future<void> _cargarMisObjetos() async {
    setState(() => _isLoading = true);
    
    final result = await _apiService.obtenerMisObjetos();
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _misObjetos = result['data'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Error al cargar objetos'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistorialScreen()),
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

  void _irARegistroObjeto() async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistrarObjetoScreen(),
      ),
    );
    if (resultado == true) {
      _cargarMisObjetos();
    }
  }

  void _verCodigoQR(Objeto objeto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerQrScreen(objeto: objeto),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('QR System'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
                ),
              )
            : SingleChildScrollView(
                 padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).padding.bottom + 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título principal
                    Text(
                      '¡Hola, ${widget.usuario}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1a1a1a),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gestiona tus objetos y visualiza tus ingresos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Card destacada: Registrar Objeto
                    _buildActionCard(
                      icon: Icons.add_circle,
                      titulo: 'Registrar Objeto',
                      descripcion: 'Crea un nuevo objeto y obtén su código QR',
                      onTap: _irARegistroObjeto,
                    ),
                    const SizedBox(height: 28),

                    // Sección: Mis Objetos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MIS OBJETOS (${_misObjetos.length})',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF666666),
                                letterSpacing: 0.5,
                              ),
                        ),
                        if (_misObjetos.isNotEmpty)
                          Text(
                            'Ver todo',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: _naranjaVivo,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_misObjetos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Column(
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
                                'No tienes objetos registrados',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Crea tu primer objeto arriba',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _misObjetos.length,
                        itemBuilder: (context, index) {
                          final objeto = _misObjetos[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildObjetoCard(objeto),
                          );
                        },
                      ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irARegistroObjeto,
        backgroundColor: _naranjaVivo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Objeto'),
        foregroundColor: Colors.white,
        elevation: 12,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
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
              icon: Icon(Icons.home_outlined, size: 26),
              activeIcon: Icon(Icons.home, size: 26),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined, size: 26),
              activeIcon: Icon(Icons.history, size: 26),
              label: 'Historial',
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

  Widget _buildObjetoCard(Objeto objeto) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _verCodigoQR(objeto),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _naranjaVivo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        objeto.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        objeto.descripcion ?? 'Sin descripción',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _naranjaVivo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_2,
                    color: _naranjaVivo,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _naranjaVivo,
            _naranjaNaranja,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _naranjaVivo.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        descripcion,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
