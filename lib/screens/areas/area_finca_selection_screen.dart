import 'package:flutter/material.dart';
import '../../services/finca_service.dart'; // Servicio para obtener la lista de fincas
import '../home/theme/dark_theme.dart'; // Consistencia del tema
import 'area_list_screen.dart'; // Modo 'view'
import 'area_list_finca_edit_screen.dart'; // Modo 'edit'

class AreaFincaSelectionScreen extends StatefulWidget {
  final String mode; // 'view' o 'edit'

  const AreaFincaSelectionScreen({super.key, required this.mode});

  @override
  State<AreaFincaSelectionScreen> createState() => _AreaFincaSelectionScreenState();
}

class _AreaFincaSelectionScreenState extends State<AreaFincaSelectionScreen> {
  final FincaService _fincaService = FincaService();

  List<dynamic> _fincas = [];
  bool _isLoading = true;
  String? _errorMessage;

  // 🎨 Constantes de Estilo
  final Color _themeAccent = GeoFloraTheme.accent;
  final Color _themeSurface = GeoFloraTheme.surface;

  @override
  void initState() {
    super.initState();
    _loadFincas();
  }

  // ==========================================================
  // ⚙️ Cargar Fincas con validación robusta
  // ==========================================================
  Future<void> _loadFincas() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _fincaService.getAllFincas();

      if (!mounted) return;

      // El servicio devuelve siempre una List, por lo que no es necesario comprobar el tipo,
      // solo si está vacía o no; casteamos a List para operaciones específicas.
      if (result.isNotEmpty) {
        // ✅ Filtrado seguro de fincas válidas
        final validFincas = result.where((finca) {
          if (finca == null) return false;
          final id = finca['idFinca'] ?? finca['id'];
          final parsedId = int.tryParse(id?.toString() ?? '0') ?? 0;
          return parsedId > 0;
        }).toList();

        setState(() {
          _fincas = validFincas;
          _isLoading = false;
        });
      } else {
        // No hay fincas devueltas o lista vacía
        setState(() {
          _fincas = [];
          _errorMessage = 'No se encontraron fincas o hubo un error.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error de conexión: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // ✏️ Navegar a Lista de Áreas (usa argumentos nombrados)
  // ==========================================================
  void _navigateToAreaList(int idFinca) {
    if (idFinca <= 0) {
      _showErrorSnackBar('ID de finca inválido');
      return;
    }

    final isEditMode = widget.mode == 'edit';
    final nombreFinca = _fincas.firstWhere(
      (f) {
        final id = f['idFinca'] ?? f['id'];
        final parsedId = int.tryParse(id?.toString() ?? '0') ?? 0;
        return parsedId == idFinca;
      },
      orElse: () => {'nombreFinca': 'Finca Desconocida'},
    )['nombreFinca']?.toString().trim() ?? 'Finca Desconocida';
    
    // ✅ CORRECCIÓN: Se pasó idFinca y nombreFinca a AreaListScreen.
    final Widget screen = isEditMode
        ? AreaListFincaEditScreen(idFinca: idFinca, nombreFinca: nombreFinca)
        : AreaListScreen();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    ).then((_) {
      _loadFincas(); // Recarga al volver
    });
  }

  // ==========================================================
  // 🔔 Mostrar errores al usuario
  // ==========================================================
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==========================================================
  // 🧱 Build
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.mode == 'edit';
    final title = isEditMode
        ? "Seleccionar Finca para EDITAR Áreas"
        : "Seleccionar Finca para VER Áreas";

    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black.withOpacity(0.7),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadFincas,
            tooltip: 'Recargar fincas',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ==========================================================
  // 🧱 Cuerpo de la pantalla (manejo de estados)
  // ==========================================================
  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _themeAccent),
            const SizedBox(height: 16),
            const Text(
              'Cargando fincas...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadFincas,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_fincas.isEmpty) {
      return const Center(
        child: Text(
          "No hay fincas disponibles para seleccionar.",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    // 🧱 Lista de Fincas
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _fincas.length,
      itemBuilder: (context, index) {
        final finca = _fincas[index];

        final rawId = finca['idFinca'] ?? finca['id'];
        final idFinca = int.tryParse(rawId?.toString() ?? '0') ?? 0;
        final codigo = finca['codigoFinca']?.toString().trim() ?? 'N/A';
        if (idFinca <= 0) return const SizedBox.shrink();

        final nombreFinca =
            finca['nombreFinca']?.toString().trim() ?? 'Finca sin nombre';
        final abreviatura =
            finca['abreviaturaFinca']?.toString().trim() ?? 'N/A';

        return Card(
          color: _themeSurface.withOpacity(0.7),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            onTap: () => _navigateToAreaList(idFinca),
            leading: Icon(
              widget.mode == 'edit' ? Icons.edit_location : Icons.search,
              color: _themeAccent,
            ),
            title: Text(
              nombreFinca,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'CODIGO: $codigo | Abreviatura: $abreviatura',
              style: const TextStyle(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ),
        );
      },
    );
  }
}