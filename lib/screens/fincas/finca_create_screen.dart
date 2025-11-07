import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/widgets.dart';
import '../../services/finca_service.dart';
import '../home/theme/dark_theme.dart';

class FincaCreateScreen extends StatefulWidget {
  const FincaCreateScreen({super.key});

  @override
  State<FincaCreateScreen> createState() => _FincaCreateScreenState();
}

class _FincaCreateScreenState extends State<FincaCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final FincaService _fincaService = FincaService();

  // Campos
  final TextEditingController _codigoFincaController = TextEditingController();
  final TextEditingController _abreviaturaController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _agronomoController = TextEditingController();

  File? _imagenSeleccionada;
  bool _isLoading = false;

  // ==========================================================
  // Seleccionar imagen
  // ==========================================================
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagenSeleccionada = File(picked.path));
    }
  }

  // ==========================================================
  // Enviar finca al backend
  // ==========================================================
  Future<void> _crearFinca() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final fincaData = {
      'codigoFinca': _codigoFincaController.text.trim(),
      'abreviaturaFinca': _abreviaturaController.text.trim(),
      'nombreFinca': _nombreController.text.trim(),
      'direccionFinca': _direccionController.text.trim(),
      'agronomoEncargado_id': _agronomoController.text.trim(),
    };

    final result = await _fincaService.createFinca(fincaData, _imagenSeleccionada);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Finca creada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState!.reset();
      setState(() => _imagenSeleccionada = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${result['message'] ?? 'No se pudo crear la finca.'}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Crear Finca"),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "🧾 Información de la Finca",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),

              // Código Finca
              TextFormField(
                controller: _codigoFincaController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Código de Finca"),
                validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),

              // Abreviatura
              TextFormField(
                controller: _abreviaturaController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Abreviatura"),
                validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),

              // Nombre
              TextFormField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Nombre de la Finca"),
                validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),

              // Dirección
              TextFormField(
                controller: _direccionController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Dirección"),
                validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 12),

              // Agrónomo encargado
              TextFormField(
                controller: _agronomoController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Cédula del Agrónomo Encargado"),
                validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 20),

              // Imagen
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                    ),
                    onPressed: _seleccionarImagen,
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text(
                      "Seleccionar Imagen",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_imagenSeleccionada != null)
                    Text(
                      "✅ Imagen seleccionada",
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              // Botón guardar
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : ElevatedButton.icon(
                        onPressed: _crearFinca,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Guardar Finca",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.greenAccent),
      ),
      filled: true,
      fillColor: Colors.black26,
    );
  }
}
