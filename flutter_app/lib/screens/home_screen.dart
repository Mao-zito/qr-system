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
  await prefs.remove('rol');  // 👈 agrega esto
  _apiService.logout();
  if (mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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

  void _verHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HistorialScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR System'),
        backgroundColor: const Color(0xFF00897B),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Hola, ${widget.usuario}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          PopupMenuButton(
  onSelected: (value) {
    if (value == 'logout') {
      _logout();
    } else if (value == 'perfil') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PerfilScreen()),
      );
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem(
      value: 'perfil',
      child: Row(
        children: [
          Icon(Icons.person_outline),
          SizedBox(width: 8),
          Text('Mi Perfil'),
        ],
      ),
    ),
    const PopupMenuItem(
      value: 'logout',
      child: Row(
        children: [
          Icon(Icons.logout),
          SizedBox(width: 8),
          Text('Cerrar Sesión'),
        ],
      ),
    ),
  ],
),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gestiona tus objetos y visualiza tus ingresos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
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

                    // Botón: Historial
                    _buildActionCard(
                      icon: Icons.history,
                      titulo: 'Mi Historial',
                      descripcion: 'Ver todos mis ingresos registrados',
                      onTap: _verHistorial,
                    ),
                    const SizedBox(height: 32),

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
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00897B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.backpack,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              title: Text(
                                objeto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                objeto.descripcion ?? 'Sin descripción',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.qr_code,
                                  color: Color(0xFF00897B),
                                ),
                                onPressed: () => _verCodigoQR(objeto),
                                tooltip: 'Ver código QR',
                              ),
                              onTap: () => _verCodigoQR(objeto),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _irARegistroObjeto,
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Objeto'),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: BorderRadius.circular(10),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFCCCCCC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
