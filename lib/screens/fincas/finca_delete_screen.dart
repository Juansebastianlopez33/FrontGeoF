import 'package:flutter/material.dart';
import '../../services/finca_service.dart';
import '../home/theme/dark_theme.dart';

class FincaDeleteScreen extends StatefulWidget {
  const FincaDeleteScreen({super.key});

  @override
  State<FincaDeleteScreen> createState() => _FincaDeleteScreenState();
}

class _FincaDeleteScreenState extends State<FincaDeleteScreen> {
  final FincaService _fincaService = FincaService();
  late Future<List<dynamic>> _fincasFuture;

  @override
  void initState() {
    super.initState();
    _fincasFuture = _fincaService.getAllFincas();
  }

  Future<void> _toggleEstado(int idFinca, bool nuevoEstado) async {
    final result = await _fincaService.toggleFincaStatus(idFinca, nuevoEstado);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? "✅ Finca habilitada correctamente."
                : "🚫 Finca inhabilitada correctamente.",
          ),
          backgroundColor: nuevoEstado ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _fincasFuture = _fincaService.getAllFincas();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error: ${result['message'] ?? 'No se pudo cambiar el estado.'}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Inhabilitar / Habilitar Fincas"),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fincasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error al cargar las fincas: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No hay fincas registradas.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final fincas = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _fincasFuture = _fincaService.getAllFincas();
              });
            },
            backgroundColor: Colors.black,
            color: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: fincas.length,
              itemBuilder: (context, index) {
                final finca = fincas[index];
                final bool isActive = finca['is_active'] ?? true;

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      finca['nombreFinca'] ?? 'Sin nombre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Código: ${finca['codigoFinca']}  |  Estado: ${isActive ? 'Activo' : 'Inactivo'}",
                      style: TextStyle(
                        color: isActive ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? Colors.redAccent : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(isActive ? Icons.block : Icons.check_circle,
                          color: Colors.white),
                      label: Text(
                        isActive ? "Inhabilitar" : "Habilitar",
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: Text(
                              isActive
                                  ? "Inhabilitar Finca"
                                  : "Habilitar Finca",
                              style: const TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              isActive
                                  ? "¿Seguro que deseas inhabilitar esta finca?"
                                  : "¿Seguro que deseas habilitar esta finca?",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Cancelar",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Confirmar",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          _toggleEstado(finca['idFinca'], !isActive);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
