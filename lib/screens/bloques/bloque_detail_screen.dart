// lib/screens/bloque/bloque_detail_screen.dart

import 'package:flutter/material.dart';
import '../../services/bloques_service.dart'; // Service to fetch Bloque data
// Ensure the correct path to your theme
import '../home/theme/dark_theme.dart';
// Importaciones de pantallas de navegación
import '../areas/area_detail_screen.dart'; // ✅ AreaDetailScreen confirmado
import '../fincas/finca_detail_screen.dart'; // ✅ FincaDetailScreen confirmado
// ⚠️ IMPORTAR: import '../naves/nave_list_screen.dart'; // Pantalla para la lista de Naves

class BloqueDetailScreen extends StatefulWidget {
  // Required argument: the ID of the block to display
  final int idBloque;

  const BloqueDetailScreen({super.key, required this.idBloque});

  @override
  State<BloqueDetailScreen> createState() => _BloqueDetailScreenState();
}

class _BloqueDetailScreenState extends State<BloqueDetailScreen> {
  final BloquesService _bloqueService = BloquesService();
  
  Map<String, dynamic>? _bloqueData;
  bool _isLoading = true;
  String? _errorMessage;

  // Style Constants
  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;
  
  @override
  void initState() {
    super.initState();
    _cargarDetalleBloque();
  }

  // ==========================================================
  // LOAD BLOCK DETAILS
  // ==========================================================
  Future<void> _cargarDetalleBloque() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _bloqueService.getBloqueDetails(widget.idBloque);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _bloqueData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? "Error al cargar los detalles del bloque.";
        _isLoading = false;
      });
    }
  }

  // ==========================================================
  // NAVIGATION METHODS
  // ==========================================================
  
  // 🆕 0. Navegación a la página principal (Home)
  void _navigateToHomeScreen() {
    // Vuelve a la primera ruta en la pila de navegación (la página principal/Home)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 1. Navegación a la lista de Naves
  void _navigateToNavesListScreen() {
    if (_bloqueData == null) return;
    
    // Obtiene el ID del Bloque para pasarlo a la lista de Naves
    final rawIdBloque = _bloqueData!['idBloque'];
    final idBloque = rawIdBloque is int ? rawIdBloque : int.tryParse(rawIdBloque?.toString() ?? '') ?? 0;
    
    if (idBloque > 0) {
      // ⚠️ Descomentar y ajustar la ruta a la pantalla de Naves real cuando esté lista
      /*
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NaveListScreen(idBloque: idBloque), 
        ),
      );
      */
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navegando a la lista de Naves (a implementar)...')),
      );
    }
  }


  
  // 2. Navegación a Área Padre (Usando el ID)
  void _navigateToAreaParent() {
    if (_bloqueData == null) return;
    
    // Extrae el ID del Área. Se asume que viene en el objeto principal o en el objeto anidado.
    final rawIdArea = _bloqueData!['idArea'] ?? _bloqueData!['area_padre']?['idArea'];
    final idArea = rawIdArea is int 
        ? rawIdArea as int 
        : int.tryParse(rawIdArea?.toString() ?? '') ?? 0;
    
    if (idArea > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AreaDetailScreen(idArea: idArea), // Navega con el ID
        ),
      );
    }
  }
  
  // 3. Navegación a Finca Padre (Usando el ID)
  void _navigateToFincaParent() {
    if (_bloqueData == null) return;
    
    // Extrae el ID de la Finca (búsqueda robusta en la jerarquía).
    final rawIdFinca = _bloqueData!['idFinca'] 
        ?? _bloqueData!['area_padre']?['idFinca'] 
        ?? _bloqueData!['finca_abuelo']?['idFinca'];
        
    final idFinca = rawIdFinca is int 
        ? rawIdFinca as int 
        : int.tryParse(rawIdFinca?.toString() ?? '') ?? 0;
    
    if (idFinca > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FincaDetailScreen(idFinca: idFinca), // Navega con el ID
        ),
      );
    }
  }
  
  // ==========================================================
  // WIDGET HELPERS (Omitidos para brevedad, asumo que existen)
  // ==========================================================
  
  Widget _buildDetailRow({
    required String label, 
    required String value,
    Color valueColor = Colors.white,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2, 
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: valueColor, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableDetailRow({
    required String label, 
    required String value, 
    required VoidCallback? onTap,
  }) {
    // Implementación de _buildClickableDetailRow (de AreaDetailScreen)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2, 
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell( 
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value,
                  style: TextStyle(
                    color: onTap != null ? _themeAccent : Colors.white, 
                    fontWeight: FontWeight.bold,
                    decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    String title = 'Detalle de Bloque';
    if (_bloqueData != null) {
      final numero = _bloqueData!['numeroBloque']?.toString() ?? 'N/A';
      title = 'Bloque N° $numero';
    }

    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black.withOpacity(0.7),
        actions: [
          // 🛑 Eliminado el botón de edición (Icons.edit)
          // ✅ Botón para ir a la página principal (Icons.home)
          IconButton(
            onPressed: _navigateToHomeScreen, 
            icon: const Icon(Icons.home, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: _themeAccent))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _buildBloqueDetails(),
      // Botón de acción flotante para Navegar a Naves
      floatingActionButton: _bloqueData != null ? FloatingActionButton.extended(
        onPressed: _navigateToNavesListScreen,
        backgroundColor: _themeAccent,
        icon: const Icon(Icons.list_alt, color: Colors.white),
        // Muestra el número del bloque en el botón (Requerimiento 1)
        label: Text('Naves del Bloque ${_bloqueData!['numeroBloque'] ?? ''}', style: const TextStyle(color: Colors.white)),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ==========================================================
  // DETAILS STRUCTURE (Requerimientos 2 y 3)
  // ==========================================================
  Widget _buildBloqueDetails() {
    if (_bloqueData == null) return Container();

    final data = _bloqueData!;
    
    // Extracción de datos robusta para el DISPLAY (NO IDs)
    final numeroBloque = data['numeroBloque']?.toString() ?? 'N/A';
    
    // Buscamos Area/Finca data en la jerarquía (area_padre/finca_abuelo) o en campos planos.
    final areaNumero = (data['area_padre']?['numeroArea'] ?? data['area_numeroArea'])?.toString() ?? 'N/A';
    final fincaNombre = (data['finca_abuelo']?['nombreFinca'] ?? data['finca_nombreFinca'])?.toString() ?? 'N/A'; 

    // Conteo de descendientes (Asumimos que el backend provee los 4 conteos)
    final totalNavesActivas = data['total_naves_activas']?.toString() ?? '0'; 
    final totalCamasActivas = data['total_camas_activas']?.toString() ?? '0'; 
    final totalNavesInactivas = data['total_naves_inactivas']?.toString() ?? '0'; 
    final totalCamasInactivas = data['total_camas_inactivas']?.toString() ?? '0'; 

    final isEnabled = data['is_active'] == true;
    final estado = isEnabled ? 'Habilitado' : 'Inhabilitado';
    final colorEstado = isEnabled ? _themeAccent : Colors.redAccent;
    
    // Se revisa si existe el ID para habilitar el onTap en las filas clickables
    final canNavigateToFinca = (data['idFinca'] ?? data['area_padre']?['idFinca'] ?? data['finca_abuelo']?['idFinca']) != null;
    final canNavigateToArea = (data['idArea'] ?? data['area_padre']?['idArea']) != null;


    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0), // Espacio para el FAB
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // =================================================
          // JERARQUÍA (Requerimiento 3)
          // =================================================
          Text(
            'Bloque N°: $numeroBloque',
            style: TextStyle(
              color: _themeAccent,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          
          const SizedBox(height: 5),
          // Jerarquía completa
          Text('Pertenece al Área N°: $areaNumero', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text('De la Finca: $fincaNombre', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          
          const Divider(height: 30, color: Colors.white12),

          // =================================================
          // ENLACES Y ESTADO
          // =================================================
          Card(
            color: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estado General del Bloque
                  _buildDetailRow(
                    label: 'Estado General',
                    value: estado,
                    valueColor: colorEstado,
                  ),
                  
                  const Divider(color: Colors.white12, height: 20),

                  // Enlace a la Finca Padre (Clickable con redirección por ID)
                  _buildClickableDetailRow(
                    label: 'Ver Detalles de Finca',
                    value: fincaNombre,
                    onTap: canNavigateToFinca ? _navigateToFincaParent : null, 
                  ),

                  // Enlace al Área Padre (Clickable con redirección por ID)
                  _buildClickableDetailRow(
                    label: 'Ver Detalles de Área',
                    value: 'Área N° $areaNumero',
                    onTap: canNavigateToArea ? _navigateToAreaParent : null, 
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // =================================================
          // ESTRUCTURAS HABILITADAS (Requerimiento 2 - Activas)
          // =================================================
          const Text(
            'Estructuras Habilitadas (Activas)',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.green, height: 10),
          
          Card(
            color: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Naves Activas',
                    value: totalNavesActivas,
                    valueColor: _themeAccent,
                    icon: Icons.warehouse,
                  ),
                  _buildDetailRow(
                    label: 'Camas Activas',
                    value: totalCamasActivas,
                    valueColor: _themeAccent,
                    icon: Icons.bed,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // =================================================
          // ESTRUCTURAS INHABILITADAS (Requerimiento 2 - Inactivas)
          // =================================================
          const Text(
            'Estructuras Inhabilitadas',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.redAccent, height: 10),

          Card(
            color: Colors.black26,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    label: 'Naves Inactivas',
                    value: totalNavesInactivas,
                    valueColor: Colors.redAccent,
                    icon: Icons.warehouse,
                  ),
                  _buildDetailRow(
                    label: 'Camas Inactivas',
                    value: totalCamasInactivas,
                    valueColor: Colors.redAccent,
                    icon: Icons.bed,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40), 
        ],
      ),
    );
  }
}