import 'package:flutter/material.dart';
import '../../home/theme/dark_theme.dart';
import '../../home/records_menu_screen.dart';

List<Map<String, dynamic>> getFeaturesForRole(String role) {
  Map<String, dynamic> feature(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return {
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'color': color,
      'screen': screen,
    };
  }

  final r = role.toLowerCase();

  // ==========================================================
  // 👤 USUARIO COMÚN (ROL: USER)
  // ==========================================================
  if (r == 'user') {
    return [
      feature(
        'Consultar Datos',
        // Subtítulo más corto
        'Explorar la información disponible (Fincas, Áreas, etc.).',
        Icons.visibility_outlined,
        GeoFloraTheme.accent,
        const RecordsMenuScreen(mode: 'view'),
      ),
    ];
  }

  // ==========================================================
  // 🧩 ADMINISTRADOR DE BASE DE DATOS (ROL: DBADMIN)
  // ==========================================================
  if (r == 'dbadmin') {
    return [
      feature(
        'Consultar Datos',
        // Subtítulo más corto
        'Visualizar todos los registros del sistema.',
        Icons.list_alt_outlined,
        GeoFloraTheme.accent,
        const RecordsMenuScreen(mode: 'view'),
      ),
      feature(
        'Gestión de Registros',
        // Título más explícito para la edición
        'Crear, editar o inhabilitar entradas en la base de datos.',
        Icons.edit_document,
        GeoFloraTheme.gold,
        const RecordsMenuScreen(mode: 'edit'),
      ),
    ];
  }

  // ==========================================================
  // 👑 ADMINISTRADOR PRINCIPAL (ROL: ADMIN)
  // ==========================================================
  if (r == 'admin') {
    return [
      feature(
        'Consultar Datos',
        // Subtítulo más corto
        'Visualización de toda la información del sistema.',
        Icons.folder_shared_outlined,
        GeoFloraTheme.accent,
        const RecordsMenuScreen(mode: 'view'),
      ),
      feature(
        'Gestión de Registros',
        // Título más explícito para la edición
        'Administrar la creación, modificación e inhabilitación de datos.',
        Icons.manage_accounts_outlined,
        GeoFloraTheme.gold,
        const RecordsMenuScreen(mode: 'edit'),
      ),
    ];
  }

  return [];
}