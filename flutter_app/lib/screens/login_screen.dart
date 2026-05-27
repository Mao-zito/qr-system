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
            colors: [Colors.blue.shade600, Colors.blue.shade900],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: _mostrarRegistro ? _buildRegistroForm() : _buildLoginForm(),
              ),
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
          Icon(Icons.qr_code_2, size: 60, color: Colors.blue.shade600),
          const SizedBox(height: 20),
          Text('QR System',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
          const SizedBox(height: 10),
          Text('Gestión de Objetos con QR',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 30),
          TextFormField(
            controller: _correoController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu correo';
              if (!value.contains('@') || !value.contains('.')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _contrasenaController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              labelText: 'Contraseña',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                icon: Icon(_mostrarContrasena ? Icons.visibility : Icons.visibility_off),
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
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Iniciar Sesión',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta? '),
              GestureDetector(
                onTap: () => setState(() => _mostrarRegistro = true),
                child: Text('Registrate',
                    style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold)),
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
          Icon(Icons.person_add, size: 60, color: Colors.blue.shade600),
          const SizedBox(height: 20),
          Text('Crear Cuenta',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.blue.shade600)),
          const SizedBox(height: 30),

          // Nombre y Apellido en fila
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreControllerReg,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person),
                    labelText: 'Nombre',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _apellidoControllerReg,
                  decoration: InputDecoration(
                    labelText: 'Apellido',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _codigoControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.badge),
              labelText: 'Código de Estudiante',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Ingresa tu código' : null,
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _telefonoControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone),
              labelText: 'Teléfono',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu teléfono';
              if (v.length < 7) return 'Teléfono inválido';
              return null;
            },
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _correoControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: _contrasenaControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              labelText: 'Contraseña',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              suffixIcon: IconButton(
                icon: Icon(_mostrarContrasenaReg ? Icons.visibility : Icons.visibility_off),
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
          const SizedBox(height: 15),

          TextFormField(
            controller: _confirmarContrasenaControllerReg,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              labelText: 'Confirmar Contraseña',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirma tu contraseña';
              if (v != _contrasenaControllerReg.text) return 'Las contraseñas no coinciden';
              return null;
            },
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registro,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Registrarse',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿Ya tienes cuenta? '),
              GestureDetector(
                onTap: () => setState(() => _mostrarRegistro = false),
                child: Text('Inicia Sesión',
                    style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}