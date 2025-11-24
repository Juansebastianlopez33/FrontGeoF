// lib/screens/area/area_list_finca_edit_screen.dart

import 'package:flutter/material.dart';
import '../../services/area_service.dart';
import 'area_edit_screen.dart'; // Importar la pantalla de edición
import 'area_create_screen.dart'; // 💡 Importación para crear área
// Asegúrate de la ruta correcta a tu tema
import '../home/theme/dark_theme.dart'; 

// ✅ AJUSTE CLAVE 1: Implementar SingleTickerProviderStateMixin para el TabController
class AreaListFincaEditScreen extends StatefulWidget {
  // idFinca ahora es obligatorio para el filtrado inicial
  final int idFinca; 
  final String nombreFinca; // Nombre de la finca para mostrar en el título

  const AreaListFincaEditScreen({super.key, required this.idFinca, required this.nombreFinca});

  @override
  // 💡 USAR EL MIXIN
  State<AreaListFincaEditScreen> createState() => _AreaListFincaEditScreenState();
}

// ✅ AJUSTE CLAVE 2: Implementar SingleTickerProviderStateMixin para el TabController
class _AreaListFincaEditScreenState extends State<AreaListFincaEditScreen> with SingleTickerProviderStateMixin {
  final AreaService _areaService = AreaService();
  
  // 🛑 AJUSTE CLAVE 3: Dos listas separadas
  List<dynamic> _areasHabilitadas = [];
  List<dynamic> _areasInhabilitadas = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  // 💡 TabController para manejar las pestañas
  late TabController _tabController;

  // Constantes de Estilo
  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;
  
  @override
  void initState() {
    super.initState();
    // 💡 Inicializar el TabController con 2 pestañas
    _tabController = TabController(length: 2, vsync: this); 
    _loadAreas();
  }
  
  // 💡 Liberar el controller
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================================
  // ⚙️ Cargar Áreas (Carga ambas listas separadas por estado)
  // ==========================================================
  Future<void> _loadAreas() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🛑 AJUSTE CLAVE 4: Llamadas separadas para cada estado (usando el nuevo método)
      final loadedHabilitadas = await _areaService.getAreasByStatus(idFinca: widget.idFinca, isActive: true);
      final loadedInhabilitadas = await _areaService.getAreasByStatus(idFinca: widget.idFinca, isActive: false);
      
      if (mounted) {
        setState(() {
          _areasHabilitadas = loadedHabilitadas; // Asignar a la lista de habilitadas
          _areasInhabilitadas = loadedInhabilitadas; // Asignar a la lista de inhabilitadas
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar las áreas: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // ✏️ Navegar a Edición (Al presionar un ListTile)
  // ==========================================================
  void _navigateToEditScreen(int idArea) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // Navega a la pantalla de Edición
        builder: (context) => AreaEditScreen(idArea: idArea), 
      ),
    );

    // Si la edición fue exitosa
    if (result == true) {
      _loadAreas(); // Recarga ambas listas
      _mostrarSnackBar('Lista de áreas actualizada');
    }
  }

  // ==========================================================
  // ➕ Navegar a Creación (Al presionar el FAB)
  // ==========================================================
  void _navigateToCreateScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AreaCreateScreen(), // Navega a la pantalla de Creación
      ),
    );

    // Si la creación fue exitosa
    if (result == true) {
      _loadAreas(); // Recarga ambas listas
      _mostrarSnackBar('✅ Nueva área creada y lista actualizada');
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
        backgroundColor: isError ? Colors.red : _themeAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // 🧱 Build
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        title: Text("Áreas de Finca: ${widget.nombreFinca}"),
        backgroundColor: Colors.black.withOpacity(0.7),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAreas, // Opción para recargar manualmente
          ),
        ],
        // 🛑 AJUSTE CLAVE 5: Agregar TabBar al Bottom de AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _themeAccent,
          tabs: [
            Tab(text: 'Habilitadas (${_areasHabilitadas.length})'),
            Tab(text: 'Inhabilitadas (${_areasInhabilitadas.length})'),
          ],
        ),
      ),
      body: _buildBody(),
      // ➕ Floating Action Button para CREAR Área
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateScreen, // Llama a la función para crear
        backgroundColor: _themeAccent,
        tooltip: 'Crear nueva área',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: _themeAccent));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            '🔴 Error al cargar: $_errorMessage',
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // 🛑 AJUSTE CLAVE 6: Usar TabBarView para mostrar las dos listas separadas
    return TabBarView(
      controller: _tabController,
      children: [
        // Pestaña 1: Habilitadas
        _buildAreaList(_areasHabilitadas, true),
        // Pestaña 2: Inhabilitadas
        _buildAreaList(_areasInhabilitadas, false),
      ],
    );
  }

  // 🛑 AJUSTE CLAVE 7: Función auxiliar para construir la lista (reutilizable)
  Widget _buildAreaList(List<dynamic> areas, bool isActiveList) {
    if (areas.isEmpty) {
      String status = isActiveList ? 'Habilitadas' : 'Inhabilitadas';
      return Center(
        child: Text(
          "No hay áreas $status registradas para esta Finca.",
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }
    
    // 🧱 Lista de Áreas
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: areas.length,
      itemBuilder: (context, index) {
        final area = areas[index];
        final idArea = area['idArea'] as int;
        
        // ✅ AJUSTE CLAVE: Buscar el nombre del jefe usando las claves más probables.
        final String jefeNombreEnArea = (area['jefeDeArea_nombre'] ?? area['nombre'] ?? '') as String;
        final jefeId = area['jefeDeArea_id'];
        
        // 💡 Estrategia para "garantizar" la información sin hacer N+1 queries:
        final String displayJefeNombre = (jefeNombreEnArea.isEmpty && jefeId != null) 
            ? 'ID: $jefeId (Pendiente nombre de Back-End)'
            : (jefeNombreEnArea.isEmpty ? 'No asignado' : jefeNombreEnArea);
        
        return Card(
          color: Colors.black26,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          
          // ⚠️ Acción al presionar: Navegar a Edición
          child: ListTile(
            onTap: () => _navigateToEditScreen(idArea), 
            
            leading: Icon(
              Icons.location_on, 
              // Color basado en el estado de la lista actual
              color: isActiveList ? _themeAccent : Colors.red,
            ),
            
            title: Text(
                'Area numero: ${area['numeroArea'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Línea corregida para mostrar el nombre del jefe de área
                Text(
                  'Jefe de Área: $displayJefeNombre', // Usar el nombre final
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  isActiveList ? 'Estado: Habilitada' : 'Estado: Inhabilitada',
                  style: TextStyle(
                    color: isActiveList ? _themeAccent : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            trailing: const Icon(Icons.edit, color: Colors.white70), // Indicador de Edición
          ),
        );
      },
    );
  }
}