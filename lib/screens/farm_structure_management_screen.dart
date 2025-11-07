import 'package:flutter/material.dart';
import 'entity_list_screen.dart'; // Importamos la vista genérica (ver siguiente código)

// -------------------------------------------------------------------
// MODELOS DE DATOS Y CONTEO SIMULADO (Simula la llamada a la API)
// -------------------------------------------------------------------

// Definiciones de la estructura de la finca para el UI
class FarmEntity {
  final String title;
  final String apiEndpoint;
  final IconData icon;
  final Color color;
  final String parentEntity; // Nombre de la entidad padre requerida

  const FarmEntity({
    required this.title,
    required this.apiEndpoint,
    required this.icon,
    required this.color,
    this.parentEntity = '',
  });
}

// Datos de la jerarquía (Finca -> Área -> Bloque -> Nave -> Cama)
const List<FarmEntity> farmStructure = [
  FarmEntity(title: 'Fincas', apiEndpoint: '/fincas', icon: Icons.grass, color: Colors.green),
  FarmEntity(title: 'Áreas', apiEndpoint: '/areas', icon: Icons.layers, color: Colors.blue),
  FarmEntity(title: 'Bloques', apiEndpoint: '/bloques', icon: Icons.view_module, color: Colors.orange),
  FarmEntity(title: 'Naves', apiEndpoint: '/naves', icon: Icons.warehouse, color: Colors.purple),
  FarmEntity(title: 'Camas', apiEndpoint: '/camas', icon: Icons.bed, color: Colors.brown),
];

// 🚨 SIMULACIÓN DE CONTEO DE ENTIDADES (En una aplicación real, esto sería una llamada a la API)
// Estos valores iniciales determinan qué tarjetas de 'REGISTRAR' estarán habilitadas.
Map<String, int> _entityCounts = {
  'Fincas': 3,
  'Áreas': 5,
  'Bloques': 2,
  'Naves': 0, // Nave no tiene registros, por lo tanto Cama estará inhabilitada.
  'Camas': 0,
};

// -------------------------------------------------------------------
// VISTA PRINCIPAL DE GESTIÓN DE LA ESTRUCTURA
// -------------------------------------------------------------------

class FarmStructureManagementScreen extends StatefulWidget {
  const FarmStructureManagementScreen({super.key});

  @override
  State<FarmStructureManagementScreen> createState() => _FarmStructureManagementScreenState();
}

class _FarmStructureManagementScreenState extends State<FarmStructureManagementScreen> {
  // En una app real, esta función haría llamadas GET /count a la API.
  Future<void> _fetchCounts() async {
    // 🚨 En el entorno real, actualiza _entityCounts con los datos de la API
    // Por ahora, solo simula que los datos se cargaron.
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  // Obtiene el conteo del padre
  int _getParentCount(String parentEntity) {
    // Si no tiene padre (Finca), se asume que siempre se puede registrar.
    if (parentEntity.isEmpty) return 1; 
    return _entityCounts[parentEntity] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Estructura de Finca'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleccione la entidad a gestionar (Crear, Editar, Eliminar):',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const Divider(),
            
            // GridView para las 5 tarjetas
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: farmStructure.map((entity) {
                // Lógica de inhabilitación jerárquica
                final String parentName = entity == farmStructure.first 
                    ? '' 
                    : farmStructure[farmStructure.indexOf(entity) - 1].title;
                
                final bool canRegister = _getParentCount(parentName) > 0 || entity == farmStructure.first;
                
                // Texto de ayuda y estado
                String subtitle = canRegister 
                    ? 'Existen registros. Click para gestionar.'
                    : '¡REGISTRO BLOQUEADO! Primero debe crear una ${parentName.substring(0, parentName.length - 1)}.'; // e.g. 'Finca'
                
                if (entity == farmStructure.first) {
                   subtitle = 'Entidad de nivel superior.';
                }

                return EntityManagementCard(
                  entity: entity,
                  canRegister: canRegister,
                  subtitle: subtitle,
                  onTap: () {
                    if (canRegister) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EntityListScreen(entity: entity, parentCounts: _entityCounts),
                        ),
                      ).then((_) => _fetchCounts()); // Recargar conteos al volver
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget simple para la tarjeta de gestión
class EntityManagementCard extends StatelessWidget {
  final FarmEntity entity;
  final bool canRegister;
  final String subtitle;
  final VoidCallback onTap;

  const EntityManagementCard({
    required this.entity,
    required this.canRegister,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // El color de la tarjeta es más tenue si está inhabilitada
    final cardColor = canRegister ? entity.color : Colors.grey.shade300;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: cardColor.withOpacity(canRegister ? 0.9 : 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(entity.icon, size: 40, color: canRegister ? Colors.white : Colors.grey.shade600),
              const SizedBox(height: 8),
              Text(
                entity.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: canRegister ? Colors.white70 : Colors.grey.shade700,
                  fontWeight: canRegister ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}