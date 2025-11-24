// lib/screens/area/area_detail_screen.dart

import 'package:flutter/material.dart';
import '../../services/area_service.dart';
// Asegúrate de la ruta correcta a tu tema
import '../home/theme/dark_theme.dart'; 
// 🆕 IMPORTACIÓN REQUERIDA para la navegación a Detalles de Finca
import '../fincas/finca_detail_screen.dart'; 
// ✅ IMPORTACIÓN REQUERIDA para la navegación a Detalles de Bloque
import '../bloques/bloque_list_screen.dart'; 

class AreaDetailScreen extends StatefulWidget {
  // Argumento requerido: el ID del área a mostrar
  final int idArea;

  const AreaDetailScreen({super.key, required this.idArea});

  @override
  State<AreaDetailScreen> createState() => _AreaDetailScreenState();
}

class _AreaDetailScreenState extends State<AreaDetailScreen> {
  final AreaService _areaService = AreaService();
  
  Map<String, dynamic>? _areaData;
  bool _isLoading = true;
  String? _errorMessage;

  // Constantes de Estilo
  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;
  
  @override
  void initState() {
    super.initState();
    _fetchAreaDetails();
  }

  // ==========================================================
  // ⚙️ Cargar Detalles del Área
  // ==========================================================
  Future<void> _fetchAreaDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _areaService.getAreaDetails(widget.idArea);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        // La clave 'data' es la correcta según tu service
        _areaData = result['data']; 
      } else {
        _errorMessage = result['message'] ?? "Error al cargar los detalles del área.";
      }
    });
  }
  
  // ==========================================================
  // 🧭 Navegación a Finca
  // ==========================================================
  void _navigateToFincaDetails(int idFinca) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // Asegúrate de que FincaDetailScreen acepte idFinca como argumento
        builder: (context) => FincaDetailScreen(idFinca: idFinca),
      ),
    );
  }

  // 🧭 Navegación a Bloques
  void _navigateToBlockList() {
    // ✅ IMPLEMENTACIÓN CORREGIDA: Navegación a la lista de bloques
    if (_areaData == null) return;
    
    final idArea = widget.idArea.toString(); // El BloqueListScreen espera el ID como String
    final areaName = _areaData!['numeroArea']?.toString() ?? 'N/A'; // Usamos el número/nombre del área
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BloqueListScreen(
          initialAreaId: idArea, 
          initialAreaName: 'Bloques del Área N° $areaName', 
        ),
      ),
    );
  }

  // ==========================================================
  // 🧭 Navegación a la Página de Inicio (NUEVA LÓGICA)
  // ==========================================================
  void _navigateToMainList() {
    // 🎯 MODIFICACIÓN CLAVE: Esto borra todas las rutas en la pila 
    // hasta llegar a la primera ruta (generalmente la Home/MainScreen).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }


  // ==========================================================
  // 🧱 Build
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        title: Text(_areaData?['nombreArea'] ?? "Detalles del Área"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: _buildBody(),
      // 🔄 Botón flotante que ahora navega a la página de inicio
      floatingActionButton: _areaData != null ? FloatingActionButton.extended(
        onPressed: _navigateToMainList,
        label: const Text('Ir a Página de Inicio'),
        icon: const Icon(Icons.home), // Cambiado el icono a 'home'
        backgroundColor: _themeAccent,
      ) : null,
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
            '🔴 Error: $_errorMessage',
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_areaData == null) {
      return const Center(
        child: Text(
          "No se encontraron datos para esta área.",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    
    final numeroArea = _areaData!['numeroArea']?.toString() ?? 'N/A';
    
    // Extracción de Jefe y Finca
    final jefeAreaNombre = _areaData!['jefeDeArea_nombre'] ?? 'Sin asignar'; 
    final jefeAreaCedula = _areaData!['jefeDeArea_id'] ?? 'N/A';
    
    final fincaNombre = _areaData!['finca_nombre'] ?? 'N/A';
    final idFinca = _areaData!['idFinca'] as int?; 
    
    final isActive = _areaData!['is_active'] == true; 
    
    // Obtener la estructura jerárquica
    final estructura = _areaData!['estructura_descendiente'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0, bottom: 100.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título principal con estado (Se mantiene)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Área: $numeroArea",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusChip(isActive), // Widget de Chip para el estado
            ],
          ),
          const SizedBox(height: 20),
          
          // ===============================================
          // 🆕 Tarjeta Única de Detalles
          // ===============================================
          _buildInfoCard(
            title: "Detalles del Área",
            icon: Icons.details,
            children: [
              // Finca (Clickable)
              _buildClickableDetailRow(
                label: "Finca:", 
                value: fincaNombre,
                onTap: idFinca != null 
                  ? () => _navigateToFincaDetails(idFinca) 
                  : null,
              ),
              // Jefe de Área
              _buildDetailRow("JEFE:", jefeAreaNombre, isBoldValue: true),
            ],
          ),

          const SizedBox(height: 20),
          
          // ===============================================
          // 🆕 Jerarquía (Bloques, Naves, Camas) con Botón
          // ===============================================
          _buildHierarchyCard(estructura),
          
        ],
      ),
    );
  }

  // ==========================================================
  // 🧱 Helpers UI
  // ==========================================================

  Widget _buildStatusChip(bool isActive) {
    final String text = isActive ? 'Habilitada' : 'Inhabilitada';
    final Color color = isActive ? _themeAccent : Colors.redAccent; 
    
    return Chip(
      label: Text(text, style: TextStyle(color: isActive ? Colors.black : Colors.white)),
      backgroundColor: color,
      avatar: Icon(isActive ? Icons.check_circle_outline : Icons.cancel_outlined, color: isActive ? Colors.black : Colors.white),
      elevation: 4,
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      color: Colors.black.withOpacity(0.3), // Fondo semitransparente oscuro
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _themeAccent.withOpacity(0.3)),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: _themeAccent, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: _themeAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Widget para la estructura jerárquica con botón
  Widget _buildHierarchyCard(Map<String, dynamic> structure) {
    // Extracción segura de datos
    final bloques = structure['total_bloques'] ?? 0;
    final naves = structure['total_naves'] ?? 0;
    final camas = structure['total_camas'] ?? 0;

    return _buildInfoCard(
      title: "Estructura del Area",
      icon: Icons.layers_outlined,
      children: [
        // 🆕 Botón para ir a Bloques
        _buildGoToBlocksButton(), 
        const Divider(color: Colors.white12, height: 20),
        _buildDetailRow("Bloques:", bloques.toString()),
        _buildDetailRow("Naves:", naves.toString()),
        _buildDetailRow("Camas:", camas.toString()),
      ],
    );
  }
  
  // 🆕 Botón de navegación a bloques
  Widget _buildGoToBlocksButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton.icon(
        onPressed: _navigateToBlockList, // Llama a la función de navegación corregida
        icon: const Icon(Icons.apartment, color: Colors.black),
        label: const Text(
          "Ver Bloques",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeAccent, // Usar el color de acento
          minimumSize: const Size(double.infinity, 45), // Ancho completo
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }


  // 💡 Widget de fila de detalle con opción para negrita en el valor
  Widget _buildDetailRow(String label, String value, {bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label", 
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 Widget para filas de detalles clickables (como la Finca)
  Widget _buildClickableDetailRow({
    required String label, 
    required String value, 
    required VoidCallback? onTap,
  }) {
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
            child: InkWell( // Usa InkWell para efecto visual y tap
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value,
                  style: TextStyle(
                    // Color de acento si es clickable, blanco si no
                    color: onTap != null ? _themeAccent : Colors.white, 
                    fontWeight: FontWeight.bold, // Siempre negrita para el nombre de la finca
                    // Subrayado para indicar que es un enlace
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
}