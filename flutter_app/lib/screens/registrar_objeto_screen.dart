import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RegistrarObjetoScreen extends StatefulWidget {
  const RegistrarObjetoScreen({Key? key}) : super(key: key);

  @override
  State<RegistrarObjetoScreen> createState() => _RegistrarObjetoScreenState();
}

class _RegistrarObjetoScreenState extends State<RegistrarObjetoScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _nombreController     = TextEditingController();
  final _descripcionController = TextEditingController();
  int? _categoriaSeleccionada;
  bool _isLoading          = false;
  List<Map<String, dynamic>> _categorias = [];
  bool _cargandoCategorias = true;

  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _blanco      = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final result = await ApiService().obtenerCategorias();
    if (mounted) {
      setState(() {
        if (result['success']) {
          _categorias = List<Map<String, dynamic>>.from(result['data']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Error al cargar categorías'),
              backgroundColor: Colors.red.shade500,
            ),
          );
        }
        _cargandoCategorias = false;
      });
    }
  }

  Future<void> _registrarObjeto() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final resultado = await ApiService().registrarObjeto(
        _nombreController.text.trim(),
        _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
        _categoriaSeleccionada,
      );
      if (mounted) {
        if (resultado['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Objeto registrado exitosamente'),
              backgroundColor: Colors.green.shade500,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado['error'] ?? 'Error al registrar objeto'),
              backgroundColor: Colors.red.shade500,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade500,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _blanco,
      // ✅ true — Flutter sube el contenido cuando aparece el teclado
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Registrar Objeto'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding + 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _naranjaVivo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_box_outlined, color: _naranjaVivo, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registra tu objeto',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF1F1F1F),
                              ),
                        ),
                        Text(
                          'Se generará un QR único',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Card formulario
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, spreadRadius: 2),
                  ],
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATOS DEL OBJETO',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _naranjaVivo,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del objeto',
                        hintText: 'ej: Mi laptop HP',
                        prefixIcon: Icon(Icons.backpack_outlined, color: _naranjaVivo),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Ingresa el nombre del objeto';
                        if (value.trim().length < 2) return 'El nombre debe tener al menos 2 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Categoría
                    _cargandoCategorias
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(_naranjaVivo),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : DropdownButtonFormField<int>(
                            value: _categoriaSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: Icon(Icons.category_outlined, color: _naranjaVivo),
                            ),
                            items: _categorias.map((cat) => DropdownMenuItem<int>(
                              value: cat['id'] as int,
                              child: Text(cat['nombre'] as String),
                            )).toList(),
                            onChanged: (value) => setState(() => _categoriaSeleccionada = value),
                            validator: (value) {
                              if (value == null) return 'Selecciona una categoría';
                              return null;
                            },
                          ),
                    const SizedBox(height: 18),

                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'ej: Laptop plateada con marca XYZ',
                        prefixIcon: Icon(Icons.description_outlined, color: _naranjaVivo),
                        alignLabelWithHint: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _cargandoCategorias) ? null : _registrarObjeto,
                  icon: _isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ))
                      : const Icon(Icons.qr_code_2),
                  label: Text(
                    _isLoading ? 'Registrando...' : 'Registrar Objeto',
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
      ),
    );
  }
}