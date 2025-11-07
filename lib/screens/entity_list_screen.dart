import 'package:flutter/material.dart';
import 'farm_structure_management_screen.dart'; // Importa el modelo FarmEntity
import 'entity_form_screen.dart'; // Importa la vista de formulario (ver siguiente código)

// -------------------------------------------------------------------
// MODELO DE DATOS SIMPLIFICADO PARA LA LISTA
// -------------------------------------------------------------------
// En una aplicación real, este modelo se llenaría con la respuesta de la API.
class EntityRecord {
  final int id;
  final String name;
  final Map<String, dynamic> parentInfo;

  EntityRecord({
    required this.id,
    required this.name,
    this.parentInfo = const {},
  });
}

// 🚨 SIMULACIÓN DE DATOS DE LA API
List<EntityRecord> _getMockRecords(String title) {
  switch (title) {
    case 'Fincas':
      return [EntityRecord(id: 1, name: 'Finca El Tesoro'), EntityRecord(id: 2, name: 'Finca La Esperanza')];
    case 'Áreas':
      return [
        EntityRecord(id: 101, name: 'Area 1 - Húmeda', parentInfo: {'Finca': 'El Tesoro'}),
        EntityRecord(id: 102, name: 'Area 2 - Seca', parentInfo: {'Finca': 'La Esperanza'})
      ];
    case 'Bloques':
      return [
        EntityRecord(id: 201, name: 'Bloque A-1', parentInfo: {'Finca': 'El Tesoro', 'Área': 'Area 1 - Húmeda'})
      ];
    case 'Naves':
      return []; // Simula que no hay Naves
    case 'Camas':
      return []; // Simula que no hay Camas
    default:
      return [];
  }
}

// -------------------------------------------------------------------
// VISTA DE LISTADO DE ENTIDADES
// -------------------------------------------------------------------

class EntityListScreen extends StatefulWidget {
  final FarmEntity entity;
  final Map<String, int> parentCounts; // Para la validación del formulario

  const EntityListScreen({
    required this.entity,
    required this.parentCounts,
    super.key,
  });

  @override
  State<EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends State<EntityListScreen> {
  List<EntityRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  // En una app real, esta función haría llamadas GET a la API (e.g., GET /fincas)
  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _records = _getMockRecords(widget.entity.title);
      _isLoading = false;
    });
  }

  void _navigateToForm({EntityRecord? record}) {
    // Navega al formulario para Crear (record == null) o Editar (record != null)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntityFormScreen(
          entity: widget.entity,
          record: record,
          parentCounts: widget.parentCounts,
        ),
      ),
    ).then((_) => _fetchRecords()); // Recarga al volver
  }

  void _deleteRecord(EntityRecord record) {
    // 🚨 En el entorno real, aquí iría la llamada DELETE a la API.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inhabilitando/Eliminando ${widget.entity.title} con ID ${record.id}')),
    );
    // Simula la eliminación
    setState(() {
      _records.removeWhere((r) => r.id == record.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si se puede crear uno nuevo (basado en la jerarquía)
    final bool canCreate = widget.entity.title == 'Fincas' || widget.parentCounts[farmStructure[farmStructure.indexOf(widget.entity) - 1].title]! > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de ${widget.entity.title}'),
        backgroundColor: widget.entity.color,
      ),
      // Botón flotante para Registrar/Crear
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canCreate ? () => _navigateToForm(record: null) : null,
        label: Text('Registrar ${widget.entity.title.substring(0, widget.entity.title.length - 1)}'),
        icon: const Icon(Icons.add),
        backgroundColor: canCreate ? widget.entity.color : Colors.grey,
      ),
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      canCreate 
                        ? 'No hay ${widget.entity.title} registrados. ¡Cree uno nuevo!'
                        : 'No se puede registrar ${widget.entity.title} porque no existen ${farmStructure[farmStructure.indexOf(widget.entity) - 1].title}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(widget.entity.icon, color: widget.entity.color),
                        title: Text(record.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: record.parentInfo.isEmpty
                            ? null
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: record.parentInfo.entries.map((e) => Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12))).toList(),
                              ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón de EDITAR
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _navigateToForm(record: record),
                            ),
                            // Botón de INHABILITAR/ELIMINAR
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecord(record),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}