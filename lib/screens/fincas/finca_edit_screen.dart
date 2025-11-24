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
    // Se elimina _cargarAgronomos()
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _abreviaturaController.dispose();
    _direccionController.dispose();
    // Se elimina _searchController.dispose()
    super.dispose();
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
        _isActive = data['is_active'] == true;
        // Se elimina la carga de _agronomoSeleccionado
      });
    }
    setState(() => _isLoading = false);
  }

  // Se eliminan _cargarAgronomos, _searchAgronomosExplicitly y _clearAgronomoSearch

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imagen = File(pickedFile.path));
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    // Se elimina la validación del agrónomo

    final data = {
      "nombreFinca": _nombreController.text.trim(),
      "codigoFinca": _codigoController.text.trim(),
      "abreviaturaFinca": _abreviaturaController.text.trim(),
      "direccionFinca": _direccionController.text.trim(),
      "is_active": _isActive.toString(),
      // Se elimina "agronomoEncargado_id"
    };

    final result = await _fincaService.updateFinca(widget.idFinca, data, _imagen);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // ✅ Éxito: Muestra SnackBar y redirige
      _mostrarSnackBar("✅ Finca actualizada correctamente"); 
      _cargarFinca();
      
      // Redirige a la página anterior después de la actualización exitosa
      if (mounted) {
          Navigator.pop(context); 
      }
    } else {
      // 🛑 Error: Usa el helper para mostrar el mensaje de error del backend
      _mostrarSnackBar(
          result['message'] ?? "Error al actualizar finca. Verifique los datos.", 
          isError: true
      );
    }
  }

  Future<void> _cambiarEstadoFinca(bool nuevoEstado) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final result = await _fincaService.toggleFincaStatus(widget.idFinca, nuevoEstado);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() => _isActive = nuevoEstado);
      _mostrarSnackBar("✅ Finca ${nuevoEstado ? 'Habilitada' : 'Inhabilitada'} correctamente");
    } else {
      setState(() => _isActive = !nuevoEstado);
      _mostrarSnackBar(
          result['message'] ?? "Error al cambiar el estado",
          isError: true
      );
    }
  }
  
  // 🔔 SnackBar Helper
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
  // UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Detalles / Editar Finca"),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
      body: _isLoading && _fincaData == null 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _fincaData == null
               ? const Center(
                   child: Text("Error al cargar los datos de la finca.",
                       style: TextStyle(color: Colors.white70)),
                 )
               : SingleChildScrollView(
                   padding: const EdgeInsets.all(16),
                   child: Form(
                     key: _formKey,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         Center(
                           child: GestureDetector(
                             onTap: _seleccionarImagen,
                             child: _imagen != null
                                 ? ClipRRect(
                                       borderRadius: BorderRadius.circular(12),
                                       child: Image.file(_imagen!,
                                           height: 180, width: 180, fit: BoxFit.cover),
                                     )
                                 : _fincaData?['url_imagen'] != null
                                     ? ClipRRect(
                                           borderRadius: BorderRadius.circular(12),
                                           child: Image.network(
                                             _fincaService.getImageUrl(
                                                 _fincaData!['url_imagen']),
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

                         // Estado finca
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
                               onChanged: (val) async {
                                 if (!_isLoading) {
                                   // El estado se actualiza en _cambiarEstadoFinca si la llamada API es exitosa
                                   await _cambiarEstadoFinca(val);
                                 }
                               },
                             ),
                           ],
                         ),
                         const SizedBox(height: 20),

                         _campo("Nombre de la finca", _nombreController),
                         _campo("Código de la finca", _codigoController),
                         _campo("Abreviatura", _abreviaturaController),
                         _campo("Dirección", _direccionController,
                             isRequired: false),

                         // Se elimina el widget _buildAgronomoSearchAndDropdown
                         const SizedBox(height: 30),

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

// Se elimina el widget _buildAgronomoSearchAndDropdown y toda su lógica.

// ==========================================================
// 🧱 Helpers UI
// ==========================================================
Widget _campo(String label, TextEditingController controller,
    {bool isRequired = true}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      validator: (value) =>
          isRequired && (value == null || value.isEmpty)
              ? "Campo requerido"
              : null,
    ),
  );
}

InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    suffixIcon: suffixIcon,
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