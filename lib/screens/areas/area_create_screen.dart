// lib/screens/area/area_create_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para TextInputFormatter
import '../../services/area_service.dart'; // Asegúrate de la ruta correcta
// O la ruta a tu tema

class AreaCreateScreen extends StatefulWidget {
  const AreaCreateScreen({super.key});

  @override
  State<AreaCreateScreen> createState() => _AreaCreateScreenState();
}

class _AreaCreateScreenState extends State<AreaCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final AreaService _areaService = AreaService();

  // Controladores de Texto
  // ❌ ELIMINADO: final TextEditingController _nombreAreaController = TextEditingController();
  final TextEditingController _numeroAreaController = TextEditingController();
  
  // *** NUEVOS CONTROLADORES Y ESTADOS PARA JEFE DE ÁREA ***
  final TextEditingController _searchController = TextEditingController(); // Controlador para la barra de búsqueda
  List<dynamic> _jefesArea = []; // Lista de resultados de la última búsqueda
  String _lastSearchQuery = ''; // Almacena la última query exitosa para evitar repetir
  // *******************************************************
  
  // Datos para Dropdowns
  List<dynamic> _fincas = [];
  String? _fincaSeleccionadaId; // Usará el idFinca

  // Datos para Jefe de Área (Seleccionado)
  String? _jefeAreaSeleccionadoCedula; // Usará la cédula del jefe para la API

  bool _isLoading = false;
  bool _isDropdownLoading = false; // Se usará para el indicador de carga de la búsqueda

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
    
    // ❌ ELIMINADO: Listener para convertir el Nombre del Área a mayúsculas
    // _nombreAreaController.addListener(_updateNombreAreaUpperCase);
  }

  // ==========================================================
  // 🎯 HELPERS (ELIMINADOS o MODIFICADOS)
  // ==========================================================
  
  // ❌ ELIMINADO: Función _displayStringForOption ya no es necesaria.

  // ❌ ELIMINADO: _updateNombreAreaUpperCase
  /*
  void _updateNombreAreaUpperCase() {
    final text = _nombreAreaController.text;
    if (text.isNotEmpty && text != text.toUpperCase()) {
      _nombreAreaController.value = _nombreAreaController.value.copyWith(
        text: text.toUpperCase(),
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }
  */

  @override
  void dispose() {
    // ❌ ELIMINADO: _nombreAreaController.removeListener y dispose
    // _nombreAreaController.removeListener(_updateNombreAreaUpperCase);
    // _nombreAreaController.dispose();
    _numeroAreaController.dispose();
    // *** NUEVOS DISPOSES ***
    _searchController.dispose();
    // ***********************
    super.dispose();
  }

  // ==========================================================
  // ⚙️ Cargar Fincas
  // ==========================================================
  Future<void> _cargarDatosIniciales() async {
    setState(() => _isDropdownLoading = true);
    
    try {
      final fincas = await _areaService.getAllFincas();
      
      if (mounted) {
        setState(() {
          _fincas = fincas;
          _isDropdownLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar("Error al cargar fincas: $e", isError: true);
        setState(() => _isDropdownLoading = false);
      }
    }
  }

  // ==========================================================
  // 🔍 BUSCAR JEFES DE ÁREA (NUEVA FUNCIÓN)
  // ==========================================================
  Future<void> _searchJefesArea() async {
    final query = _searchController.text.trim();

    // 1. Requisito: Validar Query No Vacía
    if (query.isEmpty) {
      _mostrarSnackBar("Debe ingresar un nombre o cédula para buscar.", isError: true);
      return;
    }
    
    // 2. Requisito: Validar Query No Repetida
    if (query == _lastSearchQuery) {
      _mostrarSnackBar("Ya buscó este valor. Modifique la búsqueda para obtener nuevos resultados.", isError: true);
      return;
    }

    setState(() {
      _isDropdownLoading = true;
      _jefesArea = []; // Limpiamos la lista anterior
      _jefeAreaSeleccionadoCedula = null; // Deseleccionamos el jefe anterior
    });

    try {
      // Usamos el mismo servicio de búsqueda
      final results = await _areaService.searchJefesArea(query);

      if (mounted) {
        setState(() {
          _jefesArea = results;
          _lastSearchQuery = query; // Guardamos la query exitosa
          _isDropdownLoading = false;

          if (results.isEmpty) {
            _mostrarSnackBar("No se encontraron Jefes de Área para '$query'.", isError: false);
          } else {
            _mostrarSnackBar("Se encontraron ${results.length} Jefes de Área. Seleccione uno.", isError: false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar("Error al buscar Jefes de Área: $e", isError: true);
        setState(() => _isDropdownLoading = false);
      }
    }
  }


  // ==========================================================
  // 💾 Crear Área
  // ==========================================================
  Future<void> _crearArea() async {
    // ❌ ELIMINADO: Asegurar mayúsculas
    // _nombreAreaController.text = _nombreAreaController.text.toUpperCase();

    if (!_formKey.currentState!.validate()) return;
    
    // Validar Dropdown y Jefe de Área
    if (_fincaSeleccionadaId == null) {
      _mostrarSnackBar("Debe seleccionar una Finca.", isError: true);
      return;
    }
    // VALIDACIÓN ACTUALIZADA: Asegura que se haya seleccionado un jefe (el valor de la cédula)
    if (_jefeAreaSeleccionadoCedula == null) {
      _mostrarSnackBar("Debe buscar y seleccionar un Jefe de Área de la lista de resultados.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final numeroAreaText = _numeroAreaController.text.trim();
    
    // 🎯 AJUSTE CRUCIAL: Generar un nombre de área basado en el número para cumplir la validación del backend.
    final String nombreAreaGenerado = numeroAreaText.isNotEmpty 
        ? "ÁREA ${numeroAreaText} - FINCA ${_fincaSeleccionadaId}"
        : "ÁREA SIN NÚMERO - FINCA ${_fincaSeleccionadaId} - TEMP";

    final areaData = {
      // 🎯 AJUSTE: Usar el nombre generado para cumplir con la validación de campo obligatorio del backend.
      'nombreArea': nombreAreaGenerado, 
      // 🎯 AJUSTE: Si es String vacío, se envía null
      'numeroArea': numeroAreaText.isNotEmpty 
          ? numeroAreaText 
          : null, 
      'idFinca': int.parse(_fincaSeleccionadaId!), // idFinca es int en el backend
      'jefeDeArea_id': _jefeAreaSeleccionadoCedula!, // cédula es String en el backend
    };

    try {
      final result = await _areaService.createArea(areaData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _mostrarSnackBar('✅ Área creada exitosamente: ${result['message']}');
        // Limpiar y volver a la pantalla anterior
        Navigator.pop(context, true); 
      } else {
        _mostrarSnackBar('🔴 Error al crear el área: ${result['message']}', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarSnackBar('🔴 Error de conexión: $e', isError: true);
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
    // Asumo que GeoFloraTheme.background y GeoFloraTheme.accent existen en tu archivo dark_theme.dart
    final themeBackground = const Color(0xFF1E1E1E); 
    final themeAccent = Colors.greenAccent;

    return Scaffold(
      backgroundColor: themeBackground,
      appBar: AppBar(
        title: const Text("Crear Área"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ❌ ELIMINADO: Campo Nombre del Área (Obligatorio, Máx 50) 
              // ❌ ELIMINADO: Se maneja de forma automática en _crearArea
              /*
              _buildTextField(
                  _nombreAreaController, 
                  "Nombre del Área (Máx 50 caracteres)", 
                  true, 
                  maxLength: 50,
                  keyboardType: TextInputType.text),
              const SizedBox(height: 15),
              */

              // --- Campo: Número de Área (Opcional, numérico, Máx 3 dígitos) ---
              _buildTextField(
                  _numeroAreaController, 
                  "Número de Área (Opcional, Máx 3 dígitos)", 
                  false, 
                  maxLength: 3, // Límite de 3 dígitos
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Solo permite dígitos
                  ]),
              const SizedBox(height: 25),

              // ======================================================
              // 🌿 Dropdown Finca
              // ======================================================
              _buildDropdownTitle("Seleccionar Finca"),
              _isDropdownLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                  : _buildDropdown(
                      value: _fincaSeleccionadaId,
                      hint: "Finca a la que pertenece el área",
                      items: _fincas.map<DropdownMenuItem<String>>((finca) {
                        final id = finca['idFinca']?.toString() ?? 'N/A';
                        final nombre = finca['nombreFinca'] ?? 'Sin nombre';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text("$nombre (ID: $id)", style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _fincaSeleccionadaId = value),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Seleccione una finca' : null,
                    ),
              const SizedBox(height: 25),
              
              // ======================================================
              // 👨‍🌾 Búsqueda y Dropdown Jefe de Área (NUEVO REEMPLAZO)
              // ======================================================
              _buildDropdownTitle("Buscar Jefe de Área por Nombre o Cédula"),
              _buildJefeAreaSearchAndDropdown(), // <-- REEMPLAZO DE _buildJefeAreaAutocomplete()
              const SizedBox(height: 30),

              // ======================================================
              // 💾 Botón Guardar
              // ======================================================
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                  : ElevatedButton.icon(
                      onPressed: _crearArea,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Guardar Área",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // 🧱 Búsqueda y Dropdown para Jefes de Área (NUEVO WIDGET)
  // ==========================================================

  Widget _buildJefeAreaSearchAndDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Campo de Búsqueda con Botón
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _searchController,
                decoration: _inputDecoration(
                  "Ingrese Nombre o Cédula a buscar",
                  suffixIcon: const Icon(Icons.person_search, color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            // Botón que ejecuta la búsqueda
            _isDropdownLoading
                ? Container(
                    height: 58, // Para alinear con el TextFormField
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _searchJefesArea, // Llama a la función con las validaciones
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      // Ajustar padding para alinear verticalmente con el TextFormField
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
          ],
        ),

        const SizedBox(height: 15),
        
        // 2. Dropdown de Selección
        _buildDropdownTitle("Resultados de la Búsqueda (${_jefesArea.length} encontrados)"),
        _buildDropdown(
          value: _jefeAreaSeleccionadoCedula,
          hint: _jefesArea.isEmpty 
              ? "Realice la búsqueda para seleccionar un jefe" 
              : "Seleccionar Jefe de Área",
          items: _jefesArea.map<DropdownMenuItem<String>>((jefe) {
            final cedula = jefe['cedula']?.toString() ?? 'N/A';
            final nombre = jefe['nombre'] ?? 'Sin nombre';
            return DropdownMenuItem<String>(
              value: cedula,
              child: Text("$nombre ($cedula)", style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (value) => setState(() => _jefeAreaSeleccionadoCedula = value),
          // Validamos si hay resultados y si se seleccionó uno
          validator: (value) {
            if (_lastSearchQuery.isNotEmpty && _jefesArea.isEmpty) {
              // Si se buscó algo pero no hubo resultados, el usuario no puede seleccionar
              return 'No hay resultados disponibles para seleccionar.';
            }
            if (_jefesArea.isNotEmpty && value == null) {
              // Si hay resultados pero no se seleccionó nada
              return 'Debe seleccionar un jefe de la lista de resultados.';
            }
            // Si _jefesArea está vacío porque no se ha buscado, la validación final se hace en _crearArea
            return null;
          }
        ),
      ],
    );
  }
  
  // *** El widget _buildJefeAreaAutocomplete() fue ELIMINADO ***
  
  // ==========================================================
  // 🧱 Helpers UI
  // ==========================================================
  Widget _buildTextField(TextEditingController controller, String label, bool required, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      // Aplicar limitación de longitud y filtros si se especifican
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ...?inputFormatters,
      ],
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Campo obligatorio';
        }
        if (keyboardType == TextInputType.number && value!.isNotEmpty && int.tryParse(value) == null) {
          return 'Debe ser un número entero válido';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return Container(
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
        icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        dropdownColor: Colors.black87,
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

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
        borderSide: const BorderSide(color: Colors.greenAccent),
      ),
      filled: true,
      fillColor: Colors.black26,
    );
  }
}