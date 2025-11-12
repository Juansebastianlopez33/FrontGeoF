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
  List<dynamic> agronomos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carga finca + lista de agrónomos
  Future<void> _loadData() async {
    final fincaResult = await _fincaService.getFincaDetails(widget.idFinca);
    final agronomosList = await _fincaService.getAllAgronomos();

    if (mounted) {
      setState(() {
        finca = fincaResult['success'] ? fincaResult['data'] : null;
        agronomos = agronomosList;
        isLoading = false;
      });
    }
  }

  // Busca el nombre del agrónomo según su cédula/id
  String _getAgronomoNombre(String? cedula) {
    if (cedula == null || cedula.isEmpty) return "—";
    final match = agronomos.firstWhere(
      (a) => a['cedula'].toString() == cedula.toString(),
      orElse: () => {},
    );
    if (match.isEmpty) return "No encontrado";
    return match['nombre'] ?? "Sin nombre";
  }

  // Widget para mostrar la imagen o el placeholder
  Widget _buildFincaImage() {
    final imageUrl = finca!['url_imagen'];

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Colors.white38,
          size: 100,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.black45,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported,
              color: Colors.white38, size: 100),
        ),
      ),
    );
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
                      _buildFincaImage(),
                      const SizedBox(height: 20),

                      _buildInfoRow("Código", finca!['codigoFinca']),
                      _buildInfoRow("Abreviatura", finca!['abreviaturaFinca']),
                      _buildInfoRow("Nombre", finca!['nombreFinca']),
                      _buildInfoRow("Dirección", finca!['direccionFinca']),

                      // 👨‍🌾 Mostrar el nombre del agrónomo en lugar de la cédula
                      _buildInfoRow(
                        "Agrónomo Encargado",
                        _getAgronomoNombre(finca!['agronomoEncargado_id']),
                      ),

                      const Divider(color: Colors.white24, height: 40),

                      Text(
                        "Estructura de la Finca",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GeoFloraTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow("Áreas",
                          "${finca!['estructura_descendiente']['total_areas']}"),
                      _buildInfoRow("Bloques",
                          "${finca!['estructura_descendiente']['total_bloques']}"),
                      _buildInfoRow("Naves",
                          "${finca!['estructura_descendiente']['total_naves']}"),
                      _buildInfoRow("Camas",
                          "${finca!['estructura_descendiente']['total_camas']}"),
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
