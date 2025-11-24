import 'package:flutter/material.dart';

/// 🎨 Tema Oscuro Global de GeoFlora (Estilo de Profundidad - Dark UI 2.0)
class GeoFloraTheme {
  
  // 1. FONDO (BACKGROUND): Tono muy oscuro y sutilmente azulado/verdoso para profundidad total.
  static const Color background = Color(0xFF0D1B2A); 
  
  // 2. SUPERFICIE (SURFACE): Primer nivel de elevación (AppBar, grandes paneles).
  static const Color surface = Color(0xFF1B263B); 

  // 3. TARJETA/MODULO (CARD): Segundo nivel de elevación, más brillante y flotante (FeatureCards, ListTiles).
  static const Color card = Color(0xFF283850); 

  // 4. ACENTO PRIMARIO (Éxito/Datos): El foco interactivo de la app.
  static const Color accent = Color(0xFF6FCF97); 
  
  // 5. ACENTO SECUNDARIO (Alerta/Gold): Para métricas críticas o acciones de énfasis.
  static const Color gold = Color(0xFFFFD700); // Dorado brillante para alto contraste
  
  // 6. COLORES DE TEXTO
  static const Color textLight = Colors.white; // Alto contraste
  static const Color textMuted = Color(0xFFB0BEC5); // Gris azulado, para subtítulos y muted text

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background, // Fondo de la página
      primaryColor: accent,
      cardColor: card, // Color base para widgets Card/FeatureCard
      
      // ⚠️ NOTA: Si usas una fuente como 'Inter' o 'Poppins' en tu proyecto, actívala aquí.
      // fontFamily: 'Inter', 

      // 1. APPBARTHEME: Usa el color de la Superficie (Elevation 1)
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 4, // Un poco más de sombra para separarse del fondo
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: const TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // 2. TEXTTHEME: Uso de nuestro sistema de texto unificado
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: textLight), // Texto principal
        bodyMedium: const TextStyle(color: textMuted), // Texto secundario (Body)
        bodySmall: TextStyle(color: textMuted.withOpacity(0.7)), // Texto muy sutil
        titleLarge: const TextStyle(color: textLight, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(color: textLight, fontWeight: FontWeight.w500),
      ),
      
      // 3. INPUTS: Para que los campos de formulario sigan la misma estética
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface, // El fondo del input en Elevation 1
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: TextStyle(color: textMuted.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, 
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 2), // Acento al enfocar
        ),
      ),
      
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black, // Asegurar el contraste
      ),
    );
  }
}