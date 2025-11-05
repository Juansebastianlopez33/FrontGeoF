import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Importa la pantalla de perfil

// --- PANTALLAS PLACEHOLDER PARA LAS FUNCIONALIDADES PRINCIPALES ---

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registros de GeoFlora')),
      body: const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'Aquí verás tus registros de campo (Mapas/Listas). Implementa la lógica de la API para cargar datos.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      )),
    );
  }
}

class NewRecordScreen extends StatelessWidget {
  const NewRecordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Registro')),
      body: const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'Aquí irá el formulario para ingresar nuevos datos de campo (e.g., coordenadas, especie).',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      )),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: const Center(
          child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text(
          'Opciones de configuración de la aplicación (e.g., notificaciones, permisos).',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
      )),
    );
  }
}

// -------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Widget reutilizable para las tarjetas de funcionalidad
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget screen,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definimos las funcionalidades de la aplicación
    final List<Map<String, dynamic>> features = [
      {
        'title': 'Ver Registros',
        'subtitle': 'Consulta, filtra y visualiza todos tus datos de campo.',
        'icon': Icons.map,
        'color': const Color(0xFF4CAF50), // Verde de naturaleza
        'screen': const RecordsScreen(),
      },
      {
        'title': 'Nuevo Registro',
        'subtitle': 'Añade una nueva observación de flora o dato geográfico.',
        'icon': Icons.add_location_alt,
        'color': const Color(0xFF2196F3), // Azul de cielo/agua
        'screen': const NewRecordScreen(),
      },
      {
        'title': 'Configuración',
        'subtitle': 'Personaliza las opciones y preferencias de la aplicación.',
        'icon': Icons.settings,
        'color': const Color(0xFFFF9800), // Naranja cálido
        'screen': const SettingsScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Página Principal"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navega al perfil. Usa push para que el botón de volver funcione
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Ver Perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Letrero minimalista 'GEOFLORA'
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                // Degradado en colores de naturaleza
                colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'GEOFLORA',
                style: TextStyle(
                  // Tamaño responsivo
                  fontSize: MediaQuery.of(context).size.width > 600 ? 100 : 70,
                  fontWeight: FontWeight.w900,
                  color: Colors.white, // El color es enmascarado por el ShaderMask
                  letterSpacing: 4.0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "¡Bienvenido a la aplicación de gestión!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 40, thickness: 1),

            // Sección de Tarjetas de Funcionalidad
            LayoutBuilder(
              builder: (context, constraints) {
                // Determina el número de columnas basado en el ancho
                final crossAxisCount = constraints.maxWidth > 800
                    ? 3
                    : constraints.maxWidth > 500
                        ? 2
                        : 1;
                // Ajusta la relación de aspecto para que las tarjetas no sean demasiado altas en móvil
                final childAspectRatio = constraints.maxWidth > 500 ? 1.0 : 1.2;

                return GridView.count(
                  shrinkWrap: true, // Ocupa solo el espacio necesario
                  physics: const NeverScrollableScrollPhysics(), // Evita scroll anidado
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: childAspectRatio,
                  children: features.map((feature) {
                    return _buildFeatureCard(
                      context,
                      feature['title'] as String,
                      feature['subtitle'] as String,
                      feature['icon'] as IconData,
                      feature['color'] as Color,
                      feature['screen'] as Widget,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}