import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'admin_home_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _formKeyReg = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _mostrarContrasena = false;
  bool _mostrarContrasenaReg = false;
  bool _mostrarRegistro = false;

  final _nombreControllerReg = TextEditingController();
  final _apellidoControllerReg = TextEditingController();
  final _correoControllerReg = TextEditingController();
  final _contrasenaControllerReg = TextEditingController();
  final _confirmarContrasenaControllerReg = TextEditingController();
  final _telefonoControllerReg = TextEditingController();
  final _codigoControllerReg = TextEditingController();

  final _apiService = ApiService();

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _nombreControllerReg.dispose();
    _apellidoControllerReg.dispose();
    _correoControllerReg.dispose();
    _contrasenaControllerReg.dispose();
    _confirmarContrasenaControllerReg.dispose();
    _telefonoControllerReg.dispose();
    _codigoControllerReg.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await _apiService.login(
        _correoController.text.trim(),
        _contrasenaController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success']) {
          final data = result['data'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('nombre', data['nombre']);
          await prefs.setString('rol', data['rol']);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('¡Bienvenido ${data['nombre']}!')),
            );
            final rol = data['rol'];
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => rol == 'admin'
                    ? AdminHomeScreen(usuario: data['nombre'], token: data['token'])
                    : HomeScreen(usuario: data['nombre'], token: data['token']),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _registro() async {
    if (!_formKeyReg.currentState!.validate()) return;

    if (_contrasenaControllerReg.text != _confirmarContrasenaControllerReg.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.registro(
      _nombreControllerReg.text.trim(),
      _correoControllerReg.text.trim(),
      _contrasenaControllerReg.text,
      'usuario',
      apellido: _apellidoControllerReg.text.trim(),
      telefono: _telefonoControllerReg.text.trim(),
      codigoEstudiante: _codigoControllerReg.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Inicia sesión')),
        );
        _correoController.clear();
        _contrasenaController.clear();
        _nombreControllerReg.clear();
        _apellidoControllerReg.clear();
        _correoControllerReg.clear();
        _contrasenaControllerReg.clear();
        _confirmarContrasenaControllerReg.clear();
        _telefonoControllerReg.clear();
        _codigoControllerReg.clear();
        setState(() => _mostrarRegistro = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF6B00),
              const Color(0xFFFF8C00).withOpacity(0.9),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo moderno
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.95),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          size: 64,
                          color: Color(0xFFFF6B00),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'QR System',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión Inteligente de Objetos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 48),
                // Card con formulario
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _mostrarRegistro ? _buildRegistroForm() : _buildLoginForm(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bienvenido',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF6B00),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Inicia sesión para continuar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 28),
          // Email
          TextFormField(
            controller: _correoController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF6B00)),
              labelText: 'Correo Electrónico',
              hintText: 'ejemplo@email.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu correo';
              if (!value.contains('@') || !value.contains('.')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 18),
          // Contraseña
          TextFormField(
            controller: _contrasenaController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF6B00)),
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFFF6B00),
                ),
                onPressed: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
              ),
            ),
            obscureText: !_mostrarContrasena,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
              if (value.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 28),
          // Botón Login
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Iniciar Sesión',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta? ',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _mostrarRegistro = true),
                child: const Text(
                  'Crea una aquí',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegistroForm() {
    return Form(
      key: _formKeyReg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Crear Cuenta',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFF6B00),
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Completa tu información',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 24),
          // Nombre y Apellido
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreControllerReg,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF6B00)),
                    labelText: 'Nombre',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _apellidoControllerReg,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF6B00)),
                    labelText: 'Apellido',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Código
          TextFormField(
            controller: _codigoControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFFFF6B00)),
              labelText: 'Código de Estudiante',
            ),
            validator: (v) => v == null || v.isEmpty ? 'Ingresa tu código' : null,
          ),
          const SizedBox(height: 14),
          // Teléfono
          TextFormField(
            controller: _telefonoControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFFF6B00)),
              labelText: 'Teléfono',
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu teléfono';
              if (v.length < 7) return 'Teléfono inválido';
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Email
          TextFormField(
            controller: _correoControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFF6B00)),
              labelText: 'Correo Electrónico',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Contraseña
          TextFormField(
            controller: _contrasenaControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF6B00)),
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarContrasenaReg ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFFF6B00),
                ),
                onPressed: () => setState(() => _mostrarContrasenaReg = !_mostrarContrasenaReg),
              ),
            ),
            obscureText: !_mostrarContrasenaReg,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa una contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 14),
          // Confirmar contraseña
          TextFormField(
            controller: _confirmarContrasenaControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFF6B00)),
              labelText: 'Confirmar Contraseña',
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirma tu contraseña';
              if (v != _contrasenaControllerReg.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 28),
          // Botón Registro
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registro,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Registrarse',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // Volver a login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Ya tienes cuenta? ',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _mostrarRegistro = false),
                child: const Text(
                  'Inicia sesión',
                  style: TextStyle(
                    color: Color(0xFFFF6B00),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 40,
          ),
        ],
      ),
    );
  }
}