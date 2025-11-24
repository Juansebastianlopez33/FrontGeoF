// lib/screens/bloque/bloque_create_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import '../../services/bloques_service.dart'; // Block Service
import '../home/theme/dark_theme.dart'; // Theme constants

// Custom Formatter to convert input to uppercase
class _UppercaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class BloqueCreateScreen extends StatefulWidget {
  final int? idAreaInicial; 

  const BloqueCreateScreen({
    super.key,
    this.idAreaInicial, 
  });

  @override
  State<BloqueCreateScreen> createState() => _BloqueCreateScreenState();
}

class _BloqueCreateScreenState extends State<BloqueCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final BloquesService _bloqueService = BloquesService();
  
  // Text Controller for required field
  final TextEditingController _numeroBloqueController = TextEditingController();
  
  // Dropdown data
  List<dynamic> _areas = [];
  String? _areaSeleccionadaId; // Will store idArea (as String for dropdown)
  bool _isLoadingAreas = false;
  
  bool _isSaving = false;
  String? _errorMessage;

  // Style Constants
  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;
  
  @override
  void initState() {
    super.initState();
    // Preseleccionar el ID del área si viene de la pantalla anterior
    if (widget.idAreaInicial != null) {
      _areaSeleccionadaId = widget.idAreaInicial!.toString();
    }
    _cargarAreas();
  }

  @override
  void dispose() {
    _numeroBloqueController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD AREAS FOR DROPDOWN
  // ==========================================================
  Future<void> _cargarAreas() async {
    setState(() {
      _isLoadingAreas = true;
    });

    final areasList = await _bloqueService.getAllAreas();

    if (mounted) {
      setState(() {
        _areas = areasList;
        
        if (_areas.isNotEmpty) {
          if (_areaSeleccionadaId != null) {
            final exists = _areas.any((a) => a['idArea']?.toString() == _areaSeleccionadaId);
            if (!exists) {
              _areaSeleccionadaId = _areas.first['idArea']?.toString();
            }
          } 
          else {
            _areaSeleccionadaId = _areas.first['idArea']?.toString();
          }
        } else {
          _areaSeleccionadaId = null;
        }
        
        _isLoadingAreas = false;
      });
    }
  }

  // ==========================================================
  // SUBMIT FORM (Solo con numeroBloque)
  // ==========================================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_areaSeleccionadaId == null) {
      setState(() {
        _errorMessage = "Debe seleccionar un Área padre.";
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final data = {
      'numeroBloque': _numeroBloqueController.text.trim(),
      // Ensure idArea is sent as an integer
      'idArea': int.tryParse(_areaSeleccionadaId!), 
      'is_active': true, // Default to active
    };

    final result = await _bloqueService.createBloque(data);

    if (!mounted) return;

    if (result['success'] == true) {
      // Show success message and close screen
      Navigator.pop(context, true); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloque registrado con éxito!')),
      );
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage = result['message'];
      });
    }
  }
  
  // ==========================================================
  // REUSABLE WIDGETS (Validator para el límite de 4 caracteres)
  // ==========================================================

  // Standard text input field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    List<TextInputFormatter>? formatters,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        decoration: _inputDecoration(label),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio.';
          }
          // Validación manual para el límite de caracteres (si se aplica)
          if (formatters?.any((f) => f is LengthLimitingTextInputFormatter && f.maxLength == 4) == true) {
              if (value.length > 4) {
                return 'Máximo 4 caracteres permitidos.';
              }
          }
          return null;
        },
      ),
    );
  }

  // Dropdown input field for selecting parent Area
  Widget _buildDropdownField({
    required String hint,
    required String? value,
    required List<dynamic> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            contentPadding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
            border: InputBorder.none,
          ),
          icon: Icon(Icons.arrow_drop_down, color: _themeAccent),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          dropdownColor: Colors.black87,
          items: items.map<DropdownMenuItem<String>>((area) {
            // Use idArea as the value and a descriptive string as the display
            final id = area['idArea']?.toString() ?? '';
            final numero = area['numeroArea']?.toString() ?? 'N/A';
            return DropdownMenuItem<String>(
              value: id,
              child: Text('Área N° $numero'),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (val) {
            if (val == null) return 'Selección de Área es obligatoria.';
            return null;
          },
        ),
      ),
    );
  }

  // Common InputDecoration styling
  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _themeAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        title: const Text('Registrar Nuevo Bloque'),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Area Dropdown Field
              Text(
                'Área Padre (Requerido)',
                style: TextStyle(color: _themeAccent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _isLoadingAreas
                  ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                  : _areas.isEmpty
                    ? const Text('No hay áreas disponibles para seleccionar.', style: TextStyle(color: Colors.redAccent))
                    : _buildDropdownField(
                          hint: 'Seleccione el Área a la que pertenece',
                          value: _areaSeleccionadaId,
                          items: _areas,
                          onChanged: (newValue) {
                            setState(() {
                              _areaSeleccionadaId = newValue;
                            });
                          },
                        ),
              
              const Divider(color: Colors.white12, height: 30),

              // Block Number Field (Uppercase and Max 4 chars)
              _buildTextField(
                controller: _numeroBloqueController,
                label: 'Número de Bloque (Máx. 4 caracteres, Solo Mayúsculas)',
                keyboardType: TextInputType.text,
                formatters: [
                  _UppercaseTextFormatter(),
                  LengthLimitingTextInputFormatter(4), // LÍMITE DE 4 CARACTERES
                ],
              ),

              // Error Message Display
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitForm,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Guardando...' : 'Registrar Bloque', style: const TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}