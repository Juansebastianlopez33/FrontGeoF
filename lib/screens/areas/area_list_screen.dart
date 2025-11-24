// lib/screens/area/area_list_screen.dart

import 'package:flutter/material.dart';
import '../../services/area_service.dart'; 
// Importación necesaria para usar las constantes de estilo
import '../home/theme/dark_theme.dart'; 
import 'area_detail_screen.dart';


class AreaListScreen extends StatefulWidget {
  // 🆕 PROPIEDADES NUEVAS: Para la pre-selección desde FincaDetailScreen
  final String? initialFincaId;
  final String? initialFincaName;

  const AreaListScreen({
    super.key, 
    this.initialFincaId, 
    this.initialFincaName
  });

  @override
  State<AreaListScreen> createState() => _AreaListScreenState();
}

class _AreaListScreenState extends State<AreaListScreen> {
  final AreaService _areaService = AreaService();

  List<dynamic> _fincas = [];
  String? _fincaSeleccionadaId; // ID de la finca seleccionada (String)
  
  List<dynamic> _areas = []; // Lista de áreas de la finca seleccionada
  
  bool _isLoadingFincas = false;
  bool _isLoadingAreas = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 🆕 USAR PROPIEDAD INICIAL: Establece el ID si viene de FincaDetailScreen
    _fincaSeleccionadaId = widget.initialFincaId;
    _cargarFincas();
  }



  // ==========================================================
  // ✏️ Navegar a Edición (Al presionar un ListTile)
  // ==========================================================
  void _navigateToDetailsScreen(int idArea) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // Navega a la pantalla de Edición
        builder: (context) => AreaDetailScreen(idArea: idArea), 
      ),
    );

    // Si la edición fue exitosa
    if (result == true) {
      // Si hay una finca seleccionada, recargar sus áreas; si no, recargar la lista de fincas
      if (_fincaSeleccionadaId != null) {
        _cargarAreas(int.parse(_fincaSeleccionadaId!));
      } else {
        _cargarFincas();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista de áreas actualizada')),
      );
    }
  }



  // ==========================================================
  // ⚙️ Cargar Fincas
  // ==========================================================
  Future<void> _cargarFincas() async {
    setState(() {
      _isLoadingFincas = true;
      _errorMessage = null;
    });
    
    final fincas = await _areaService.getAllFincas();
    
    if (!mounted) return;

    setState(() {
      _fincas = fincas;
      _isLoadingFincas = false;
      if (fincas.isEmpty) {
        _errorMessage = "No se encontraron fincas registradas.";
      }
      
      // 🆕 LÓGICA DE CARGA AUTOMÁTICA: Si hay un ID inicial, cargar áreas inmediatamente.
      if (_fincaSeleccionadaId != null && _areas.isEmpty && !_isLoadingAreas) {
        _cargarAreas(int.parse(_fincaSeleccionadaId!));
      }
    });
  }
  
  // ==========================================================
  // ⚙️ Cargar Áreas por Finca
  // ==========================================================
  Future<void> _cargarAreas(int idFinca) async {
    setState(() {
      _isLoadingAreas = true;
      _areas = []; // Limpiar lista anterior
      _errorMessage = null;
    });

    // Usando el método corregido que acepta idFinca
    final areas = await _areaService.getAllAreas(idFinca: idFinca);

    if (!mounted) return;

    setState(() {
      _areas = areas;
      _isLoadingAreas = false;
      if (areas.isEmpty && _fincaSeleccionadaId != null) {
        // Solo mostrar este error si una finca ya fue seleccionada
        _errorMessage = "No se encontraron áreas para la finca seleccionada.";
      }
    });
  }

  // ==========================================================
  // 🧱 Build
  // ==========================================================
  
  // 🆕 FUNCIÓN NUEVA: Para generar el título dinámico y resaltado de la AppBar
  Widget _buildAppBarTitle(Color themeAccent) {
    if (widget.initialFincaName != null) {
      final fincaNameUpper = widget.initialFincaName!.toUpperCase();
      return RichText(
        text: TextSpan(
          text: "Áreas de la Finca: ",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
          children: <TextSpan>[
            TextSpan(
              text: fincaNameUpper,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20, // Más resaltado
                color: themeAccent,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const Text("Listado de Áreas");
  }
  
  @override
  Widget build(BuildContext context) {
    // Uso directo de las constantes del tema
    final themeBackground = GeoFloraTheme.surface; // Usar surface para el cuerpo
    final themeAccent = GeoFloraTheme.accent;
    
    return Scaffold(
      backgroundColor: themeBackground,
      appBar: AppBar(
        // ➡️ CAMBIO CLAVE: Usar el nuevo widget de título con formato RichText
        title: _buildAppBarTitle(themeAccent), 
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: Column(
        children: [
          // ======================================================
          // 🌿 Selector de Finca (SOLO si no viene preseleccionado)
          // ======================================================
          // Si NO tiene initialFincaId, muestra el Dropdown para que el usuario elija
          if (widget.initialFincaId == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _buildFincaDropdown(themeAccent),
            ),
          
          // 🚫 ELIMINADO: La sección de _buildFixedFincaInfo fue removida según lo solicitado.

          // ======================================================
          // 🔄 Indicadores de Carga y Mensajes
          // ======================================================
          if (_isLoadingFincas || _isLoadingAreas)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator(color: themeAccent)),
            ),

          if (_errorMessage != null && !_isLoadingFincas && !_isLoadingAreas)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          
          // ======================================================
          // 📋 Lista de Áreas
          // ======================================================
          Expanded(
            child: _buildAreaList(themeAccent),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 🧱 Helpers UI
  // ==========================================================
  
  // 🚫 ELIMINADO: _buildFixedFincaInfo fue removido.
  // Widget _buildFixedFincaInfo(Color themeAccent) { ... }

  Widget _buildFincaDropdown(Color themeAccent) {
    if (_isLoadingFincas) {
      return Container(); // El indicador de carga ya se muestra arriba
    }

    final title = _buildDropdownTitle("Seleccionar Finca para ver Áreas");

    final dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: DropdownButtonFormField<String>(
        value: _fincaSeleccionadaId,
        isExpanded: true,
        decoration: const InputDecoration(
          hintText: "Seleccione una Finca",
          hintStyle: TextStyle(color: Colors.white38),
          contentPadding: EdgeInsets.fromLTRB(0, 15, 0, 15),
          border: InputBorder.none,
        ),
        icon: Icon(Icons.arrow_drop_down, color: themeAccent),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        dropdownColor: GeoFloraTheme.surface, // Usar color de tema
        items: _fincas.map<DropdownMenuItem<String>>((finca) {
          final codigo = finca['codigoFinca']?.toString() ?? 'N/A';
          final idFinca = finca['idFinca']?.toString() ?? '0';
          final nombre = finca['nombreFinca'] ?? 'Sin nombre';
          return DropdownMenuItem<String>(
            value: idFinca,
            child: Text("$nombre (codigo: $codigo)", style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _fincaSeleccionadaId = value;
              _areas = []; 
              _errorMessage = null;
            });
            // Cargar las áreas
            _cargarAreas(int.parse(value)); 
          }
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Seleccione una finca' : null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [title, dropdown],
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

  Widget _buildAreaList(Color themeAccent) {
    // ⚠️ La condición de mostrar mensaje de no-finca debe considerar el initialFincaId
    if (_fincaSeleccionadaId == null && widget.initialFincaId == null) {
      return const Center(
        child: Text(
          "Seleccione una finca para ver sus áreas.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    
    // Si está cargando o está vacía, evitamos que el ListView.builder dé error
    if (_isLoadingAreas || _areas.isEmpty) {
        // El indicador de carga o el mensaje de 'No hay áreas' ya se manejan arriba
        if (_isLoadingAreas || (_errorMessage != null && _errorMessage!.contains("No se encontraron áreas"))) {
            return Container(); 
        }
    }
    
    // Lista de Áreas
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _areas.length,
      itemBuilder: (context, index) {
        final area = _areas[index];
        // ➡️ CÁLCULOS SIMPLIFICADOS
        final numeroArea = area['numeroArea']?.toString() ?? 'N/A'; 
        final jefeNombre = area['jefeDeArea_nombre'] ?? 'N/A';
        final isActive = area['is_active'] == true; 
        final estado = isActive ? 'Habilitada' : 'Inhabilitada';
        final colorEstado = isActive ? themeAccent : Colors.redAccent;
        final iconEstado = isActive ? Icons.check_circle_outline : Icons.cancel_outlined;
        
        return Card(
          // Usar un color ligeramente distinto o surface
          color: GeoFloraTheme.surface.withOpacity(0.9), 
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: colorEstado.withOpacity(0.3), width: 1.5),
          ),
          // ➡️ WIDGET LISTTILE MODIFICADO PARA SER MÁS DENSO
          child: ListTile(
            leading: Icon(Icons.grass, color: themeAccent),
            // 1. Título: Número de Área prominente
            title: Text(
              'ÁREA N° $numeroArea', 
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w800, // Extra bold
                fontSize: 18
              ),
            ),
            // 2. Subtítulo: Jefe e ID en una sola línea
            subtitle: Text(
              'Jefe: $jefeNombre', 
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            // 3. Trailing: Estado (Icono y Texto)
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconEstado, color: colorEstado, size: 16),
                const SizedBox(width: 4),
                Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12
                  ),
                ),
              ],
            ),
            onTap: () {
              final rawId = area['idArea'];
              final idArea = rawId is int
                  ? rawId
                  : int.tryParse(rawId?.toString() ?? '') ?? 0;
              _navigateToDetailsScreen(idArea);
            },
          ),
        );
      },
    );
  } 
}