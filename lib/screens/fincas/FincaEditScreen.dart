import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../home/theme/dark_theme.dart';
import '../../services/finca_service.dart';

class FincaEditScreen extends StatefulWidget {
  final int idFinca;

  const FincaEditScreen({super.key, required this.idFinca});

  @override
  State<FincaEditScreen> createState() => _FincaEditScreenState();
}

class _FincaEditScreenState extends State<FincaEditScreen> {
  final FincaService _fincaService = FincaService();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _abreviaturaController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  File? _imagen;
  bool isLoading = true;
  bool _isActive = true;
  Map<String, dynamic>? finca;

  int? _selectedAgronomoId;

  @override
  void initState() {
    super.initState();
    _loadFincaDetails();
  }

  Future<void> _loadFincaDetails() async {
    final result = await _fincaService.getFincaDetails(widget.idFinca);
    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          finca = result['data'];
          _nombreController.text = finca!['nombreFinca'] ?? '';
          _codigoController.text = finca!['codigoFinca'] ?? '';
          _abreviaturaController.text = finca!['abreviaturaFinca'] ?? '';
          _direccionController.text = finca!['direccionFinca'] ?? '';
          _isActive = finca!['is_active'] ?? true;
          _selectedAgronomoId = finca!['agronomoEncargado_id'];
        }
        isLoading = false;
      });
    }
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imagen = File(pickedFile.path));
    }
  }

  Future<void> _saveChanges() async {
    setState(() => isLoading = true);

    final data = {
      "nombreFinca": _nombreController.text.trim(),
      "codigoFinca": _codigoController.text.trim(),
      "abreviaturaFinca": _abreviaturaController.text.trim(),
      "direccionFinca": _direccionController.text.trim(),
      "is_active": _isActive.toString(),
      "agronomoEncargado_id": _selectedAgronomoId.toString(),
    };

    final result = await _fincaService.updateFinca(
      widget.idFinca,
      data,
      _imagen,
    );

    setState(() => isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Finca actualizada correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      _loadFincaDetails(); // recargar datos
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
        title: const Text("Editar Finca"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : finca == null
              ? const Center(
                  child: Text(
                    "No se pudieron cargar los detalles de la finca.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Imagen editable
                      GestureDetector(
                        onTap: _selectImage,
                        child: _imagen != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _imagen!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : finca!['url_imagen'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      finca!['url_imagen'],
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported,
                                              color: Colors.white38, size: 100),
                                    ),
                                  )
                                : const Icon(Icons.image_outlined,
                                    color: Colors.white38, size: 100),
                      ),
                      const SizedBox(height: 20),

                      // Campos editables
                      _buildTextField("Nombre", _nombreController),
                      _buildTextField("Código", _codigoController),
                      _buildTextField("Abreviatura", _abreviaturaController),
                      _buildTextField("Dirección", _direccionController),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            "Activo:",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: _isActive,
                            onChanged: (val) => setState(() => _isActive = val),
                            activeColor: Colors.greenAccent,
                            inactiveThumbColor: Colors.redAccent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Agrónomo encargado (dropdown)
                      Row(
                        children: [
                          const Text(
                            "Agrónomo Encargado:",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _selectedAgronomoId,
                              dropdownColor: Colors.black87,
                              style: const TextStyle(color: Colors.white),
                              isExpanded: true,
                              items: [
                                // Aquí puedes cargar la lista real de agrónomos desde el servicio
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text("Agrónomo 1"),
                                ),
                                DropdownMenuItem(
                                  value: 2,
                                  child: Text("Agrónomo 2"),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedAgronomoId = val),
                            ),
                          )
                        ],
                      ),

                      const Divider(color: Colors.white24, height: 40),

                      // Estructura descendiente (solo info)
                      Text(
                        "Estructura de la Finca",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GeoFloraTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow("Áreas",
                          "${finca!['estructura_descendiente']['total_areas']}"),
                      _buildInfoRow("Bloques",
                          "${finca!['estructura_descendiente']['total_bloques']}"),
                      _buildInfoRow("Naves",
                          "${finca!['estructura_descendiente']['total_naves']}"),
                      _buildInfoRow("Camas",
                          "${finca!['estructura_descendiente']['total_camas']}"),

                      const SizedBox(height: 30),

                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text("Guardar Cambios"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
