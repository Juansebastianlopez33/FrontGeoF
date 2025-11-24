// lib/screens/bloque/bloque_list_screen.dart (AJUSTADO - SOLO ACTIVOS)

import 'package:flutter/material.dart';
// Importamos AreaService para obtener la lista de áreas (el padre)
import '../../services/area_service.dart';
// Importamos el nuevo servicio de bloques
import '../../services/bloques_service.dart';
// Importación necesaria para usar las constantes de estilo
import '../home/theme/dark_theme.dart';
// Asumimos la existencia de una pantalla de detalle/edición
import 'bloque_detail_screen.dart'; // 💡 Esta importación es la que se usará.


class BloqueListScreen extends StatefulWidget {
  // ✅ AJUSTE: initialAreaId ahora es un parámetro OBLIGATORIO (required)
  final String initialAreaId; 
  final String? initialAreaName;

  const BloqueListScreen({
    super.key,
    required this.initialAreaId, // Marcado como requerido
    this.initialAreaName
  });

  @override
  State<BloqueListScreen> createState() => _BloqueListScreenState();
}

class _BloqueListScreenState extends State<BloqueListScreen> {
  // Servicios a utilizar
  final AreaService _areaService = AreaService();
  final BloquesService _bloqueService = BloquesService();

  // 🗑️ Eliminados: _areas (Lista de áreas para el Dropdown)
  // 🗑️ Eliminado: _areaSeleccionadaId (ID del área seleccionada)
  
  List<dynamic> _bloques = []; // Lista de bloques
  // 🗑️ Eliminado: _isLoadingAreas. Se mantiene _isLoadingBloques.
  bool _isLoadingBloques = false; 
  String? _errorMessage;
  
  // Constantes de Estilo
  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeBackground = GeoFloraTheme.surface;
  

  @override
  void initState() {
    super.initState();
    // 🎯 Llamada a la función de carga inicial
    _loadAreasAndInitialSelection();
  }

  // ==========================================================
  // CARGA DE DATOS
  // ==========================================================

  // Carga todas las áreas habilitadas y maneja la selección inicial.
  // ✅ AJUSTADO: Ahora solo valida el ID inicial y llama a _loadBloques.
  // Se mantiene el nombre de la función para no romper referencias externas.
  Future<void> _loadAreasAndInitialSelection() async {
    setState(() {
      _isLoadingBloques = true; 
      _errorMessage = null;
    });

    try {
      // 💡 Ya no se cargan áreas. Obtenemos el ID directamente del widget.
      final idArea = int.tryParse(widget.initialAreaId);

      if (idArea == null || idArea <= 0) {
        throw Exception('ID de Área inicial no válido o faltante: ${widget.initialAreaId}');
      }

      if (mounted) {
        // Llamada directa a cargar bloques para el área recibida.
        await _loadBloques(idArea);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoadingBloques = false;
        });
      }
    }
  }

  // 📋 Carga la lista de bloques para un área específica (MODIFICADO: SOLO ACTIVOS)
  Future<void> _loadBloques(int idArea) async {
    setState(() {
      _isLoadingBloques = true;
      _bloques = [];
    });

    // 🎯 AJUSTE: Llama al servicio sin el parámetro de estado, garantizando solo activos
    try {
      final bloquesList = await _bloqueService.getAllBloques(idArea: idArea);

      if (mounted) {
        setState(() {
          _bloques = bloquesList;
          _isLoadingBloques = false;
        });
        if (_bloques.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay bloques habilitados registrados para esta Área.')),
          );
        }
      }
    } catch (e) {
       if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar bloques: $e';
          _isLoadingBloques = false;
        });
      }
    }
  }

  // 🗑️ Eliminado: Función para manejar el cambio de área en el dropdown (_onAreaChanged)

  // Navegación a la pantalla de detalles (o edición)
  void _navigateToDetailsScreen(int idBloque) {
    // La redirección está aquí y usa la clase importada.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BloqueDetailScreen(idBloque: idBloque),
      ),
    ).then((_) {
        // Recargamos la lista al volver para actualizar cambios
        final idArea = int.tryParse(widget.initialAreaId);
        if (idArea != null && idArea > 0) {
          _loadBloques(idArea);
        }
    });
  }


  // ==========================================================
  // WIDGETS DE UI
  // ==========================================================

  // 🗑️ Eliminado: Dropdown para seleccionar el Área (_buildAreaDropdown())

  // Lista de Bloques (Muestra solo los activos)
  Widget _buildBloqueList() {
    if (_isLoadingBloques) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(color: Colors.white),
      ));
    }
    
    if (_bloques.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            'No hay bloques habilitados registrados para esta área.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bloques.length,
      itemBuilder: (context, index) {
        final bloque = _bloques[index];
        final numeroBloque = bloque['numeroBloque']?.toString() ?? 'N/A';
        final isActive = bloque['is_active'] == true;
        
        final colorEstado = isActive ? _themeAccent : Colors.redAccent;
        final estado = isActive ? 'Habilitado' : 'Inhabilitado';
        final iconEstado = isActive ? Icons.check_circle_outline : Icons.cancel_outlined;

        return Card(
          color: Colors.black45,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: Icon(Icons.grass, color: colorEstado),
            title: Text(
              'BLOQUE $numeroBloque',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'ID: ${bloque['idBloque'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            // Trailing: Estado (Icono y Texto)
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconEstado, color: colorEstado, size: 16),
                const SizedBox(width: 4),
                Text(
                  estado,
                  style: TextStyle(
                    color: colorEstado,
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                  ),
                ),
                const SizedBox(width: 10),
                // Icono para la navegación a detalles
                const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
              ],
            ),
            onTap: () {
              final rawId = bloque['idBloque'];
              final idBloque = rawId is int
                  ? rawId
                  : int.tryParse(rawId?.toString() ?? '') ?? 0;
              // ✅ Redirección correcta usando el ID del bloque
              _navigateToDetailsScreen(idBloque); 
            },
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themeBackground,
      appBar: AppBar(
        // Si hay un nombre de área inicial, úsalo en el título
        title: Text(widget.initialAreaName ?? 'Bloques Habilitados'), 
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 🗑️ Eliminados: Widgets de selección de Área (Dropdown)
            /*
            const Text(
              'Seleccione el Área',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildAreaDropdown(),
            const SizedBox(height: 20),
            */
            const Text(
              'Bloques Habilitados',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10), // Añadido espacio después del divisor
            
            // Mostrar mensaje de error si existe
            if (_errorMessage != null)
              Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else
              _buildBloqueList(),
          ],
        ),
      ),
      
      // ✅ FAB para crear un nuevo bloque en el área seleccionada
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final idArea = int.tryParse(widget.initialAreaId);
          if (idArea != null && idArea > 0) {
              // 💡 Aquí iría la navegación a la pantalla de creación
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navegación a Crear Bloque pendiente. ID de Área: ${idArea}')),
              );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se puede crear un bloque: ID de Área no válido.')),
              );
          }
        },
        label: const Text('Nuevo Bloque'),
        icon: const Icon(Icons.add),
        backgroundColor: _themeAccent,
      ),
    );
  }
}
// ⚠️ Nota: Se eliminó el "placeholder" BloqueDetailScreen al final del archivo.
// La clase BloqueDetailScreen debe residir en 'bloque_detail_screen.dart' para que la importación funcione correctamente.