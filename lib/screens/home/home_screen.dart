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

  @override
  Widget build(BuildContext context) {
    final features = getFeaturesForRole(userRole);
    final responsiveTitleSize =
        _getResponsiveFontSize(context, 24.0).clamp(20.0, 30.0);
    final responsiveSubtitleSize =
        _getResponsiveFontSize(context, 16.0).clamp(14.0, 18.0);
    final responsiveSectionTitleSize =
        _getResponsiveFontSize(context, 20.0).clamp(16.0, 24.0);

    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        title: const Text('GeoFlora - Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Bienvenido a GeoFlora',
                style: TextStyle(
                  fontSize: responsiveTitleSize,
                  fontWeight: FontWeight.bold,
                  color: GeoFloraTheme.accent,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Rol Actual: ${userRole.toUpperCase()}',
              style: TextStyle(
                fontSize: responsiveSubtitleSize,
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
            const Divider(height: 30, color: Colors.white24),
            if (features.isNotEmpty) ...[
              Text(
                'Opciones de Funcionalidad',
                style: TextStyle(
                  fontSize: responsiveSectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 800
                      ? 3
                      : constraints.maxWidth > 500
                          ? 2
                          : 1;
                  final childAspectRatio =
                      constraints.maxWidth > 500 ? 1.0 : 1.2;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: childAspectRatio,
                    children: features.map((feature) {
                      return FeatureCard(
                        title: feature['title'],
                        subtitle: feature['subtitle'],
                        icon: feature['icon'],
                        color: feature['color'],
                        screen: feature['screen'],
                      );
                    }).toList(),
                  );
                },
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Text(
                    "No hay opciones disponibles para tu rol.",
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
