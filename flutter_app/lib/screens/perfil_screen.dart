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

  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

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
    final base64Str = base64Encode(bytes);

    setState(() => _guardando = true);
    final result = await _apiService.actualizarPerfil(fotoPerfil: base64Str);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          // ✅ respeta el teclado en el bottom sheet
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ handle visual del bottom sheet
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Cambiar contraseña',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _naranjaVivo,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Actualiza tu contraseña para mantener tu cuenta segura',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contrasenaActualController,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFFF6B00)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contrasenaNuevaController,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFFF6B00)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmarContrasenaController,
              decoration: const InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFFF6B00)),
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
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Cambiar contraseña',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cerrar sesión',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ padding inferior del sistema (botones de navegación del celular)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
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
                valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                // ✅ padding dinámico — respeta botones del sistema
                bottomPadding + 32,
              ),
              child: Column(
                children: [
                  // ── Foto de perfil ──────────────────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_naranjaVivo, _naranjaNaranja],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _naranjaVivo.withOpacity(0.25),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: _blanco,
                            backgroundImage: _perfil!['foto_perfil'] != null
                                ? MemoryImage(base64Decode(_perfil!['foto_perfil']))
                                : null,
                            child: _perfil!['foto_perfil'] == null
                                ? Text(
                                    (_perfil!['nombre'] ?? 'U')[0].toUpperCase(),
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: _naranjaVivo,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _seleccionarFoto,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _naranjaVivo,
                                shape: BoxShape.circle,
                                border: Border.all(color: _blanco, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _naranjaVivo.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre y rol
                  Text(
                    '${_perfil!['nombre'] ?? ''} ${_perfil!['apellido'] ?? ''}'.trim(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1F1F1F),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _naranjaVivo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _perfil!['rol']?.toString().toUpperCase() ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _naranjaVivo,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Card información personal ────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'INFORMACIÓN PERSONAL',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: _naranjaVivo,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: 18),
                        if (_editando) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFFFF6B00)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _apellidoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Apellido',
                                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFFFF6B00)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFFFF6B00)),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _guardando ? null : _guardarPerfil,
                              child: _guardando
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Guardar cambios',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                            ),
                          ),
                        ] else ...[
                          _buildInfoRow(Icons.person_outline, 'Nombre completo',
                              '${_perfil!['nombre'] ?? ''} ${_perfil!['apellido'] ?? ''}'.trim()),
                          _buildDivider(),
                          _buildInfoRow(Icons.email_outlined, 'Correo', _perfil!['correo'] ?? '-'),
                          _buildDivider(),
                          _buildInfoRow(Icons.phone_outlined, 'Teléfono',
                              _perfil!['telefono'] ?? 'Sin registrar'),
                          _buildDivider(),
                          _buildInfoRow(Icons.badge_outlined, 'Código estudiante',
                              _perfil!['codigo_estudiante'] ?? 'Sin registrar'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Botón cambiar contraseña ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _mostrarCambiarContrasena,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text(
                        'Cambiar contraseña',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: const BorderSide(color: _naranjaVivo, width: 2),
                        foregroundColor: _naranjaVivo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Botón cerrar sesión ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _confirmarLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.grey.shade100, height: 1, thickness: 1);

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _naranjaVivo.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _naranjaVivo, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1F1F),
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}