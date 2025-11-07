import 'package:flutter/material.dart';
import '../../services/finca_service.dart';
import '../home/theme/dark_theme.dart';
import 'finca_detail_screen.dart';

class FincaListScreen extends StatefulWidget {
  const FincaListScreen({super.key});

  @override
  State<FincaListScreen> createState() => _FincaListScreenState();
}

class _FincaListScreenState extends State<FincaListScreen> {
  final FincaService _fincaService = FincaService();
  late Future<List<dynamic>> _fincasFuture;
  String _filtro = 'todas'; // todas | activas | inactivas
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fincasFuture = _fincaService.getAllFincas();
  }

  Future<void> _recargarFincas() async {
    setState(() {
      _fincasFuture = _fincaService.getAllFincas();
    });
  }

  // Filtrar por estado y búsqueda
  List<dynamic> _filtrarFincas(List<dynamic> fincas) {
    List<dynamic> filtradas = fincas;

    if (_filtro == 'activas') {
      filtradas = filtradas.where((f) => f['is_active'] == true).toList();
    } else if (_filtro == 'inactivas') {
      filtradas = filtradas.where((f) => f['is_active'] == false).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtradas = filtradas.where((f) {
        final nombre = (f['nombreFinca'] ?? '').toString().toLowerCase();
        final codigo = (f['codigoFinca'] ?? '').toString().toLowerCase();
        final abrev = (f['abreviaturaFinca'] ?? '').toString().toLowerCase();
        return nombre.contains(q) || codigo.contains(q) || abrev.contains(q);
      }).toList();
    }

    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: const Text("Listado de Fincas"),
        backgroundColor: Colors.black.withOpacity(0.85),
        actions: [
          PopupMenuButton<String>(
            color: Colors.grey[900],
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onSelected: (value) => setState(() => _filtro = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todas',
                child: Text("📋 Todas", style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'activas',
                child: Text("🟢 Habilitadas", style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'inactivas',
                child: Text("🔴 Inhabilitadas", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ==============================
          // Barra de búsqueda
          // ==============================
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.black54,
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o abreviatura...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // ==============================
          // Lista de fincas
          // ==============================
          Expanded(
            child: FutureBuilder<List<dynamic>>(
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
                      "Error al cargar fincas: ${snapshot.error}",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay fincas registradas.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final fincasFiltradas = _filtrarFincas(snapshot.data!);

                if (fincasFiltradas.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay resultados para \"$_query\".",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _recargarFincas,
                  backgroundColor: Colors.black,
                  color: Colors.white,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: fincasFiltradas.length,
                    itemBuilder: (context, index) {
                      final finca = fincasFiltradas[index];
                      final bool isActive = finca['is_active'] ?? true;

                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.landscape,
                            color: isActive ? Colors.greenAccent : Colors.redAccent,
                          ),
                          title: Text(
                            finca['nombreFinca'] ?? 'Sin nombre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Código: ${finca['codigoFinca'] ?? '-'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "Abreviatura: ${finca['abreviaturaFinca'] ?? '-'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "Dirección: ${finca['direccionFinca'] ?? '-'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            child: Text(
                              isActive ? "Habilitada" : "Inhabilitada",
                              style: TextStyle(
                                color: isActive ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FincaDetailScreen(
                                  idFinca: finca['idFinca'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
