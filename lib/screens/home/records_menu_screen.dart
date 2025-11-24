// lib/screens/home/records_menu_screen.dart

import 'package:flutter/material.dart';
import '../home/theme/dark_theme.dart';
import '../fincas/finca_list_screen.dart';
import '../fincas/finca_create_screen.dart';
import '../fincas/finca_delete_screen.dart';
import '../fincas/finca_list_edit_screen.dart';
import '../areas/area_finca_selection_screen.dart';
// 🆕 Importación de la pantalla de selección de Área para Bloques
import '../bloques/bloque_area_selection_screen.dart';

// Importaciones necesarias para obtener el nombre y rol
import '../../services/api_service.dart'; // ⬅️ Asume esta ruta a tu ApiService

class RecordsMenuScreen extends StatefulWidget {
  final String mode; // "view" o "edit"

  const RecordsMenuScreen({super.key, required this.mode});

  @override
  State<RecordsMenuScreen> createState() => _RecordsMenuScreenState();
}

class _RecordsMenuScreenState extends State<RecordsMenuScreen> {
  final ApiService _apiService = ApiService();
  String _userName = '...';
  String _userRole = '...';

  // Colores del tema
  final Color _surfaceColor = GeoFloraTheme.surface;
  final Color _backgroundColor = GeoFloraTheme.background;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final name = await _apiService.getUserName();
    final role = await _apiService.getUserRole();

    if (mounted) {
      setState(() {
        _userName = name ?? 'Usuario Desconocido';
        _userRole = role ?? 'N/A';
      });
    }
  }

  // 1. Helper para el Título Principal del AppBar (más conciso)
  String _buildMainTitle() {
    return widget.mode == 'edit' ? 'MODO EDICIÓN' : 'MODO CONSULTA';
  }

  // 2. Helper para el Subtítulo (Rol y Alerta)
  Widget _buildSubtitleWidget(BuildContext context, bool isEdit) {
    // Texto general para ambos modos
    final userText = Text(
      '👤 $_userName | Rol: $_userRole',
      style: TextStyle(
        color: isEdit ? Colors.white70 : Colors.white,
        fontSize: isEdit ? 14 : 16,
        fontWeight: isEdit ? FontWeight.bold : FontWeight.normal,
      ),
    );

    if (isEdit) {
      // Mensaje de alerta en modo edición
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          userText,
          const SizedBox(height: 4),
          Text(
            '⚠️ Alerta: Todos los cambios serán registrados.',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 20, color: Colors.white24),
        ],
      );
    } else {
      // Solo información del usuario en modo vista
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          userText,
          const Divider(height: 20, color: Colors.white24),
        ],
      );
    }
  }

  // 4. Función de navegación a la página principal
  void _goToHome(BuildContext context) {
    // Esto asume que la pantalla principal es el "pop" inmediato.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == 'edit';

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        // Título simplificado para caber en la AppBar
        title: Text(
          _buildMainTitle(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isEdit ? Colors.redAccent : Colors.white,
          ),
        ),
        // Ícono más llamativo
        leading: Icon(
          isEdit ? Icons.security_update_warning_sharp : Icons.visibility_outlined,
          color: isEdit ? Colors.redAccent : Colors.lightBlueAccent,
          size: 32,
        ),
        toolbarHeight: kToolbarHeight, 
        backgroundColor: Colors.black.withOpacity(0.7),
        
        // 🔥 AÑADIR BOTÓN DE ACCIÓN (CASITA)
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.amberAccent, size: 28),
            tooltip: 'Ir a Inicio',
            onPressed: () => _goToHome(context),
          ),
          const SizedBox(width: 8), // Pequeño espacio a la derecha
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Subtítulo con Rol y Nombre
          _buildSubtitleWidget(context, isEdit),

          // ===============================================
          // 🏞️ MÓDULO FINCAS
          // ===============================================
          _buildCard(
            context,
            icon: Icons.agriculture_outlined,
            color: Colors.greenAccent,
            title: "Fincas",
            subtitle: isEdit
                ? "Crear, modificar o inhabilitar fincas."
                : "Consultar información de las fincas.",
            onTap: () {
              if (isEdit) {
                // Modo Edición: Abre el menú de acciones de Fincas
                _abrirMenuFincas(context);
              } else {
                // Modo Consulta: Va directamente a la lista de Fincas
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FincaListScreen(),
                  ),
                );
              }
            },
          ),

          // ===============================================
          // 📍 MÓDULO ÁREAS (SOLO en Modo Edición)
          // ===============================================
          if (isEdit) 
            _buildCard(
              context,
              icon: Icons.location_on_outlined,
              color: Colors.blueAccent,
              title: "Áreas",
              subtitle: "Seleccionar una finca para crear o editar sus áreas.",
              onTap: () {
                // En modo edición, lleva a la selección de finca para gestionar áreas
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AreaFincaSelectionScreen(mode: widget.mode),
                  ),
                );
              },
            ),

          // ===============================================
          // 🧱 MÓDULO BLOQUES (SOLO en Modo Edición)
          // ===============================================
          if (isEdit)
            _buildCard(
              context,
              icon: Icons.grid_on,
              color: Colors.orangeAccent,
              title: "Bloques",
              subtitle: "Seleccionar un área para crear, editar o gestionar sus bloques.",
              onTap: () {
                // Navega a la pantalla de selección de Área para luego gestionar Bloques
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BloqueAreaSelectionScreen(),
                  ),
                );
              },
            ),
          
          // Aquí puedes agregar más módulos
        ],
      ),
    );
  }
  
  // =======================================
  // 🧱 HELPER: BUILD CARD
  // =======================================
  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    // Usamos el color de superficie de GeoFloraTheme
    return Card(
      color: _surfaceColor.withOpacity(0.7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 20)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  // =======================================
  // ✅ Menú inferior de acciones sobre Fincas
  // =======================================
  void _abrirMenuFincas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // Usamos el color de fondo de GeoFloraTheme
      backgroundColor: _surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.add, color: GeoFloraTheme.accent),
                title: const Text("Registrar Nueva Finca",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FincaCreateScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.amberAccent),
                title: const Text("Editar Fincas",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // ✅ Abrir lista de edición de fincas
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FincaListEditScreen(), // ✅ CORRECTO
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: const Text("INABILITAR O HABILITAR Fincas",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FincaDeleteScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}