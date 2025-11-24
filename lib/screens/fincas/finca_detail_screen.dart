// lib/screens/finca/finca_detail_screen.dart

import 'package:flutter/material.dart';
import '../home/theme/dark_theme.dart';
import '../../services/finca_service.dart';
// ⚠️ IMPORTACIÓN REQUERIDA: para la navegación a la lista de áreas
import '../areas/area_list_screen.dart'; 

class FincaDetailScreen extends StatefulWidget {
  final int idFinca;

  const FincaDetailScreen({super.key, required this.idFinca});

  @override
  State<FincaDetailScreen> createState() => _FincaDetailScreenState();
}

class _FincaDetailScreenState extends State<FincaDetailScreen> {
  final FincaService _fincaService = FincaService();
  Map<String, dynamic>? finca;
  List<dynamic> agronomos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carga finca + lista de agrónomos
  Future<void> _loadData() async {
    final fincaResult = await _fincaService.getFincaDetails(widget.idFinca);
    final agronomosList = await _fincaService.getAllAgronomos();

    if (mounted) {
      setState(() {
        finca = fincaResult['success'] ? fincaResult['data'] : null;
        agronomos = agronomosList;
        isLoading = false;
      });
    }
  }

  // Busca el nombre del agrónomo según su cédula/id
  String _getAgronomoNombre(String? cedula) {
    if (cedula == null || cedula.isEmpty) return "—";
    final match = agronomos.firstWhere(
      (a) => a['cedula'].toString() == cedula.toString(),
      orElse: () => {},
    );
    if (match.isEmpty) return "No encontrado";
    return match['nombre'] ?? "Sin nombre";
  }
  
  // 🧭 FUNCIÓN: Navegación al presionar el botón de Áreas
  void _navigateToAreaList() {
    if (finca == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pasar el idFinca y nombreFinca a AreaListScreen
        builder: (context) => AreaListScreen(
          initialFincaId: widget.idFinca.toString(), 
          initialFincaName: finca!['nombreFinca'] ?? 'Finca',
        ), 
      ),
    );
  }

  // ==========================================================
  // 🧭 FUNCIÓN NUEVA: Navegación a la Página de Inicio
  // ==========================================================
  void _navigateToMainList() {
    // 🎯 MODIFICACIÓN CLAVE: Esto borra todas las rutas en la pila 
    // hasta llegar a la primera ruta (generalmente la Home/MainScreen).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // Imagen de la finca (ajustada y sin ocupar media pantalla)
  Widget _buildFincaImage() {
    final imageUrl = finca!['url_imagen'];
    final double screenWidth = MediaQuery.of(context).size.width;
    final double imageHeight = screenWidth * 0.35; // más pequeña (~35% del ancho)

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: imageHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.white38,
          size: 60,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: imageHeight,
              color: Colors.black26,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: imageHeight,
            color: Colors.black38,
            alignment: Alignment.center,
            child: const Icon(Icons.image_not_supported,
                color: Colors.white38, size: 60),
          ),
        ),
      ),
    );
  }
  
  // 🆕 WIDGET NUEVO: El botón de Áreas
  Widget _buildAreasButton(Color themeAccent) {
    // Obtener el conteo de áreas (si existe, sino 0)
    final totalAreas = finca!['estructura_descendiente']['total_areas']?.toString() ?? '0';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Botón Grande
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _navigateToAreaList, // Llama a la función de navegación
              icon: const Icon(Icons.grass, size: 24),
              label: const Text(
                "Ver Áreas",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeAccent, // Color de acento
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
          ),
          // 2. Conteo de Áreas debajo del botón
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              "Total de Áreas: $totalAreas",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 10), // Espacio para separar
        ],
      ),
    );
  }

  // ==========================================================
  // 🧱 NUEVOS HELPERS PARA LA TABLA DE DETALLES
  // ==========================================================

  // 🆕 WIDGET: Muestra una fila de detalle con estilo condicional
  Widget _buildDetailRow(String label, String? value, Color themeAccent, {bool highlight = false, IconData? icon}) {
    final displayValue = value ?? "—";
    
    // Estilo para el valor: Resalta si 'highlight' es true
    final TextStyle valueStyle = TextStyle(
      color: highlight ? themeAccent : Colors.white,
      fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
      fontSize: highlight ? 16 : 14,
    );

    // Aplicar UPPERCASE al nombre de la finca si está resaltado
    final String finalValue = highlight && label.contains("Nombre") 
        ? displayValue.toUpperCase() 
        : displayValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono opcional
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon, color: themeAccent.withOpacity(0.7), size: 20),
            ),
          // Etiqueta (Label)
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
          // Valor (Value)
          Expanded(
            flex: 3,
            child: Text(
              finalValue,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 WIDGET: Contenedor tipo tarjeta para la información principal
  Widget _buildFincaDetailsCard(Color themeAccent) {
    final agronomosName = _getAgronomoNombre(finca!['agronomoEncargado_id']);

    return Card(
      // Usamos GeoFloraTheme.surface con opacidad para distinguirlo del fondo
      color: GeoFloraTheme.surface.withOpacity(0.9), 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: themeAccent.withOpacity(0.4), width: 1),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre de Finca (Resaltado y en MAYÚSCULAS)
            _buildDetailRow("Nombre de Finca", finca!['nombreFinca'], themeAccent, highlight: true, icon: Icons.grass),
            const Divider(color: Colors.white12, height: 1),
            
            _buildDetailRow("Código", finca!['codigoFinca'], themeAccent, icon: Icons.tag),
            const Divider(color: Colors.white12, height: 1),
            
            _buildDetailRow("Abreviatura", finca!['abreviaturaFinca'], themeAccent, icon: Icons.short_text),
            const Divider(color: Colors.white12, height: 1),
            
            _buildDetailRow("Dirección", finca!['direccionFinca'], themeAccent, icon: Icons.location_on_outlined),
            const Divider(color: Colors.white12, height: 1),
            
            // Agrónomo Encargado (Resaltado)
            _buildDetailRow("Agrónomo Encargado", agronomosName, themeAccent, highlight: true, icon: Icons.person_pin),
          ],
        ),
      ),
    );
  }
  
  // ==========================================================
  // 🧱 WIDGET ORIGINAL (Renombrado para la estructura)
  // ==========================================================

  // ✏️ RENOMBRADO: De _buildInfoRow a _buildStructureRow para diferenciar el uso
  Widget _buildStructureRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? "—",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final themeAccent = GeoFloraTheme.accent; // Obtener color de acento

    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Detalles de la Finca"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      // 🆕 BOTÓN FLOTANTE: Navega a la página de inicio
      floatingActionButton: finca != null ? FloatingActionButton.extended(
        onPressed: _navigateToMainList, // ⬅️ Usa la nueva
        label: const Text('inicio'),
        icon: const Icon(Icons.home),
        backgroundColor: themeAccent,
      ) : null,
      // ---------------------------------------------
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : finca == null
              ? const Center(
                  child: Text(
                    "No se pudieron cargar los detalles de la finca.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildFincaImage(),
                        const SizedBox(height: 20),

                        // ➡️ CAMBIO CLAVE: Usar el nuevo widget de tarjeta para la información principal
                        _buildFincaDetailsCard(themeAccent),

                        const Divider(color: Colors.white24, height: 40),

                        Text(
                          "Estructura de la Finca",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Usar el botón de áreas en lugar de la fila de áreas
                        _buildAreasButton(themeAccent),

                        // Usar el helper renombrado para la estructura descendiente
                        _buildStructureRow("Bloques",
                            "${finca!['estructura_descendiente']['total_bloques']}"),
                        _buildStructureRow("Naves",
                            "${finca!['estructura_descendiente']['total_naves']}"),
                        _buildStructureRow("Camas",
                            "${finca!['estructura_descendiente']['total_camas']}"),
                      ],
                    ),
                  ),
    );
  }
}