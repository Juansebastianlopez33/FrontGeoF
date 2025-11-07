import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/finca_service.dart';
import '../home/theme/dark_theme.dart';

class FincaEditScreen extends StatefulWidget {
  final int idFinca;

  const FincaEditScreen({super.key, required this.idFinca});

  @override
  State<FincaEditScreen> createState() => _FincaEditScreenState();
}

class _FincaEditScreenState extends State<FincaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final FincaService _fincaService = FincaService();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _abreviaturaController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  File? _imagen;
  bool _isLoading = false;
  bool _isActive = true;
  Map<String, dynamic>? _fincaData;

  @override
  void initState() {
    super.initState();
    _cargarFinca();
  }

  Future<void> _cargarFinca() async {
    setState(() => _isLoading = true);
    final result = await _fincaService.getFincaDetails(widget.idFinca);
    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _fincaData = data;
        _nombreController.text = data['nombreFinca'] ?? '';
        _codigoController.text = data['codigoFinca'] ?? '';
        _abreviaturaController.text = data['abreviaturaFinca'] ?? '';
        _direccionController.text = data['direccionFinca'] ?? '';
        _isActive = data['is_active'] ?? true;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagen = File(pickedFile.path);
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      "nombreFinca": _nombreController.text.trim(),
      "codigoFinca": _codigoController.text.trim(),
      "abreviaturaFinca": _abreviaturaController.text.trim(),
      "direccionFinca": _direccionController.text.trim(),
      "is_active": _isActive.toString(), // <-- cambio mínimo para evitar error
    };

    final result = await _fincaService.updateFinca(
      widget.idFinca,
      data,
      _imagen,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Finca actualizada correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      _cargarFinca();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Error al actualizar finca"),
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
        title: const Text("Detalles / Editar Finca"),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _fincaData == null
              ? const Center(
                  child: Text(
                    "Error al cargar los datos de la finca.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ==============================
                        // Imagen
                        // ==============================
                        Center(
                          child: GestureDetector(
                            onTap: _seleccionarImagen,
                            child: _imagen != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _imagen!,
                                      height: 180,
                                      width: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _fincaData?['url_imagen'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _fincaData!['url_imagen'],
                                          height: 180,
                                          width: 180,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        height: 180,
                                        width: 180,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white54),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.image,
                                            color: Colors.white54, size: 60),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ==============================
                        // Estado finca
                        // ==============================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isActive ? Icons.check_circle : Icons.cancel,
                              color: _isActive
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isActive ? "HABILITADA" : "INHABILITADA",
                              style: TextStyle(
                                color: _isActive
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Switch(
                              value: _isActive,
                              activeColor: Colors.greenAccent,
                              inactiveThumbColor: Colors.redAccent,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ==============================
                        // Campos Editables
                        // ==============================
                        _campo("Nombre de la finca", _nombreController),
                        _campo("Código de la finca", _codigoController),
                        _campo("Abreviatura", _abreviaturaController),
                        _campo("Dirección", _direccionController,
                            isRequired: false),
                        const SizedBox(height: 20),

                        // ==============================
                        // Estructura descendiente
                        // ==============================
                        if (_fincaData?['estructura_descendiente'] != null)
                          _estructuraInfo(_fincaData!['estructura_descendiente']),
                        const SizedBox(height: 30),

                        // ==============================
                        // Botón Guardar
                        // ==============================
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _guardarCambios,
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: const Text("Guardar Cambios",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _campo(String label, TextEditingController controller,
      {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label),
        validator: (value) =>
            isRequired && value!.isEmpty ? "Campo requerido" : null,
      ),
    );
  }

  Widget _estructuraInfo(Map<String, dynamic> estructura) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Estructura Descendiente",
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text("Áreas: ${estructura['total_areas'] ?? 0}",
              style: const TextStyle(color: Colors.white70)),
          Text("Bloques: ${estructura['total_bloques'] ?? 0}",
              style: const TextStyle(color: Colors.white70)),
          Text("Naves: ${estructura['total_naves'] ?? 0}",
              style: const TextStyle(color: Colors.white70)),
          Text("Camas: ${estructura['total_camas'] ?? 0}",
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.greenAccent),
      ),
    );
  }
}
