import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RegistrarObjetoScreen extends StatefulWidget {
  const RegistrarObjetoScreen({Key? key}) : super(key: key);

  @override
  State<RegistrarObjetoScreen> createState() => _RegistrarObjetoScreenState();
}

class _RegistrarObjetoScreenState extends State<RegistrarObjetoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  int? _categoriaSeleccionada;
  bool _isLoading = false;
  
  static const Color _naranjaVivo = Color(0xFFFF6B00);
  static const Color _naranjaNaranja = Color(0xFFFF8C00);
  static const Color _blanco = Color(0xFFFAFAFA);

  final List<Map<String, dynamic>> categorias = [
    {'id': 1, 'nombre': 'Laptop'},
    {'id': 2, 'nombre': 'Tablet'},
    {'id': 3, 'nombre': 'Celular'},
    {'id': 4, 'nombre': 'Otro'},
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _registrarObjeto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await ApiService().registrarObjeto(
        _nombreController.text.trim(),
        _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blanco,
      appBar: AppBar(
        title: const Text('Registrar Objeto'),
        backgroundColor: _naranjaVivo,
        elevation: 8,
        shadowColor: _naranjaVivo.withOpacity(0.4),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  'Registra tu objeto',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _naranjaVivo,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se generará un código QR único para tu objeto',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 28),

                // Campo: Nombre del objeto
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del objeto',
                    hintText: 'ej: Mi laptop HP',
                    prefixIcon: const Icon(Icons.backpack_outlined, color: _naranjaVivo),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre del objeto';
                    }
                    if (value.trim().length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Campo: Categoría
                DropdownButtonFormField<int>(
                  value: _categoriaSeleccionada,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(Icons.category_outlined, color: _naranjaVivo),
                  ),
                  items: categorias.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat['id'],
                      child: Text(cat['nombre']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaSeleccionada = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecciona una categoría';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Campo: Descripción
                TextFormField(
                  controller: _descripcionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'ej: Laptop plateada con marca XYZ',
                    prefixIcon: const Icon(Icons.description_outlined, color: _naranjaVivo),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Botón: Registrar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registrarObjeto,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            'Registrar Objeto',
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
      ),
    );
  }
}
