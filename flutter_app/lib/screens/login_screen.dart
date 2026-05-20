import 'package:flutter/material.dart';
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
  bool _isLoading = false;
  bool _mostrarContrasena = false;
  bool _mostrarRegistro = false;
  
  // Controladores para registro
  final _nombreControllerReg = TextEditingController();
  final _correoControllerReg = TextEditingController();
  final _contrasenaControllerReg = TextEditingController();
  final _confirmarContrasenaControllerReg = TextEditingController();

  final _apiService = ApiService();

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    _nombreControllerReg.dispose();
    _correoControllerReg.dispose();
    _contrasenaControllerReg.dispose();
    _confirmarContrasenaControllerReg.dispose();
    super.dispose();
  }

 Future<void> _login() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    final result = await _apiService.login(
      _correoController.text,
      _contrasenaController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        final data = result['data'];

        // 👇 Guardar sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('nombre', data['nombre']);
        await prefs.setString('rol', data['rol']); // 👈 agrega esto

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
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

  Future<void> _registro() async {
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
      _nombreControllerReg.text,
      _correoControllerReg.text,
      _contrasenaControllerReg.text,
      'usuario',
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Inicia sesión')),
        );
        
        // Limpiar campos y volver al login
        _correoController.clear();
        _contrasenaController.clear();
        _nombreControllerReg.clear();
        _correoControllerReg.clear();
        _contrasenaControllerReg.clear();
        _confirmarContrasenaControllerReg.clear();
        
        setState(() => _mostrarRegistro = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
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
              Colors.blue.shade600,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
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
          // Logo
          Icon(
            Icons.qr_code_2,
            size: 60,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 20),
          Text(
            'QR System',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Gestión de Objetos con QR',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),

          // Email
          TextFormField(
            controller: _correoController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Contraseña
          TextFormField(
            controller: _contrasenaController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              labelText: 'Contraseña',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _mostrarContrasena = !_mostrarContrasena);
                },
              ),
            ),
            obscureText: !_mostrarContrasena,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),

          // Botón Login
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : const Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 15),

          // Link a registro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¿No tienes cuenta? '),
              GestureDetector(
                onTap: () => setState(() => _mostrarRegistro = true),
                child: Text(
                  'Registrate',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.person_add,
          size: 60,
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 20),
        Text(
          'Crear Cuenta',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade600,
          ),
        ),
        const SizedBox(height: 30),

        // Nombre
        TextFormField(
          controller: _nombreControllerReg,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person),
            labelText: 'Nombre Completo',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),

        // Email
        TextFormField(
          controller: _correoControllerReg,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email),
            labelText: 'Correo Electrónico',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),

        // Contraseña
        TextFormField(
          controller: _contrasenaControllerReg,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock),
            labelText: 'Contraseña',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 15),

        // Confirmar Contraseña
        TextFormField(
          controller: _confirmarContrasenaControllerReg,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock),
            labelText: 'Confirmar Contraseña',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 30),

        // Botón Registrar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _registro,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Registrarse',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
        const SizedBox(height: 15),

        // Link a login
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿Ya tienes cuenta? '),
            GestureDetector(
              onTap: () => setState(() => _mostrarRegistro = false),
              child: Text(
                'Inicia Sesión',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
