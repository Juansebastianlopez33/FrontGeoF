import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Controladores
  final TextEditingController _codigoFincaController = TextEditingController();
  final TextEditingController _abreviaturaController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  File? _imagenSeleccionada;
  bool _isLoading = false;

  // ==========================================================
  // 👨‍🌾 Agrónomos
  // ==========================================================
  List<dynamic> _agronomos = [];
  String? _agronomoSeleccionado;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _cargarAgronomos();
  }

  Future<void> _cargarAgronomos() async {
    setState(() => _isSearching = true);
    final agronomos = await _fincaService.getAllAgronomos();
    setState(() {
      _agronomos = agronomos;
      _isSearching = false;
    });
  }

  Future<void> _buscarAgronomo(String query) async {
    if (query.isEmpty) {
      await _cargarAgronomos();
      return;
    }

    setState(() => _isSearching = true);
    final result = await _fincaService.searchAgronomo(nombre: query, cedula: query);
    setState(() {
      if (result['success']) {
        final data = result['data'];
        // Si es un solo objeto, lo envolvemos en lista
        if (data is Map && data.containsKey('cedula')) {
          _agronomos = [data];
        } else if (data is Map && data.containsKey('resultados')) {
          _agronomos = List.from(data['resultados']);
        } else {
          _agronomos = [];
        }
      } else {
        _agronomos = [];
      }
      _isSearching = false;
    });
  }

  // ==========================================================
  // 📸 Seleccionar imagen
  // ==========================================================
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imagenSeleccionada = File(picked.path));
      print('DEBUG: Imagen seleccionada. Path: ${picked.path}');
    }
  }

  // ==========================================================
  // 💾 Crear Finca
  // ==========================================================
  Future<void> _crearFinca() async {
    if (!_formKey.currentState!.validate()) return;
    if (_agronomoSeleccionado == null || _agronomoSeleccionado!.isEmpty) {
      _mostrarSnackBar("Debe seleccionar un agrónomo.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final fincaData = {
      'codigoFinca': _codigoFincaController.text,
      'abreviaturaFinca': _abreviaturaController.text,
      'nombreFinca': _nombreController.text,
      'direccionFinca': _direccionController.text,
      'agronomoEncargado_id': _agronomoSeleccionado ?? '',
    };

    print('DEBUG: Datos a enviar: $fincaData');

    final result = await _fincaService.createFinca(fincaData, _imagenSeleccionada);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _mostrarSnackBar('✅ Finca creada exitosamente.');
      Navigator.pop(context);
    } else {
      _mostrarSnackBar('🔴 Error al crear la finca: ${result['message']}', isError: true);
    }
  }

  // ==========================================================
  // 🔔 SnackBar Helper
  // ==========================================================
  void _mostrarSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ==========================================================
  // 🧱 Build
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Crear Finca"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_codigoFincaController, "Código Finca", true),
              const SizedBox(height: 15),
              _buildTextField(_abreviaturaController, "Abreviatura", true),
              const SizedBox(height: 15),
              _buildTextField(_nombreController, "Nombre Finca", true),
              const SizedBox(height: 15),
              _buildTextField(_direccionController, "Dirección", true),
              const SizedBox(height: 25),

              // ======================================================
              // 👨‍🌾 Dropdown con búsqueda de agrónomos
              // ======================================================
              Text(
                "Seleccionar Agrónomo Encargado",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Buscar por nombre o cédula"),
                onChanged: (query) {
                  _searchQuery = query;
                  _buscarAgronomo(query);
                },
              ),
              const SizedBox(height: 10),

              _isSearching
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.greenAccent),
                    )
                  : DropdownButtonFormField<String>(
                      value: _agronomoSeleccionado,
                      dropdownColor: Colors.black87,
                      items: _agronomos.map<DropdownMenuItem<String>>((a) {
                        final nombre = a['nombre'] ?? 'Sin nombre';
                        final cedula = a['cedula'] ?? 'N/A';
                        return DropdownMenuItem<String>(
                          value: cedula,
                          child: Text(
                            "$nombre ($cedula)",
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _agronomoSeleccionado = value),
                      decoration: _inputDecoration("Agrónomo"),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Seleccione un agrónomo' : null,
                    ),
              const SizedBox(height: 30),

              // ======================================================
              // 📷 Selector de imagen
              // ======================================================
              GestureDetector(
                onTap: _seleccionarImagen,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imagenSeleccionada != null
                          ? Colors.greenAccent
                          : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(_imagenSeleccionada!.path, fit: BoxFit.cover)
                              : Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.white70),
                              SizedBox(height: 8),
                              Text("Seleccionar Imagen de la Finca",
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // ======================================================
              // 💾 Botón Guardar
              // ======================================================
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.greenAccent))
                  : ElevatedButton.icon(
                      onPressed: _crearFinca,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
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
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🧱 Helpers UI
  // ==========================================================
  Widget _buildTextField(TextEditingController controller, String label, bool required) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Campo obligatorio';
        }
        return null;
      },
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
