import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/objeto_model.dart';
import '../services/api_service.dart';
import 'historial_screen.dart';
import 'login_screen.dart';
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
  
  static const Color _naranja = Color(0xFF5B7FFF);
  static const Color _naranjaClaro = Color(0xFF5B7FFF);
  static const Color _blanco = Color(0xFFFAFAFA);

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
    if (index == 1) {
      // Historial
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistorialScreen()),
      );
    } else if (index == 2) {
      // Perfil
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PerfilScreen()),
      );
    } else {
      // Inicio
      setState(() {
        _selectedIndex = 0;
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_naranjaClaro),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    const Text(
                      'Panel de Control',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gestiona tus objetos y visualiza tus ingresos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón: Registrar Objeto
                    _buildActionCard(
                      icon: Icons.add_circle_outline,
                      titulo: 'Registrar Objeto',
                      descripcion: 'Crea un nuevo objeto y obtén su código QR',
                      onTap: _irARegistroObjeto,
                    ),
                    const SizedBox(height: 12),

                    // Sección: Mis Objetos
                    const Text(
                      'MIS OBJETOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_misObjetos.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No tienes objetos registrados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
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
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE8E8E8),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _naranjaClaro.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.backpack,
                                      color: _naranjaClaro,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  objeto.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Color(0xFF1F1F1F),
                                  ),
                                ),
                                subtitle: Text(
                                  objeto.descripcion ?? 'Sin descripción',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.qr_code_2,
                                    color: _naranjaClaro,
                                    size: 22,
                                  ),
                                  onPressed: () => _verCodigoQR(objeto),
                                  tooltip: 'Ver código QR',
                                ),
                                onTap: () => _verCodigoQR(objeto),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irARegistroObjeto,
        backgroundColor: _naranjaClaro,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Objeto'),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        selectedItemColor: _naranjaClaro,
        unselectedItemColor: Color(0xFFB8B8B8),
        iconSize: 24,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: _naranjaClaro.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _blanco.withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _naranjaClaro.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _naranjaClaro,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _naranjaClaro.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _naranjaClaro.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
