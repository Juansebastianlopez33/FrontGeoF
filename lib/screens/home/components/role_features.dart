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
  // 👤 USUARIO COMÚN
  // ==========================================================
  if (r == 'user') {
    return [
      feature(
        'Ver Registros',
        'Consulta los registros disponibles, como las fincas.',
        Icons.visibility_outlined,
        GeoFloraTheme.accent,
        const RecordsMenuScreen(mode: 'view'),
      ),
    ];
  }

  // ==========================================================
  // 🧩 DBADMIN
  // ==========================================================
  if (r == 'dbadmin') {
    return [
      feature(
        'Ver Registros',
        'Consulta los registros existentes.',
        Icons.list_alt_outlined,
        GeoFloraTheme.accent,
        const RecordsMenuScreen(mode: 'view'),
      ),
      feature(
        'Editar Registros',
        'Edita, crea o inhabilita registros del sistema.',
        Icons.edit_document,
        GeoFloraTheme.gold,
        const RecordsMenuScreen(mode: 'edit'),
      ),
    ];
  }

  // ==========================================================
  // 👑 ADMIN PRINCIPAL
  // ==========================================================
  if (r == 'admin') {
    return [
      feature(
        'Ver Registros',
        'Visualiza todos los registros del sistema.',
        Icons.folder_shared_outlined,
        GeoFloraTheme.accent,
        const RecordsMenuScreen(mode: 'view'),
      ),
      feature(
        'Editar Registros',
        'Gestiona, crea o modifica registros del sistema.',
        Icons.manage_accounts_outlined,
        GeoFloraTheme.gold,
        const RecordsMenuScreen(mode: 'edit'),
      ),
    ];
  }

  return [];
}
