// lib/screens/home/components/feature_card.dart (MODIFICADO - Módulo Táctil)

import 'package:flutter/material.dart';
import '../theme/dark_theme.dart'; // Ruta correcta al tema

class FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;

  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      // 1. Usamos la nueva tarjeta de elevación
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15), 
        decoration: BoxDecoration(
          color: GeoFloraTheme.card, // Usamos el color de la tarjeta (Nivel 2)
          borderRadius: BorderRadius.circular(12), 
          // 2. Sombra sutil para simular elevación neumórfica oscura
          boxShadow: [
            BoxShadow(
              color: GeoFloraTheme.surface.withOpacity(0.5), // Sombra más suave
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Contrasombra ligera
              blurRadius: 4,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        
        // 3. Estructura mejorada: Icono a la izquierda, Texto apilado a la derecha
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Alinear a la izquierda
          children: [
            // 4. Ícono más visible y prominente
            Icon(icon, size: 30, color: color), 
            const SizedBox(width: 12),
            
            // 5. Contenedor de Texto apilado (Title y Subtitle)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                    // 6. AUMENTO CRÍTICO de tamaño de fuente
                    style: const TextStyle(
                      color: GeoFloraTheme.textLight,
                      fontSize: 14, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // 7. Subtítulo en tono atenuado
                      color: GeoFloraTheme.textMuted, 
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}