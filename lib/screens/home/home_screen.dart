import 'package:flutter/material.dart';
import '../profile_screen.dart';
import 'components/feature_card.dart';
import 'components/role_features.dart';
import 'theme/dark_theme.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;
  const HomeScreen({super.key, required this.userRole});

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    return baseSize * (screenWidth / 400.0);
  }

  // 1. 🛑 ELIMINAMOS _buildResponsiveImage
  // 2. 🛑 ELIMINAMOS _buildSecondaryImage

  // 3. 📊 NUEVO: Dashboard Zero (Panel de métricas rápidas)
  Widget _buildDashboardZero(BuildContext context, double titleSize) {
    // ⚠️ NOTA: El contenido de esta tarjeta debe ser dinámico (datos reales). Por ahora es estático.
    return Container(
      margin: const EdgeInsets.only(top: 15.0, bottom: 30.0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GeoFloraTheme.surface, // Primer nivel de elevación
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: GeoFloraTheme.background.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen Rápido',
            style: TextStyle(
              fontSize: titleSize.clamp(16.0, 20.0),
              fontWeight: FontWeight.w600,
              color: GeoFloraTheme.textMuted,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Métrica Clave 1
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '18', // ⚠️ Dato Dinámico: Cantidad de Fincas Activas
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: GeoFloraTheme.accent,
                    ),
                  ),
                  const Text('Fincas Activas', style: TextStyle(color: GeoFloraTheme.textLight)),
                ],
              ),
              // Métrica Clave 2
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '4,500 ha', // ⚠️ Dato Dinámico: Área Total en Hectáreas
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: GeoFloraTheme.gold,
                    ),
                  ),
                  const Text('Área Registrada', style: TextStyle(color: GeoFloraTheme.textLight)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. 🦶 Widget para el pie de página (sin cambios, pero lo mantenemos)
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      color: GeoFloraTheme.background, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Divider(color: Color(0xFF1B263B), height: 1, thickness: 1),
          const SizedBox(height: 15),
          Text(
            '© ${DateTime.now().year} GeoFlora. Todos los derechos reservados.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: GeoFloraTheme.textMuted),
          ),
          const SizedBox(height: 5),
          Text(
            'Política de Privacidad | Términos de Servicio',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: GeoFloraTheme.accent.withOpacity(0.6), 
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = getFeaturesForRole(userRole);
    final responsiveTitleSize =
        _getResponsiveFontSize(context, 28.0).clamp(24.0, 36.0);
    final responsiveSubtitleSize =
        _getResponsiveFontSize(context, 16.0).clamp(14.0, 18.0);
    final responsiveSectionTitleSize =
        _getResponsiveFontSize(context, 20.0).clamp(18.0, 24.0);

    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        // 5. Usar el color de superficie para el AppBar, no transparente, para la elevación
        backgroundColor: GeoFloraTheme.surface, 
        elevation: 0,
        title: const Text(
          'GeoFlora',
          style: TextStyle(color: GeoFloraTheme.textLight, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: GeoFloraTheme.textLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Ver Perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 6. Saludo sin mayúsculas forzadas para mayor elegancia
                  Text(
                    'Hola, ${userRole.substring(0, 1).toUpperCase()}${userRole.substring(1).toLowerCase()}',
                    style: TextStyle(
                      fontSize: responsiveTitleSize,
                      fontWeight: FontWeight.w900,
                      color: GeoFloraTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accede a las funciones operativas de tu rol.',
                    style: TextStyle(
                      fontSize: responsiveSubtitleSize,
                      color: GeoFloraTheme.textMuted,
                    ),
                  ),
                  
                  // 7. INSERCIÓN DEL DASHBOARD ZERO
                  _buildDashboardZero(context, responsiveSectionTitleSize),
                  
                  // Título de la sección de módulos
                  Text(
                    'Módulos de Gestión',
                    style: TextStyle(
                      fontSize: responsiveSectionTitleSize,
                      fontWeight: FontWeight.bold,
                      color: GeoFloraTheme.accent, 
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (features.isNotEmpty)
                    // 8. TRANSICIÓN DE GRIDVIEW A LISTVIEW: Más legible y táctil en móvil
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: features.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final feature = features[index];
                        return FeatureCard(
                          title: feature['title'],
                          subtitle: feature['subtitle'],
                          icon: feature['icon'],
                          color: feature['color'],
                          screen: feature['screen'],
                        );
                      },
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: Text(
                          "No hay módulos operativos disponibles para tu rol.",
                          style: TextStyle(fontSize: 18, color: GeoFloraTheme.textMuted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            _buildFooter(context),
          ],
        ),
      ),
    );
  }
}