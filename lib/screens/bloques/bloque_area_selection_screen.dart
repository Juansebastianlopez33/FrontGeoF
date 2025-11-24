// lib/screens/bloque/bloque_area_selection_screen.dart (REFACTORIZADO CON TABS PARA BLOQUES)

import 'package:flutter/material.dart';
import '../../services/bloques_service.dart';
import '../../services/finca_service.dart';
import '../../services/area_service.dart';
import '../home/theme/dark_theme.dart';
import 'bloque_create_screen.dart';
import 'bloque_edit_screen.dart';

// 🟢 NUEVO: Enum para controlar el estado actual de la selección
enum SelectionLevel { finca, area, bloque }

// 🎯 AJUSTE CLAVE: Añadir SingleTickerProviderStateMixin para el TabController
class BloqueAreaSelectionScreen extends StatefulWidget {
  const BloqueAreaSelectionScreen({super.key});

  @override
  State<BloqueAreaSelectionScreen> createState() => _BloqueAreaSelectionScreenState();
}

// 🎯 AJUSTE CLAVE: Implementar SingleTickerProviderStateMixin
class _BloqueAreaSelectionScreenState extends State<BloqueAreaSelectionScreen>
    with SingleTickerProviderStateMixin {
  final BloquesService _bloquesService = BloquesService();
  final AreaService _areaService = AreaService();

  // 🟢 NUEVO: Estado actual de navegación
  SelectionLevel _currentLevel = SelectionLevel.finca;

  // Nivel 1: Finca
  List<dynamic> _fincas = [];
  int? _idFincaSeleccionada;
  String? _nombreFincaSeleccionada;

  // Nivel 2: Área
  List<dynamic> _areas = [];
  int? _idAreaSeleccionada;
  String? _numeroAreaSeleccionada;

  // Nivel 3: Bloques
  // 🎯 NUEVO: Separar la lista de bloques en activa e inactiva para el TabBar
  List<dynamic> _bloquesActivos = [];
  List<dynamic> _bloquesInactivos = [];
  
  // 🎯 NUEVO: TabController para la vista de Bloques
  late TabController _tabController;


  bool _isLoadingFincas = true;
  bool _isLoadingAreas = false;
  // 🎯 MODIFICADO: Solo un flag de carga para los bloques, se usa en _loadBloquesByStatus
  bool _isLoadingBloques = false; 
  String? _errorMessage;

  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;

  @override
  void initState() {
    super.initState();
    _loadFincas();
    // 🎯 INICIALIZACIÓN DEL TAB CONTROLLER (2 pestañas: Activos/Inactivos)
    _tabController = TabController(length: 2, vsync: this);
    // 💡 Escuchar cambios para recargar la lista de bloques si la pestaña cambia
    _tabController.addListener(_handleTabSelection);
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }
  
  // 💡 Manejar cambio de pestaña para recargar solo la lista actual
  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      if (_currentLevel == SelectionLevel.bloque && _idAreaSeleccionada != null) {
        // Recarga la lista de la pestaña seleccionada
        _loadBloquesByStatus(_tabController.index == 0); 
      }
    }
  }


  // ==========================================================
  // NAVEGACIÓN Y CARGA DE DATOS
  // ==========================================================

  // 🟢 NUEVO: Función para retroceder un nivel
  void _goBack() {
    setState(() {
      if (_currentLevel == SelectionLevel.bloque) {
        _currentLevel = SelectionLevel.area;
        _idAreaSeleccionada = null;
        _numeroAreaSeleccionada = null;
        _bloquesActivos = []; // Limpiar listas de bloques
        _bloquesInactivos = [];
      } else if (_currentLevel == SelectionLevel.area) {
        _currentLevel = SelectionLevel.finca;
        _idFincaSeleccionada = null;
        _nombreFincaSeleccionada = null;
        _areas = [];
      }
    });
  }

  // Nivel 1: CARGAR FINCAS (sin cambios mayores)
  Future<void> _loadFincas() async {
    // ... (Mismo código de _loadFincas)
    setState(() {
      _isLoadingFincas = true;
      _errorMessage = null;
    });

    final FincaService fincaService = FincaService();
    final fincasList = await fincaService.getAllFincas();

    if (mounted) {
      if (fincasList.isNotEmpty) {
        setState(() {
          _fincas = fincasList;
        });
      } else {
        setState(() {
          _errorMessage = "No se encontraron fincas. No se pueden cargar áreas.";
        });
      }
      setState(() {
        _isLoadingFincas = false;
      });
    }
  }


  // Nivel 2: CARGAR ÁREAS POR FINCA (Añade el cambio de nivel)
  Future<void> _loadAreas(int idFinca, String nombreFinca) async {
    // ... (Mismo código de _loadAreas)
    setState(() {
      // 🟢 Asignación del estado para la navegación
      _idFincaSeleccionada = idFinca;
      _nombreFincaSeleccionada = nombreFinca;
      _idAreaSeleccionada = null;
      _bloquesActivos = [];
      _bloquesInactivos = [];
      _isLoadingAreas = true;
      _areas = [];
    });

    // 🎯 MODIFICACIÓN 1: Añadir onlyActive: true
    final areasList = await _areaService.getAllAreas(idFinca: idFinca, onlyActive: true);

    if (mounted) {
      setState(() {
        _areas = areasList;
        _isLoadingAreas = false;
        // 🟢 NAVIGACIÓN: Cambia a la vista de Áreas
        _currentLevel = SelectionLevel.area;
      });
      if (_areas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          // 🎯 MODIFICACIÓN 2: Actualizar mensaje de SnackBar
          SnackBar(content: Text('No hay áreas habilitadas registradas para la finca "$nombreFinca".')),
        );
      }
    }
  }


  // Nivel 3: CARGAR BLOQUES POR ÁREA (Prepara el estado, pero no los carga)
  Future<void> _loadBloques(int idArea, String numeroArea) async {
    // 🟢 Asignación del estado para la navegación
    setState(() {
      _idAreaSeleccionada = idArea;
      _numeroAreaSeleccionada = numeroArea;
      _bloquesActivos = [];
      _bloquesInactivos = [];
      _currentLevel = SelectionLevel.bloque; // Cambia a la vista de Bloques
      _tabController.index = 0; // Por defecto, la pestaña de Bloques Habilitados
    });
    // 💡 Iniciar la carga de los bloques activos (la pestaña por defecto)
    await _loadBloquesByStatus(true); 
  }
  
  // 🎯 NUEVO: Cargar bloques con el filtro de estado (isActive)
  Future<void> _loadBloquesByStatus(bool isActive) async {
    if (_idAreaSeleccionada == null) return;

    setState(() {
      _isLoadingBloques = true;
    });

    final bloquesList = await _bloquesService.getAllBloques(
      idArea: _idAreaSeleccionada, 
      isActive: isActive, // Usa el parámetro isActive para filtrar
    );

    if (mounted) {
      setState(() {
        _isLoadingBloques = false;
        if (isActive) {
          _bloquesActivos = bloquesList;
        } else {
          _bloquesInactivos = bloquesList;
        }
      });
      
      // Mostrar SnackBar solo si la lista está vacía
      if (bloquesList.isEmpty) {
        final statusText = isActive ? 'habilitados' : 'inhabilitados';
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay bloques $statusText registrados para el Área N° $_numeroAreaSeleccionada.')),
        );
      }
    }
  }


  // Funciones de navegación (sin cambios, solo llama a la recarga de bloques)
  Future<void> _navigateToEditScreen(int idBloque) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BloqueEditScreen(idBloque: idBloque),
      ),
    );
    if (result == true && _idAreaSeleccionada != null) {
      // Recarga la lista de la pestaña actual
      _loadBloquesByStatus(_tabController.index == 0);
    }
  }

  Future<void> _navigateToCreateScreen() async {
    if (_idAreaSeleccionada == null) return;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BloqueCreateScreen(idAreaInicial: _idAreaSeleccionada),
      ),
    );
    if (result == true && _idAreaSeleccionada != null) {
      // Recarga la lista de la pestaña de Activos (donde se verá el nuevo bloque)
      _tabController.index = 0;
      _loadBloquesByStatus(true);
    }
  }

  // ==========================================================
  // WIDGETS DE LISTA
  // ==========================================================
  // ... (_buildFincaList) ...
  // Nivel 1: Lista de Fincas (Modificado onTap)
  Widget _buildFincaList() {
    if (_isLoadingFincas) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _fincas.length,
      itemBuilder: (context, index) {
        final finca = _fincas[index];
        final idFinca = finca['idFinca'] as int;
        final nombreFinca = finca['nombreFinca']?.toString() ?? 'N/A';

        return Card(
          color: Colors.black38,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: const Icon(Icons.agriculture, color: Colors.white70),
            title: Text(nombreFinca, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              // 🟢 LÓGICA DE NAVEGACIÓN: Cargar áreas y cambiar el nivel
              _loadAreas(idFinca, nombreFinca);
            },
          ),
        );
      },
    );
  }
  
  // ... (_buildAreaList) ...
  // Nivel 2: Lista de Áreas (Modificado onTap)
  Widget _buildAreaList() {
    if (_isLoadingAreas) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_areas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Text(
          'La Finca "$_nombreFincaSeleccionada" no tiene áreas registradas.',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _areas.length,
      itemBuilder: (context, index) {
        final area = _areas[index];
        final idArea = area['idArea'] as int;
        final numeroArea = area['numeroArea']?.toString() ?? 'N/A';

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          child: ListTile(
            leading: const Icon(Icons.location_city, color: Colors.white70),
            title: Text('Área N° $numeroArea', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {
              // 🟢 LÓGICA DE NAVEGACIÓN: Cargar bloques y cambiar el nivel
              _loadBloques(idArea, numeroArea);
            },
          ),
        );
      },
    );
  }


  // Nivel 3: Lista de Bloques (MODIFICADO para recibir la lista a mostrar)
  Widget _buildBloqueList(List<dynamic> bloques, bool isActiveTab) {
    if (_isLoadingBloques) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    final statusText = isActiveTab ? 'habilitados' : 'inhabilitados';

    if (bloques.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            'No hay bloques $statusText registrados para el Área N° $_numeroAreaSeleccionada.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBloquesByStatus(isActiveTab), // Permite recargar
      backgroundColor: Colors.black,
      color: _themeAccent,
      child: ListView.builder(
        shrinkWrap: true,
        // Usamos AlwaysScrollableScrollPhysics para permitir el RefreshIndicator incluso con pocos elementos
        physics: const AlwaysScrollableScrollPhysics(), 
        itemCount: bloques.length,
        itemBuilder: (context, index) {
          final bloque = bloques[index];
          final idBloque = bloque['idBloque'] as int;
          final numeroBloque = bloque['numeroBloque']?.toString() ?? 'N/A';
          final isActive = bloque['is_active'] == true;

          final Color statusColor = isActive ? _themeAccent : Colors.redAccent;
          final String statusText = isActive ? 'Habilitado' : 'Inhabilitado';

          return Card(
            color: Colors.black45,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              onTap: () => _navigateToEditScreen(idBloque),
              leading: Icon(Icons.grass, color: statusColor),
              title: Text(
                'BLOQUE $numeroBloque',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado: $statusText',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              trailing: Switch(
                value: isActive,
                onChanged: (newStatus) => _toggleStatusBloque(idBloque, newStatus),
                activeColor: _themeAccent,
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red.withOpacity(0.3),
              ),
            ),
          );
        },
      ),
    );
  }

  // Acción para el Switch (MODIFICADO para recargar las dos listas)
  Future<void> _toggleStatusBloque(int idBloque, bool newStatus) async {
    // Optimistic UI Update (Se mantiene, pero se revierte al no usarlo)
    // No se realiza una actualización optimista ya que la recarga de listas es inmediata.
    
    final result = await _bloquesService.toggleBloqueStatus(idBloque, newStatus);

    if (mounted) {
      if (!result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar estado: ${result['message']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bloque ${newStatus ? 'habilitado' : 'inhabilitado'}')),
        );
      }
      // 🎯 MODIFICACIÓN CLAVE: Recargar ambas listas (Activos e Inactivos) para mover el bloque
      await _loadBloquesByStatus(true);
      await _loadBloquesByStatus(false);
    }
  }


  // 🟢 NUEVO: Helper para obtener el Widget de contenido actual (MODIFICADO)
  Widget _buildCurrentContent() {
    switch (_currentLevel) {
      case SelectionLevel.finca:
        return _buildFincaList();
      case SelectionLevel.area:
        return _buildAreaList();
      case SelectionLevel.bloque:
        // 🎯 AJUSTE CLAVE: Usar TabBarView para los bloques
        return Expanded( // El TabBarView debe estar dentro de un Expanded o tener una altura fija
          child: TabBarView(
            controller: _tabController,
            children: [
              // Pestaña 1: Bloques Habilitados
              _buildBloqueList(_bloquesActivos, true), 
              // Pestaña 2: Bloques Inhabilitados
              _buildBloqueList(_bloquesInactivos, false), 
            ],
          ),
        );
    }
  }

  // 🟢 NUEVO: Helper para obtener el título del AppBar
  String _getAppBarTitle() {
    switch (_currentLevel) {
      case SelectionLevel.finca:
        return '1. Seleccione una Finca';
      case SelectionLevel.area:
        return '2. Áreas de: $_nombreFincaSeleccionada';
      case SelectionLevel.bloque:
        return '3. Bloques del Área N° $_numeroAreaSeleccionada';
    }
  }

  // 🎯 NUEVO: Helper para obtener el TabBar
  PreferredSizeWidget? _getAppBarBottom() {
    if (_currentLevel == SelectionLevel.bloque) {
      return TabBar(
        controller: _tabController,
        indicatorColor: _themeAccent,
        labelColor: _themeAccent,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: "Habilitados"),
          Tab(text: "Inhabilitados"),
        ],
      );
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        title: Text(_getAppBarTitle()), // 🟢 Título dinámico
        backgroundColor: Colors.black.withOpacity(0.7),
        // 🟢 BOTÓN DE REGRESO: Solo se muestra si no estamos en el primer nivel (Finca)
        leading: _currentLevel != SelectionLevel.finca
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              )
            : null,
        // 🎯 AJUSTE CLAVE: Agregar TabBar al bottom de la AppBar en el nivel bloque
        bottom: _getAppBarBottom(), 
      ),

      // 🟢 CUERPO: Ajuste para usar Column con Expanded cuando es TabBarView
      body: _currentLevel == SelectionLevel.bloque
          ? Column(
              children: <Widget>[
                _buildCurrentContent(), // Esto ahora es Expanded(TabBarView)
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildCurrentContent(), // Mantiene el SingleChildScrollView
                  
                  // Mostramos el mensaje de error de carga de fincas solo si estamos en ese nivel
                  if (_currentLevel == SelectionLevel.finca && _errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

      // Botón flotante para la creación de bloques (solo si estamos en el nivel Bloque)
      floatingActionButton: _currentLevel == SelectionLevel.bloque && _idAreaSeleccionada != null
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateScreen,
              label: const Text('Nuevo Bloque'),
              icon: const Icon(Icons.add),
              backgroundColor: _themeAccent,
            )
          : null,
    );
  }
}