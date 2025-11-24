import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  
  // *** NUEVOS CONTROLADORES Y ESTADOS PARA BÚSQUEDA EXPLÍCITA ***
  final TextEditingController _searchController = TextEditingController(); // Controlador para la barra de búsqueda
  String _lastSearchQuery = ''; // Almacena la última query exitosa
  // *************************************************************

  File? _imagenSeleccionada;
  bool _isLoading = false;

  // ==========================================================
  // 👨‍🌾 Agrónomos
  // ==========================================================
  List<dynamic> _agronomos = [];
  String? _agronomoSeleccionado;
  // String _searchQuery = ''; // Eliminada, reemplazada por _searchController
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _cargarAgronomos();
    
    // Listeners para mayúsculas
    _abreviaturaController.addListener(_updateAbreviaturaUpperCase);
    _nombreController.addListener(_updateNombreUpperCase);
    _direccionController.addListener(_updateDireccionUpperCase);
  }

  void _updateAbreviaturaUpperCase() {
    final text = _abreviaturaController.text;
    if (text.isNotEmpty && text != text.toUpperCase()) {
      _abreviaturaController.value = _abreviaturaController.value.copyWith(
        text: text.toUpperCase(),
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }
  void _updateNombreUpperCase() {
    final text = _nombreController.text;
    if (text.isNotEmpty && text != text.toUpperCase()) {
      _nombreController.value = _nombreController.value.copyWith(
        text: text.toUpperCase(),
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }
  void _updateDireccionUpperCase() {
    final text = _direccionController.text;
    if (text.isNotEmpty && text != text.toUpperCase()) {
      _direccionController.value = _direccionController.value.copyWith(
        text: text.toUpperCase(),
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }


  @override
  void dispose() {
    // Eliminar Listeners
    _abreviaturaController.removeListener(_updateAbreviaturaUpperCase);
    _nombreController.removeListener(_updateNombreUpperCase);
    _direccionController.removeListener(_updateDireccionUpperCase);
    
    // Liberar controladores
    _codigoFincaController.dispose();
    _abreviaturaController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _searchController.dispose(); // Limpiamos el nuevo controlador de búsqueda
    super.dispose();
  }

  Future<void> _cargarAgronomos() async {
    // Para el initial load, no es necesario mostrar el spinner de búsqueda
    final agronomos = await _fincaService.getAllAgronomos();
    setState(() {
      _agronomos = agronomos;
      // IMPORTANTE: Si la lista cambia, es buena práctica resetear la selección para evitar el assertion
      if (_agronomoSeleccionado != null && 
          !_agronomos.any((a) => a['cedula'] == _agronomoSeleccionado)) {
          _agronomoSeleccionado = null;
      }
    });
  }

  // ==========================================================
  // 🔍 BÚSQUEDA EXPLÍCITA DE AGRÓNOMOS (FUNCIÓN MODIFICADA)
  // ==========================================================
  Future<void> _searchAgronomosExplicitly() async {
    final query = _searchController.text.trim();

    // 1. Validar Query No Vacía
    if (query.isEmpty) {
      _mostrarSnackBar("Debe ingresar un nombre o cédula para buscar.", isError: true);
      return;
    }
    
    // 2. Validar Query No Repetida
    if (query == _lastSearchQuery) {
      _mostrarSnackBar("Ya buscó este valor. Modifique la búsqueda para obtener nuevos resultados.", isError: true);
      return;
    }

    setState(() {
        _agronomoSeleccionado = null; 
        _isSearching = true; // Activa el indicador de carga
        _agronomos = []; // Limpiamos la lista anterior
    });

    final result = await _fincaService.searchAgronomo(nombre: query, cedula: query);
    
    if (!mounted) return;

    setState(() {
      if (result['success']) {
        final data = result['data'];
        List<dynamic> resultadosBusqueda = [];

        if (data is Map && data.containsKey('cedula')) {
          resultadosBusqueda = [data];
        } else if (data is Map && data.containsKey('resultados')) {
          // Lógica para filtrar duplicados por cédula
          final Map<String, dynamic> uniqueAgronomos = {};
          for (var agronomo in List.from(data['resultados'])) {
            // Usamos toString() por consistencia aunque aquí el tipo parece ser String
            uniqueAgronomos[agronomo['cedula']?.toString() ?? 'N/A'] = agronomo;
          }
          resultadosBusqueda = uniqueAgronomos.values.toList();
        } else {
          resultadosBusqueda = [];
        }

        _agronomos = resultadosBusqueda;
        _lastSearchQuery = query; // Guardamos la query exitosa

        if (_agronomos.isEmpty) {
          _mostrarSnackBar("No se encontraron Agrónomos para '$query'.", isError: false);
        } else {
          _mostrarSnackBar("Se encontraron ${_agronomos.length} Agrónomos. Seleccione o confirme.", isError: false);
        }

      } else {
        _agronomos = [];
        _mostrarSnackBar(result['message'] ?? "Error al buscar agrónomos.", isError: true);
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
    // Aseguramos que el texto de los controladores ya esté en mayúsculas aquí por si acaso
    _abreviaturaController.text = _abreviaturaController.text.toUpperCase();
    _nombreController.text = _nombreController.text.toUpperCase();
    _direccionController.text = _direccionController.text.toUpperCase();

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
              _buildCodigoTextField(_codigoFincaController, "Código Finca", true),
              const SizedBox(height: 15),
              _buildTextField(_abreviaturaController, "Abreviatura", true),
              const SizedBox(height: 15),
              _buildTextField(_nombreController, "Nombre Finca", true),
              const SizedBox(height: 15),
              _buildTextField(_direccionController, "Dirección", true),
              const SizedBox(height: 25),

              // ======================================================
              // 👨‍🌾 Búsqueda y Dropdown Agrónomo (REEMPLAZO)
              // ======================================================
              const Text(
                "Seleccionar Agrónomo Encargado",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              _buildAgronomoSearchAndDropdown(), // <-- NUEVO WIDGET
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
  // 🧱 Búsqueda y Dropdown para Agrónomo (NUEVO WIDGET)
  // ==========================================================
  Widget _buildAgronomoSearchAndDropdown() {
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
                  "Buscar por Nombre o Cédula",
                ),
                style: const TextStyle(color: Colors.white),
                // Aquí quitamos el onChanged: _buscarAgronomo
              ),
            ),
            const SizedBox(width: 8),
            // Botón que ejecuta la búsqueda
            _isSearching
                ? Container(
                    height: 58, 
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(color: Colors.greenAccent, strokeWidth: 2),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _searchAgronomosExplicitly,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.search),
                  ),
          ],
        ),

        const SizedBox(height: 10),

        // 2. Dropdown de Selección
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: DropdownButtonFormField<String>(
            value: _agronomoSeleccionado,
            isExpanded: true,
            // Ajuste para el padding vertical dentro del campo de selección
            decoration: InputDecoration(
              hintText: _agronomos.isEmpty 
                  ? "Realice la búsqueda para seleccionar un agrónomo"
                  : "Seleccionar Agrónomo (${_agronomos.length} resultados)",
              hintStyle: const TextStyle(color: Colors.white38),
              contentPadding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
              border: InputBorder.none,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            dropdownColor: Colors.black87,
            items: _agronomos.map<DropdownMenuItem<String>>((a) {
              final nombre = a['nombre'] ?? 'Sin nombre';
              // Usamos toString() por seguridad
              final cedula = a['cedula']?.toString() ?? 'N/A'; 
              return DropdownMenuItem<String>(
                value: cedula,
                child: Text(
                  "$nombre ($cedula)",
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _agronomoSeleccionado = value),
            validator: (value) =>
                value == null || value.isEmpty ? 'Seleccione un agrónomo' : null,
          ),
        ),
      ],
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

  Widget _buildCodigoTextField(TextEditingController controller, String label, bool required) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
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