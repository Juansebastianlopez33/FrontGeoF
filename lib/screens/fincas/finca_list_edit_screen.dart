// lib/screens/finca/finca_list_edit_screen.dart (Refactorizado)

import 'package:flutter/material.dart';
import '../../services/finca_service.dart';
import '../home/theme/dark_theme.dart';
import 'finca_edit_screen.dart'; // Pantalla de edición
import 'finca_create_screen.dart'; // 💡 Asumo que tienes una pantalla de creación

class FincaListEditScreen extends StatefulWidget {
  const FincaListEditScreen({super.key});

  @override
  State<FincaListEditScreen> createState() => _FincaListEditScreenState();
}

// ==========================================================
// 🎯 AJUSTE CLAVE: Agregar TickerProviderStateMixin para el TabController
// ==========================================================
class _FincaListEditScreenState extends State<FincaListEditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FincaService _fincaService = FincaService();
  String _query = '';
  
  // 💡 GlobalKeys para forzar el refresh de los widgets de lista hijos
  final GlobalKey<_FincasListViewState> _activeListKey = GlobalKey<_FincasListViewState>();
  final GlobalKey<_FincasListViewState> _inactiveListKey = GlobalKey<_FincasListViewState>();

  @override
  void initState() {
    super.initState();
    // Inicializar TabController con 2 pestañas
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================================
  // 🔄 Forzar Recarga en ambas pestañas (usado después de edición/creación)
  // ==========================================================
  void _forceRefreshAllLists() {
    // Llama al método _loadFincas() dentro del estado de cada widget de lista
    _activeListKey.currentState?._loadFincas();
    _inactiveListKey.currentState?._loadFincas();
    _mostrarSnackBar('Listas de fincas recargadas.');
  }

  // ==========================================================
  // ✏️ Navegar a Edición (Al presionar un ListTile)
  // ==========================================================
  void _navigateToEditScreen(int idFinca) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // Navega a la pantalla de Edición
        builder: (context) => FincaEditScreen(idFinca: idFinca),
      ),
    );

    // Si la edición fue exitosa
    if (result == true) {
      _forceRefreshAllLists(); // ✅ Recarga las dos listas
    }
  }
  
  // ==========================================================
  // ➕ Navegar a Creación (Al presionar el FAB)
  // ==========================================================
  void _navigateToCreateScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FincaCreateScreen(), // Asume que tienes esta pantalla
      ),
    );

    // Si la creación fue exitosa
    if (result == true) {
      _forceRefreshAllLists(); // ✅ Recarga las dos listas
      _mostrarSnackBar('✅ Nueva finca creada y listas actualizadas');
      // Opcional: Cambiar a la pestaña de habilitadas 
      _tabController.animateTo(0); 
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
        backgroundColor: isError ? Colors.red : GeoFloraTheme.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Editar Fincas"),
        backgroundColor: Colors.black.withOpacity(0.85),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefreshAllLists, 
          ),
        ],
        // ✅ AJUSTE CLAVE: Agregar TabBar al Bottom de la AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GeoFloraTheme.accent,
          labelColor: GeoFloraTheme.accent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Habilitadas"),
            Tab(text: "Inhabilitadas"),
          ],
        ),
      ),
      body: Column(
        children: [
          // ==============================
          // Barra de búsqueda (Se mantiene igual)
          // ==============================
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black54,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o abreviatura...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // ==============================
          // 🛑 TabBarView para las dos listas
          // ==============================
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Lista de Fincas HABILITADAS (is_active: true)
                _FincasListView(
                  key: _activeListKey,
                  isActive: true,
                  query: _query, // Pasar el query de búsqueda
                  onFincaTap: _navigateToEditScreen,
                ),
                // 2. Lista de Fincas INHABILITADAS (is_active: false)
                _FincasListView(
                  key: _inactiveListKey,
                  isActive: false,
                  query: _query, // Pasar el query de búsqueda
                  onFincaTap: _navigateToEditScreen,
                ),
              ],
            ),
          ),
        ],
      ),
      // ➕ Floating Action Button para CREAR Finca
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateScreen, 
        backgroundColor: GeoFloraTheme.accent,
        tooltip: 'Crear nueva finca',
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

// ============================================================
// 🧱 NUEVO WIDGET: _FincasListView (Maneja la carga, error y filtro de cada lista)
// ============================================================
class _FincasListView extends StatefulWidget {
  final bool isActive;
  final String query;
  final Function(int idFinca) onFincaTap;

  const _FincasListView({
    super.key,
    required this.isActive,
    required this.query,
    required this.onFincaTap,
  });

  @override
  State<_FincasListView> createState() => _FincasListViewState();
}

class _FincasListViewState extends State<_FincasListView> {
  final FincaService _fincaService = FincaService();
  // Future para gestionar el estado de carga
  late Future<List<dynamic>> _fincasFuture;

  @override
  void initState() {
    super.initState();
    // Iniciar la carga de datos al crearse el widget
    _loadFincas();
  }
  
  // 💡 Método para detectar cambios en el widget padre (principalmente el query)
  @override
  void didUpdateWidget(covariant _FincasListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo necesitamos forzar un build para re-aplicar el filtro de búsqueda local
    if (oldWidget.query != widget.query) {
      // Forzar un re-build para que FutureBuilder re-evalúe los datos filtrados localmente
      setState(() {}); 
    }
  }

  // ==========================================================
  // ⚙️ Cargar Fincas (Filtrando por Estado desde el Backend)
  // ==========================================================
  Future<void> _loadFincas() async {
    // Usamos setState para actualizar el Future y gatillar la recarga
    setState(() {
      // 🎯 AJUSTE CLAVE: Usar la nueva función getFincasByStatus
      _fincasFuture = _fincaService.getFincasByStatus(
        isActive: widget.isActive,
      );
    });
  }

  // ==========================================================
  // 🔍 Filtro Local (Aplicado solo en el frontend)
  // ==========================================================
  List<dynamic> _applyQueryFilter(List<dynamic> fincas) {
    if (widget.query.isEmpty) return fincas;

    final q = widget.query.toLowerCase();
    return fincas.where((f) {
      final nombre = (f['nombreFinca'] ?? '').toString().toLowerCase();
      final codigo = (f['codigoFinca'] ?? '').toString().toLowerCase();
      final abrev = (f['abreviaturaFinca'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || codigo.contains(q) || abrev.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Usar FutureBuilder para manejar los estados de carga y error
    return FutureBuilder<List<dynamic>>(
      future: _fincasFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: GeoFloraTheme.accent));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '🔴 Error al cargar fincas: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        final fincas = snapshot.data ?? [];
        final fincasFiltradas = _applyQueryFilter(fincas);
        final statusText = widget.isActive ? "Habilitadas" : "Inhabilitadas";

        if (fincasFiltradas.isEmpty && fincas.isNotEmpty) {
           return Center(
            child: Text(
              "No hay fincas $statusText que coincidan con \"${widget.query}\".",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          );
        }
        
        if (fincasFiltradas.isEmpty) {
          return Center(
            child: Text(
              "No hay fincas $statusText registradas.",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          );
        }

        // 🧱 Lista de Fincas
        return RefreshIndicator(
          onRefresh: _loadFincas, // Recarga la lista actual
          backgroundColor: Colors.black,
          color: GeoFloraTheme.accent,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: fincasFiltradas.length,
            itemBuilder: (context, index) {
              final finca = fincasFiltradas[index];
              final bool isActive = finca['is_active'] ?? true;
              final Color statusColor = isActive ? Colors.greenAccent : Colors.redAccent;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  onTap: () => widget.onFincaTap(finca['idFinca']),
                  leading: Icon(
                    Icons.landscape,
                    color: statusColor,
                  ),
                  title: Text(
                    finca['nombreFinca'] ?? 'Sin nombre',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Código: ${finca['codigoFinca'] ?? '-'}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Abreviatura: ${finca['abreviaturaFinca'] ?? '-'}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "Dirección: ${finca['direccionFinca'] ?? '-'}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      isActive ? "Habilitada" : "Inhabilitada",
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}