import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _apiService = ApiService();
  Map<String, dynamic>? _perfil;
  bool _isLoading = true;
  bool _editando = false;
  bool _guardando = false;

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  final _contrasenaActualController = TextEditingController();
  final _contrasenaNuevaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  static const Color _naranjaClaro = Color(0xFF5B7FFF);
  static const Color _blanco = Color(0xFFFAFAFA);

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _contrasenaActualController.dispose();
    _contrasenaNuevaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _isLoading = true);
    final result = await _apiService.obtenerPerfil();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _perfil = result['data'];
          _nombreController.text = _perfil!['nombre'] ?? '';
          _apellidoController.text = _perfil!['apellido'] ?? '';
          _telefonoController.text = _perfil!['telefono'] ?? '';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (imagen == null) return;

    final bytes = await File(imagen.path).readAsBytes();
    final base64 = base64Encode(bytes);

    setState(() => _guardando = true);
    final result = await _apiService.actualizarPerfil(fotoPerfil: base64);
    if (mounted) {
      setState(() => _guardando = false);
      if (result['success']) {
        setState(() => _perfil = result['data']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _guardarPerfil() async {
    setState(() => _guardando = true);
    final result = await _apiService.actualizarPerfil(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );
    if (mounted) {
      setState(() => _guardando = false);
      if (result['success']) {
        setState(() {
          _perfil = result['data'];
          _editando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cambiarContrasena() async {
    if (_contrasenaNuevaController.text != _confirmarContrasenaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _guardando = true);
    final result = await _apiService.cambiarContrasena(
      _contrasenaActualController.text,
      _contrasenaNuevaController.text,
    );
    if (mounted) {
      setState(() => _guardando = false);
      if (result['success']) {
        _contrasenaActualController.clear();
        _contrasenaNuevaController.clear();
        _confirmarContrasenaController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada exitosamente'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
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

  void _mostrarCambiarContrasena() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cambiar contraseña',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F1F1F),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contrasenaActualController,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                prefixIcon: const Icon(Icons.lock_outline),
                prefixIconColor: _naranjaClaro,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contrasenaNuevaController,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                prefixIconColor: _naranjaClaro,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmarContrasenaController,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                prefixIconColor: _naranjaClaro,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _guardando ? null : _cambiarContrasena,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cambiar contraseña',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: _naranjaClaro,
        elevation: 0,
        actions: [
          if (!_editando)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editando = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _editando = false);
                _nombreController.text = _perfil!['nombre'] ?? '';
                _apellidoController.text = _perfil!['apellido'] ?? '';
                _telefonoController.text = _perfil!['telefono'] ?? '';
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_naranjaClaro),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Foto de perfil
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: _naranjaClaro.withOpacity(0.15),
                          backgroundImage: _perfil!['foto_perfil'] != null
                              ? MemoryImage(base64Decode(_perfil!['foto_perfil']))
                              : null,
                          child: _perfil!['foto_perfil'] == null
                              ? Text(
                                  (_perfil!['nombre'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: _naranjaClaro,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _seleccionarFoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _naranjaClaro,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _naranjaClaro.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_perfil!['nombre'] ?? ''} ${_perfil!['apellido'] ?? ''}'.trim(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  Text(
                    _perfil!['rol']?.toString().toUpperCase() ?? '',
                    style: const TextStyle(
                      color: Color(0xFF5B7FFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Datos
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.08),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8E8E8)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFORMACIÓN PERSONAL',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _naranjaClaro,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Divider(height: 20),
                          if (_editando) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _nombreController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre',
                                      prefixIcon: const Icon(Icons.person_outline),
                                      prefixIconColor: _naranjaClaro,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _apellidoController,
                                    decoration: InputDecoration(
                                      labelText: 'Apellido',
                                      prefixIconColor: _naranjaClaro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _telefonoController,
                              decoration: InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                prefixIconColor: _naranjaClaro,
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _guardando ? null : _guardarPerfil,
                                child: _guardando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Guardar cambios',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                          ] else ...[
                            _buildInfoRow(
                              Icons.person_outline,
                              'Nombre completo',
                              '${_perfil!['nombre'] ?? ''} ${_perfil!['apellido'] ?? ''}'.trim(),
                            ),
                            _buildInfoRow(
                              Icons.email_outlined,
                              'Correo',
                              _perfil!['correo'] ?? '-',
                            ),
                            _buildInfoRow(
                              Icons.phone_outlined,
                              'Teléfono',
                              _perfil!['telefono'] ?? 'Sin registrar',
                            ),
                            _buildInfoRow(
                              Icons.badge_outlined,
                              'Código estudiante',
                              _perfil!['codigo_estudiante'] ?? 'Sin registrar',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cambiar contraseña
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _mostrarCambiarContrasena,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Cambiar contraseña'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: _naranjaClaro, width: 1.5),
                        foregroundColor: _naranjaClaro,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cerrar sesión
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Cerrar sesión'),
                            content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _logout();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Cerrar sesión',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Cerrar Sesión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: _naranjaClaro, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F1F1F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}