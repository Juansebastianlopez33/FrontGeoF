// lib/screens/area/area_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/area_service.dart';
// Asegúrate de la ruta correcta a tu tema
import '../home/theme/dark_theme.dart';
import 'dart:async'; // Necesario para Future

class AreaEditScreen extends StatefulWidget {
  final int idArea;

  const AreaEditScreen({super.key, required this.idArea});

  @override
  State<AreaEditScreen> createState() => _AreaEditScreenState();
}

class _AreaEditScreenState extends State<AreaEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final AreaService _areaService = AreaService();

  // Controladores de Texto
  final TextEditingController _numeroAreaController = TextEditingController();
  final TextEditingController _jefeAreaDisplayController = TextEditingController();

  // Datos
  List<dynamic> _fincas = [];
  String? _fincaSeleccionadaId;
  Map<String, dynamic>? _jefeAreaSeleccionado;
  String? _jefeAreaSeleccionadoCedula;

  // 🎯 NUEVO: Variables de Estado para el Switch
  Map<String, dynamic>? _areaData; // Para guardar la data del área
  bool _isAreaActive = false; // Estado del Switch

  bool _isLoading = false;
  bool _isInitialLoading = true;
  String? _initialErrorMessage;

  // Constantes de Estilo
  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;
  final Color _errorColor = Colors.redAccent; // Añadido para consistencia

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ==========================================================
  // ⚙️ Cargar Datos Iniciales (Fincas + Detalles del Área)
  // ==========================================================
  Future<void> _loadInitialData() async {
    setState(() => _isInitialLoading = true);

    // 1. Cargar todas las fincas para el Dropdown
    final fincas = await _areaService.getAllFincas();

    // 2. Cargar detalles del área a editar
    final detailResult = await _areaService.getAreaDetails(widget.idArea);

    if (!mounted) return;

    if (detailResult['success'] == true && fincas.isNotEmpty) {
      final areaData = detailResult['data'];
      
      // 🎯 INICIALIZACIÓN: Guardar la data y el estado del switch
      _areaData = areaData; 
      _isAreaActive = areaData['is_active'] ?? false;
      
      _numeroAreaController.text = areaData['numeroArea']?.toString() ?? '';

      // Establecer la finca inicial seleccionada
      _fincaSeleccionadaId = areaData['idFinca']?.toString();

      // Jefe de Área: Obtener nombre de forma robusta
      final jefeCedula = areaData['jefeDeArea_id'];
      final jefeNameFromBackend = areaData['jefeDeArea_nombre'] ?? areaData['nombre'];

      if (jefeCedula != null && jefeNameFromBackend != null) {
        _jefeAreaSeleccionadoCedula = jefeCedula;
        _jefeAreaSeleccionado = {'cedula': jefeCedula, 'nombre': jefeNameFromBackend};
        _jefeAreaDisplayController.text = _displayStringForOption(_jefeAreaSeleccionado!);
      } else {
        _jefeAreaSeleccionadoCedula = null;
        _jefeAreaSeleccionado = null;
        _jefeAreaDisplayController.text = '';
      }

      setState(() {
        _fincas = fincas;
        _isInitialLoading = false;
      });

    } else {
      setState(() {
        _fincas = fincas;
        _isInitialLoading = false;
        _initialErrorMessage = detailResult['message'] ?? "No se pudo cargar la información del área para editar.";
      });
    }
  }

  // ==========================================================
  // 💾 Actualizar Área (PUT)
  // ==========================================================
  Future<void> _updateArea() async {
    if (_jefeAreaSeleccionadoCedula == null || _jefeAreaSeleccionadoCedula!.isEmpty) {
      _mostrarSnackBar("El campo 'Jefe de Área' es obligatorio.", isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_fincaSeleccionadaId == null) {
      _mostrarSnackBar("Debe seleccionar una Finca.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final numeroAreaText = _numeroAreaController.text.trim();

    final areaData = {
      'idArea': widget.idArea,
      'numeroArea': numeroAreaText.isNotEmpty ? int.tryParse(numeroAreaText) : null,
      'idFinca': int.parse(_fincaSeleccionadaId!),
      'jefeDeArea_id': _jefeAreaSeleccionadoCedula,
      // NOTA: El estado 'is_active' NO se envía en esta ruta PUT,
      // sino que se maneja separadamente por _toggleStatus (PATCH).
    };

    final result = await _areaService.updateArea(widget.idArea, areaData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _mostrarSnackBar('✅ Área actualizada exitosamente: ${result['message']}');
      Navigator.pop(context, true);
    } else {
      _mostrarSnackBar('🔴 Error al actualizar el área: ${result['message']}', isError: true);
    }
  }
  
  // ==========================================================
  // 🚫 Toggle Status del Área (Función Clave)
  // ==========================================================
  Future<void> _toggleStatus(bool newValue) async {
    // Si el nuevo valor es el mismo que el actual, no hacemos nada 
    if (newValue == _isAreaActive) return; 
    
    // 1. Mostrar confirmación
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newValue ? 'Habilitar Área' : 'Inhabilitar Área'),
        content: Text(
          newValue 
            ? '¿Está seguro de habilitar esta Área? Tenga en cuenta que los elementos de su jerarquía (Bloques, Naves, Camas) DEBEN ser habilitados individualmente si se requiere.'
            : '¿Está seguro de inhabilitar esta Área? Esto **también inhabilitará toda su jerarquía descendiente** (Bloques, Naves, Camas) en el sistema.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(newValue ? 'Habilitar' : 'Inhabilitar', style: TextStyle(color: newValue ? _themeAccent : _errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) {
      // Si el usuario cancela, aseguramos que el switch visualmente permanezca en su estado original.
      setState(() {}); 
      return; 
    } 

    // 2. Llamada al servicio
    setState(() => _isLoading = true);

    // Llama al servicio PATCH /status
    final result = await _areaService.toggleAreaStatus(widget.idArea); 
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        // 3. Si la API fue exitosa, actualizamos el estado local del Switch
        setState(() {
          _isAreaActive = newValue; 
        });
        _mostrarSnackBar(result['message'] ?? 'Estado cambiado con éxito');
      } else {
        // 4. Si falla, mostramos el error y forzamos al Switch a volver a su estado original
        _mostrarSnackBar(result['message'] ?? 'Error al cambiar el estado', isError: true);
        setState(() {}); 
      }
    }
  }


  // ==========================================================
  // 🎯 HELPERS
  // ==========================================================
  String _displayStringForOption(Map<String, dynamic> option) {
    final nombre = option['nombre'] ?? 'Sin nombre';
    final cedula = option['cedula'] ?? 'N/A';
    return "$nombre ($cedula)";
  }

  Future<void> _showJefeAreaSearchDialog() async {
    final selectedJefe = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JefeAreaSearchPage(areaService: _areaService),
        fullscreenDialog: true,
      ),
    );

    if (selectedJefe != null && selectedJefe is Map<String, dynamic>) {
      setState(() {
        _jefeAreaSeleccionado = selectedJefe;
        _jefeAreaSeleccionadoCedula = selectedJefe['cedula']?.toString();
        _jefeAreaDisplayController.text = _displayStringForOption(selectedJefe);
      });
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
        backgroundColor: isError ? _errorColor : _themeAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _numeroAreaController.dispose();
    _jefeAreaDisplayController.dispose();
    super.dispose();
  }


  // ==========================================================
  // 🧱 Build
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        title: Text("Editar Área ID: ${widget.idArea}"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: _isInitialLoading
          ? Center(child: CircularProgressIndicator(color: _themeAccent))
          : _initialErrorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      '🔴 Error: $_initialErrorMessage',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        
                        // 🎯 NUEVO: Switch de Habilitar/Inhabilitar
                        Card(
                          color: Colors.black38,
                          margin: const EdgeInsets.only(bottom: 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isAreaActive ? 'Estado: HABILITADA' : 'Estado: INHABILITADA',
                                  style: TextStyle(
                                    color: _isAreaActive ? _themeAccent : Colors.redAccent,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Switch(
                                  value: _isAreaActive,
                                  onChanged: _toggleStatus, // Llama a la nueva función
                                  activeColor: _themeAccent, // Verde/Accent para Habilitado
                                  inactiveThumbColor: Colors.red, // Rojo para Inhabilitado
                                  inactiveTrackColor: Colors.red.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Campo: Número de Área
                        _buildTextField(
                            _numeroAreaController,
                            "Número de Área (Máx 3 dígitos)",
                            false,
                            maxLength: 3,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                        const SizedBox(height: 25),

                        // Dropdown de Finca
                        _buildDropdownTitle("Finca Perteneciente (Editable)"),
                        _buildFincaDropdown(),
                        const SizedBox(height: 25),

                        // Campo de Jefe de Área con botón de búsqueda
                        _buildDropdownTitle("Jefe de Área Seleccionado (Obligatorio)"),
                        _buildJefeAreaSearchField(),
                        const SizedBox(height: 30),

                        // Botón Guardar
                        _isLoading
                            ? Center(child: CircularProgressIndicator(color: _themeAccent))
                            : ElevatedButton.icon(
                                  onPressed: _updateArea,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _themeAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.save),
                                  label: const Text(
                                    "Actualizar Área",
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
  // 🧱 FIX 1 & 2: Campo de texto que muestra la selección y tiene botón de búsqueda
  // ==========================================================
  Widget _buildJefeAreaSearchField() {

    final searchIconColor = _jefeAreaSeleccionadoCedula != null
        ? _themeAccent 
        : _themeAccent.withOpacity(0.6); 

    return TextFormField(
      controller: _jefeAreaDisplayController,
      readOnly: true, 
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(
        "Jefe de Área",
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para limpiar la selección
            if (_jefeAreaSeleccionadoCedula != null)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.redAccent),
                onPressed: () {
                  setState(() {
                    _jefeAreaSeleccionado = null;
                    _jefeAreaSeleccionadoCedula = null;
                    _jefeAreaDisplayController.clear();
                  });
                },
              ),
            // Botón para iniciar la búsqueda
            IconButton(
              icon: Icon(Icons.search, color: searchIconColor),
              onPressed: _showJefeAreaSearchDialog,
            ),
          ],
        ),
      ),
      validator: (value) {
        if (_jefeAreaSeleccionadoCedula == null || _jefeAreaSeleccionadoCedula!.isEmpty) {
          return 'Debe seleccionar un Jefe de Área.';
        }
        return null;
      },
      onTap: _showJefeAreaSearchDialog,
    );
  }

  // ==========================================================
  // 🧱 Dropdown para Finca (Editable)
  // ==========================================================
  Widget _buildFincaDropdown() {
    final items = _fincas.map<DropdownMenuItem<String>>((finca) {
      final id = finca['idFinca']?.toString() ?? '';
      final nombre = finca['nombreFinca'] ?? 'Finca sin nombre';
      return DropdownMenuItem<String>(
        value: id,
        child: Text('$nombre (ID: $id)'),
      );
    }).toList();

    return _buildDropdownField(
      value: _fincaSeleccionadaId,
      hint: 'Seleccione una Finca',
      items: items,
      onChanged: (String? newValue) {
        setState(() {
          _fincaSeleccionadaId = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Debe seleccionar una finca.';
        }
        return null;
      },
      suffixIcon: const Icon(Icons.location_on_outlined, color: Colors.white54),
    );
  }

  // ==========================================================
  // 🧱 Dropdown Genérico (Se mantiene igual)
  // ==========================================================
  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    required String? Function(String?)? validator,
    Widget? suffixIcon,
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
          suffixIcon: suffixIcon,
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

  // ==========================================================
  // 🧱 Helpers UI (Se mantienen igual)
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
        borderSide: BorderSide(color: _themeAccent),
      ),
      filled: true,
      fillColor: Colors.black26,
    );
  }
}

// ==========================================================
// 🎯 PÁGINA MODAL DE BÚSQUEDA (Se mantiene igual)
// ==========================================================
class JefeAreaSearchPage extends StatefulWidget {
  final AreaService areaService;

  const JefeAreaSearchPage({super.key, required this.areaService});

  @override
  State<JefeAreaSearchPage> createState() => _JefeAreaSearchPageState();
}

class _JefeAreaSearchPageState extends State<JefeAreaSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;
  final Color _themeAccent = GeoFloraTheme.accent;
  
  bool _isQueryValid = false; 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateQueryState); 
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateQueryState);
    _searchController.dispose();
    super.dispose();
  }
  
  void _updateQueryState() {
    final newValidity = _searchController.text.trim().length >= 3;
    if (_isQueryValid != newValidity) {
      setState(() {
        _isQueryValid = newValidity;
      });
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || query.length < 3) {
      setState(() {
        _searchResults = [];
        _errorMessage = "Ingrese al menos 3 caracteres para buscar.";
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.areaService.searchJefesArea(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        if (_searchResults.isEmpty) {
          _errorMessage = "No se encontraron Jefes de Área con esa consulta.";
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = "Error al conectar con el servidor: $e";
      });
    }
  }

  String _displayStringForOption(Map<String, dynamic> option) {
    final nombre = option['nombre'] ?? 'Sin nombre';
    final cedula = option['cedula'] ?? 'N/A';
    return "$nombre ($cedula)";
  }

  @override
  Widget build(BuildContext context) {
    final searchIconColor = _isQueryValid ? _themeAccent : Colors.white54;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Buscar Jefe de Área"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Nombre o Cédula (Mín. 3 caracteres)",
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _isQueryValid ? _themeAccent : Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _isQueryValid ? _themeAccent : Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _themeAccent),
                ),
                suffixIcon: _isSearching
                    ? Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(color: _themeAccent, strokeWidth: 2),
                      )
                    : IconButton(
                        icon: Icon(Icons.search, color: searchIconColor),
                        onPressed: _isQueryValid ? _performSearch : null, 
                      ),
              ),
              onEditingComplete: _isQueryValid ? _performSearch : null,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isSearching
                  ? Center(child: CircularProgressIndicator(color: _themeAccent))
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                      : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final jefe = _searchResults[index];
                              return Card(
                                color: Colors.black26,
                                child: ListTile(
                                  leading: const Icon(Icons.person, color: Colors.white70),
                                  title: Text(jefe['nombre'] ?? 'N/A', style: const TextStyle(color: Colors.white)),
                                  subtitle: Text('Cédula: ${jefe['cedula'] ?? 'N/A'}', style: const TextStyle(color: Colors.white54)),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.greenAccent),
                                  onTap: () {
                                    Navigator.pop(context, jefe);
                                  },
                                ),
                              );
                            },
                          ),
            ),
          ],
        ),
      ),
    );
  }
}