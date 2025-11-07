import 'package:flutter/material.dart';
import '../home/theme/dark_theme.dart';
import '../../services/finca_service.dart';

class FincaDetailScreen extends StatefulWidget {
  final int idFinca;

  const FincaDetailScreen({super.key, required this.idFinca});

  @override
  State<FincaDetailScreen> createState() => _FincaDetailScreenState();
}

class _FincaDetailScreenState extends State<FincaDetailScreen> {
  final FincaService _fincaService = FincaService();
  Map<String, dynamic>? finca;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFincaDetails();
  }

  Future<void> _loadFincaDetails() async {
    final result = await _fincaService.getFincaDetails(widget.idFinca);
    if (mounted) {
      setState(() {
        finca = result['success'] ? result['data'] : null;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Detalles de la Finca"),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : finca == null
              ? const Center(
                  child: Text(
                    "No se pudieron cargar los detalles de la finca.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (finca!['url_imagen'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            finca!['url_imagen'],
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.white38,
                              size: 100,
                            ),
                          ),
                        )
                      else
                        const Icon(Icons.image_outlined,
                            color: Colors.white38, size: 100),
                      const SizedBox(height: 20),

                      // Información general
                      _buildInfoRow("Código", finca!['codigoFinca']),
                      _buildInfoRow("Abreviatura", finca!['abreviaturaFinca']),
                      _buildInfoRow("Nombre", finca!['nombreFinca']),
                      _buildInfoRow("Dirección", finca!['direccionFinca']),
                      _buildInfoRow("Agrónomo Encargado",
                          finca!['agronomoEncargado_id']),
                      const Divider(color: Colors.white24, height: 40),

                      // Estructura descendiente
                      Text(
                        "Estructura de la Finca",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GeoFloraTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        "Áreas",
                        "${finca!['estructura_descendiente']['total_areas']}",
                      ),
                      _buildInfoRow(
                        "Bloques",
                        "${finca!['estructura_descendiente']['total_bloques']}",
                      ),
                      _buildInfoRow(
                        "Naves",
                        "${finca!['estructura_descendiente']['total_naves']}",
                      ),
                      _buildInfoRow(
                        "Camas",
                        "${finca!['estructura_descendiente']['total_camas']}",
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? "—",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
