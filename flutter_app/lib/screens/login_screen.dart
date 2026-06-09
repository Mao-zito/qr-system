import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'admin_home_screen.dart';
import 'home_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController     = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  final _formKeyReg = GlobalKey<FormState>();

  bool _isLoading            = false;
  bool _mostrarContrasena    = false;
  bool _mostrarContrasenaReg = false;
  bool _mostrarRegistro      = false;

  final _nombreControllerReg              = TextEditingController();
  final _apellidoControllerReg            = TextEditingController();
  final _correoControllerReg              = TextEditingController();
  final _contrasenaControllerReg          = TextEditingController();
  final _confirmarContrasenaControllerReg = TextEditingController();
  final _telefonoControllerReg            = TextEditingController();
  final _codigoControllerReg              = TextEditingController();

  final _apiService = ApiService();

  static const Color _naranja  = Color(0xFFFF6B00);
  static const Color _naranja2 = Color(0xFFFF8C00);

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await _apiService.login(
      _correoController.text.trim(),
      _contrasenaController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        final data  = result['data'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token',  data['token']);
        await prefs.setString('nombre', data['nombre']);
        await prefs.setString('rol',    data['rol']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Bienvenido ${data['nombre']}!')),
          );
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => data['rol'] == 'admin'
                ? AdminHomeScreen(usuario: data['nombre'], token: data['token'])
                : HomeScreen(usuario: data['nombre'], token: data['token']),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _registro() async {
    if (!_formKeyReg.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final result = await _apiService.registro(
      _nombreControllerReg.text.trim(),
      _correoControllerReg.text.trim(),
      _contrasenaControllerReg.text,
      'usuario',
      apellido:         _apellidoControllerReg.text.trim(),
      telefono:         _telefonoControllerReg.text.trim(),
      codigoEstudiante: _codigoControllerReg.text.trim(),
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro exitoso! Inicia sesión')),
        );
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
    return GestureDetector(
      // ✅ Cierra el teclado al tocar fuera de cualquier campo
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        // ✅ true (valor por defecto) — Flutter mueve el layout cuando aparece el teclado
        resizeToAvoidBottomInset: true,
        // ✅ El color del Scaffold coincide con el extremo inferior del gradiente
        //    para que no haya diferencia visible si el contenido no llena la pantalla
        backgroundColor: _naranja2,
        body: Container(
          // ✅ El Container ocupa TODA la pantalla (incluyendo zona del sistema)
          //    así el gradiente es continuo de arriba a abajo sin franjas de otro color
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_naranja, _naranja2],
            ),
          ),
          child: SafeArea(
            // ✅ bottom: false → el gradiente se pinta hasta el borde físico,
            //    el SafeArea solo protege la parte superior (notch/status bar)
            bottom: false,
            child: _mostrarRegistro ? _buildRegistro() : _buildLogin(),
          ),
        ),
      ),
    );
  }

  // ── LOGIN ───────────────────────────────────────────────────────────────────

  Widget _buildLogin() {
    // ✅ Detecta si el teclado está abierto
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        24, 40, 24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        children: [
          // ✅ Logo oculto cuando el teclado está abierto
          if (!keyboardOpen) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.qr_code_2, size: 56, color: _naranja),
            ),
            const SizedBox(height: 20),
            const Text(
              'QR System',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gestión Inteligente de Objetos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ✅ Cuando el teclado está abierto, pequeño espacio superior
          if (keyboardOpen) const SizedBox(height: 16),

          // Card login
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 28,
                  spreadRadius: 6,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _naranja,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),

                  _buildField(
                    controller: _correoController,
                    label: 'Correo Electrónico',
                    hint: 'ejemplo@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu correo';
                      if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _contrasenaController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscure: !_mostrarContrasena,
                    suffix: IconButton(
                      icon: Icon(
                        _mostrarContrasena ? Icons.visibility : Icons.visibility_off,
                        color: _naranja,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _mostrarContrasena = !_mostrarContrasena),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),

                  // Link olvidaste contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: _naranja,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _mostrarRegistro = true),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          children: const [
                            TextSpan(text: '¿No tienes cuenta? '),
                            TextSpan(
                              text: 'Crea una aquí',
                              style: TextStyle(
                                color: _naranja,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Espacio inferior para que el contenido no quede pegado al borde
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  // ── REGISTRO ────────────────────────────────────────────────────────────────

  Widget _buildRegistro() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => setState(() => _mostrarRegistro = false),
              ),
              const Text(
                'Crear cuenta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 28,
                    spreadRadius: 6,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKeyReg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información personal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _naranja,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _nombreControllerReg,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _apellidoControllerReg,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _codigoControllerReg,
                      label: 'Código de Estudiante',
                      icon: Icons.badge_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingresa tu código' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _telefonoControllerReg,
                      label: 'Teléfono',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu teléfono';
                        if (v.length < 7) return 'Teléfono inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Acceso',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _naranja,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _correoControllerReg,
                      label: 'Correo Electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu correo';
                        if (!v.contains('@') || !v.contains('.'))
                          return 'Correo inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _contrasenaControllerReg,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscure: !_mostrarContrasenaReg,
                      suffix: IconButton(
                        icon: Icon(
                          _mostrarContrasenaReg
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _naranja,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _mostrarContrasenaReg = !_mostrarContrasenaReg),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _confirmarContrasenaControllerReg,
                      label: 'Confirmar Contraseña',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                        if (v != _contrasenaControllerReg.text)
                          return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _registro,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          _isLoading ? 'Registrando...' : 'Crear cuenta',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _mostrarRegistro = false),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            children: const [
                              TextSpan(text: '¿Ya tienes cuenta? '),
                              TextSpan(
                                text: 'Inicia sesión',
                                style: TextStyle(
                                  color: _naranja,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Campo reutilizable ──────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _naranja, size: 20),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: _naranja, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      ),
    );
  }
}