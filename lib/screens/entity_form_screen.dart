import 'package:flutter/material.dart';
import 'farm_structure_management_screen.dart'; 
import 'entity_list_screen.dart'; 

// 🚨 Modelo simple para las opciones del Dropdown
class ParentOption {
  final int id;
  final String name;

  ParentOption({required this.id, required this.name});
}

// 🚨 SIMULACIÓN DE DATOS DE PADRES (En una app real, esto es una llamada GET a la API)
List<ParentOption> _getMockParentOptions(String entityTitle) {
  switch (entityTitle) {
    case 'Áreas': // Necesita Fincas
      return [ParentOption(id: 1, name: 'Finca El Tesoro (ID: 1)'), ParentOption(id: 2, name: 'Finca La Esperanza (ID: 2)')];
    case 'Bloques': // Necesita Áreas
      return [ParentOption(id: 101, name: 'Area 1 - Húmeda (ID: 101)'), ParentOption(id: 102, name: 'Area 2 - Seca (ID: 102)')];
    case 'Naves': // Necesita Bloques
      return [ParentOption(id: 201, name: 'Bloque A-1 (ID: 201)'), ParentOption(id: 202, name: 'Bloque B-2 (ID: 202)')];
    case 'Camas': // Necesita Naves
      return [ParentOption(id: 301, name: 'Nave Central (ID: 301)'), ParentOption(id: 302, name: 'Nave Lateral (ID: 302)')];
    default:
      return [];
  }
}

// -------------------------------------------------------------------
// VISTA DE FORMULARIO GENÉRICO (Crear/Editar) - Ahora Stateful
// -------------------------------------------------------------------

class EntityFormScreen extends StatefulWidget {
  final FarmEntity entity;
  final EntityRecord? record; 
  final Map<String, int> parentCounts;

  const EntityFormScreen({
    required this.entity,
    this.record,
    required this.parentCounts,
    super.key,
  });

  @override
  State<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends State<EntityFormScreen> {
  List<ParentOption> _parentOptions = [];
  int? _selectedParentId;
  bool _isLoadingParents = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Si estamos editando, precargar el nombre y el ID del padre (simulado)
    if (widget.record != null) {
      _nameController.text = widget.record!.name;
      
      // Lógica de precarga del ID del padre inmediato al editar
      if (widget.entity != farmStructure.first) {
        final parentInfo = widget.record!.parentInfo;
        
        // Simulación: extrae el ID del nombre del registro padre (ej. "(ID: 123)")
        final parentNameWithId = parentInfo.values.last.toString();
        final match = RegExp(r'\(ID: (\d+)\)').firstMatch(parentNameWithId);
        if (match != null) {
          _selectedParentId = int.tryParse(match.group(1)!);
        }
      }
    }
    
    // Cargar las opciones del dropdown
    _loadParentOptions();
  }
  
  // Función para simular la carga de opciones del padre
  Future<void> _loadParentOptions() async {
    // Si no tiene padre (Fincas), termina de inmediato
    if (widget.entity == farmStructure.first) {
       setState(() => _isLoadingParents = false);
       return;
    }
    
    setState(() => _isLoadingParents = true);

    // 🚨 En el entorno real, aquí harías una llamada GET a la API
    await Future.delayed(const Duration(milliseconds: 300)); 
    
    final loadedOptions = _getMockParentOptions(widget.entity.title);
    
    setState(() {
      _parentOptions = loadedOptions;
      _isLoadingParents = false;
      
      // Si estamos creando y tenemos opciones, seleccionamos la primera por defecto.
      if (widget.record == null && _parentOptions.isNotEmpty) {
           _selectedParentId = _parentOptions.first.id;
      } 
      // Si estamos editando, nos aseguramos de que el ID precargado exista en la lista.
      else if (widget.record != null && _selectedParentId != null && 
               !_parentOptions.any((option) => option.id == _selectedParentId)) {
          // Si el ID precargado no existe (ej. fue eliminado), seleccionamos el primero o ninguno.
          _selectedParentId = _parentOptions.isNotEmpty ? _parentOptions.first.id : null;
      }
    });
  }

  // -------------------------------------------------------------------
  // WIDGET BUILD
  // -------------------------------------------------------------------
  
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.record != null;
    final parentIndex = farmStructure.indexOf(widget.entity) - 1;
    final bool hasParent = parentIndex >= 0;
    
    String parentTitle = hasParent ? farmStructure[parentIndex].title : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar ${widget.entity.title}' : 'Registrar ${widget.entity.title}'),
        backgroundColor: widget.entity.color,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------------------
            // 🚨 SELECCIÓN DEL PADRE INMEDIATO (Dropdown)
            // -------------------------------------------------------------
            if (hasParent) ...[
              const Text('Asociar a la Jerarquía Superior:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              _isLoadingParents 
                ? const Center(child: LinearProgressIndicator()) 
                : _parentOptions.isEmpty
                  ? Text(
                      'Error: No hay ${parentTitle} disponibles. Regrese y cree una primero.',
                      style: const TextStyle(color: Colors.red),
                    )
                  // ✅ Código limpio, confiando en List<ParentOption> no nula.
                  : DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Seleccionar ${parentTitle.substring(0, parentTitle.length - 1)} *',
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedParentId,
                      // Construcción de ítems simplificada, sin chequeo de nulidad redundante.
                      items: _parentOptions.map((option) {
                        return DropdownMenuItem<int>(
                          value: option.id,
                          child: Text(option.name),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedParentId = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Debe seleccionar un padre' : null,
                    ),
              const SizedBox(height: 20),
              
              const Divider(height: 30),
            ],

            // -------------------------------------------------------------
            // 🚨 INFORMACIÓN DE JERARQUÍA SUPERIOR (Solo Lectura)
            // -------------------------------------------------------------
            if (isEditing && widget.record!.parentInfo.isNotEmpty) ...[
                const Text('Jerarquía Superior del Registro (Solo Lectura):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...widget.record!.parentInfo.entries.map((entry) {
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: TextField(
                            controller: TextEditingController(text: '${entry.key}: ${entry.value}'),
                            decoration: InputDecoration(
                                labelText: entry.key,
                                border: const OutlineInputBorder(),
                                fillColor: Colors.grey.shade200,
                                filled: true,
                            ),
                            readOnly: true, // CLAVE: NO SE PUEDE EDITAR
                        ),
                    );
                }).toList(),
                const Divider(height: 30),
            ],

            // -------------------------------------------------------------
            // CAMPOS DE DATOS PROPIOS DE LA ENTIDAD
            // -------------------------------------------------------------
            Text(
              isEditing ? 'Datos de ${widget.entity.title} a modificar:' : 'Datos del nuevo registro:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre / Identificador de ${widget.entity.title}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // -------------------------------------------------------------
            // BOTÓN DE ACCIÓN
            // -------------------------------------------------------------
            ElevatedButton.icon(
              onPressed: () {
                if (!hasParent || _selectedParentId != null) {
                    // Lógica de POST/PUT a la API
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${isEditing ? 'Actualizando' : 'Creando'} ${widget.entity.title} asociado al ID Padre: ${_selectedParentId ?? 'N/A'}...')),
                    );
                    Navigator.pop(context);
                } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor, seleccione el elemento padre.'), backgroundColor: Colors.red),
                    );
                }
              },
              icon: Icon(isEditing ? Icons.save : Icons.add_circle),
              label: Text(isEditing ? 'Guardar Cambios' : 'Crear Registro'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: widget.entity.color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}