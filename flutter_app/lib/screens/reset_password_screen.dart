import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _apiService = ApiService();

  // Paso actual: 1 = correo, 2 = código, 3 = nueva contraseña
  int _paso = 1;
  bool _isLoading = false;

  final _correoController        = TextEditingController();
  final _codigoController        = TextEditingController();
  final _nuevaController         = TextEditingController();
  final _confirmarController     = TextEditingController();

  bool _mostrarNueva     = false;
  bool _mostrarConfirmar = false;

  static const Color _naranja  = Color(0xFFFF6B00);
  static const Color _naranja2 = Color(0xFFFF8C00);

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  // ── Paso 1: solicitar código ───────────────────────────────────────────────
  Future<void> _solicitarCodigo() async {
    final correo = _correoController.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      _snack('Ingresa un correo válido', error: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await _apiService.solicitarReset(correo);
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _paso = 2);
        _snack('Código enviado a $correo');
      } else {
        _snack(result['error'] ?? 'Error al enviar el código', error: true);
      }
    }
  }

  // ── Paso 2: verificar código ───────────────────────────────────────────────
  Future<void> _verificarCodigo() async {
    final codigo = _codigoController.text.trim();
    if (codigo.length != 6) {
      _snack('Ingresa el código de 6 dígitos', error: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await _apiService.verificarCodigoReset(
      _correoController.text.trim(),
      codigo,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _paso = 3);
      } else {
        _snack(result['error'] ?? 'Código inválido o expirado', error: true);
      }
    }
  }

  // ── Paso 3: nueva contraseña ───────────────────────────────────────────────
  Future<void> _restablecerContrasena() async {
    final nueva     = _nuevaController.text;
    final confirmar = _confirmarController.text;

    if (nueva.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres', error: true);
      return;
    }
    if (nueva != confirmar) {
      _snack('Las contraseñas no coinciden', error: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.restablecerContrasena(
      _correoController.text.trim(),
      _codigoController.text.trim(),
      nueva,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        _snack('¡Contraseña restablecida! Inicia sesión');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        _snack(result['error'] ?? 'Error al restablecer', error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_naranja, _naranja2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar manual
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () {
                        if (_paso > 1) {
                          setState(() => _paso--);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Text('Restablecer contraseña',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Indicador de pasos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: List.generate(3, (i) {
                    final activo   = i + 1 == _paso;
                    final completo = i + 1 < _paso;
                    return Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: completo ? Colors.white : activo ? Colors.white : Colors.white.withOpacity(0.3),
                            ),
                            child: Center(
                              child: completo
                                  ? Icon(Icons.check, size: 16, color: _naranja)
                                  : Text('${i + 1}',
                                      style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w800,
                                        color: activo ? _naranja : Colors.white.withOpacity(0.6),
                                      )),
                            ),
                          ),
                          if (i < 2)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: i + 1 < _paso ? Colors.white : Colors.white.withOpacity(0.3),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Correo',     style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                    Text('Código',     style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                    Text('Contraseña', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Card
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 28, spreadRadius: 6)],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: _buildPaso(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaso() {
    switch (_paso) {
      case 1: return _buildPaso1();
      case 2: return _buildPaso2();
      case 3: return _buildPaso3();
      default: return _buildPaso1();
    }
  }

  // ── UI Paso 1 ──────────────────────────────────────────────────────────────
  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.email_outlined, color: _naranja, size: 36),
        const SizedBox(height: 12),
        const Text('¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F1F1F))),
        const SizedBox(height: 8),
        Text('Ingresa tu correo y te enviaremos un código de 6 dígitos.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 28),
        _buildField(
          controller: _correoController,
          label: 'Correo registrado',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _solicitarCodigo,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.send_outlined),
            label: Text(_isLoading ? 'Enviando...' : 'Enviar código',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── UI Paso 2 ──────────────────────────────────────────────────────────────
  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_clock_outlined, color: _naranja, size: 36),
        const SizedBox(height: 12),
        const Text('Ingresa el código',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F1F1F))),
        const SizedBox(height: 8),
        Text('Revisa tu correo ${_correoController.text} y escribe el código de 6 dígitos.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 28),

        // Campo código grande y centrado
        TextField(
          controller: _codigoController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 12, color: _naranja),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(fontSize: 32, letterSpacing: 12, color: Colors.grey.shade300, fontWeight: FontWeight.w900),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: _naranja, width: 2)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : _solicitarCodigo,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reenviar código'),
            style: TextButton.styleFrom(foregroundColor: _naranja),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _verificarCodigo,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.check_circle_outline),
            label: Text(_isLoading ? 'Verificando...' : 'Verificar código',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  // ── UI Paso 3 ──────────────────────────────────────────────────────────────
  Widget _buildPaso3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_reset_outlined, color: _naranja, size: 36),
        const SizedBox(height: 12),
        const Text('Nueva contraseña',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F1F1F))),
        const SizedBox(height: 8),
        Text('Elige una contraseña segura de al menos 6 caracteres.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 28),
        _buildField(
          controller: _nuevaController,
          label: 'Nueva contraseña',
          icon: Icons.lock_outline,
          obscure: !_mostrarNueva,
          suffix: IconButton(
            icon: Icon(_mostrarNueva ? Icons.visibility : Icons.visibility_off, color: _naranja, size: 20),
            onPressed: () => setState(() => _mostrarNueva = !_mostrarNueva),
          ),
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _confirmarController,
          label: 'Confirmar contraseña',
          icon: Icons.lock_outline,
          obscure: !_mostrarConfirmar,
          suffix: IconButton(
            icon: Icon(_mostrarConfirmar ? Icons.visibility : Icons.visibility_off, color: _naranja, size: 20),
            onPressed: () => setState(() => _mostrarConfirmar = !_mostrarConfirmar),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _restablecerContrasena,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.check_circle_outline),
            label: Text(_isLoading ? 'Guardando...' : 'Guardar contraseña',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _naranja, size: 20),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide(color: _naranja, width: 2)),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      );
}