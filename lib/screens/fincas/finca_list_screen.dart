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
  
  // Se elimina el estado '_filtro' ya que ahora solo se verán las habilitadas.
  // String _filtro = 'todas'; 
  String _query = '';

  @override
  void initState() {
    super.initState();
    // 🎯 Se llama directamente al servicio para obtener solo las fincas habilitadas.
    _fincasFuture = _fincaService.getFincasByStatus(isActive: true);
  }

  Future<void> _recargarFincas() async {
    setState(() {
      // 🎯 Al recargar, volvemos a obtener solo las fincas habilitadas.
      _fincasFuture = _fincaService.getFincasByStatus(isActive: true);
    });
  }

  // Filtrar solo por búsqueda (el filtrado por estado lo hace ahora el backend).
  List<dynamic> _filtrarFincas(List<dynamic> fincas) {
    List<dynamic> filtradas = fincas;

    // Se elimina el filtrado local por estado, ya que el API solo devuelve activas.
    
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
        // ✏️ Título más específico
        title: const Text("Fincas Habilitadas"),
        backgroundColor: Colors.black.withOpacity(0.85),
        // ❌ Se elimina el menú de filtro por estado
        // actions: [
        //   PopupMenuButton<String>(
        //     ...
        //   ),
        // ],
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
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Las fincas recibidas ya son solo las habilitadas
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay fincas habilitadas registradas.",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final fincasFiltradas = _filtrarFincas(snapshot.data!);

                if (fincasFiltradas.isEmpty) {
                  return Center(
                    child: Text(
                      "No hay resultados para \"$_query\" entre las fincas habilitadas.",
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
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
                      // Ya que la lista es solo de activas, 'isActive' siempre será true
                      final bool isActive = finca['is_active'] ?? true; 
                      
                      final String abbrev = 
                          "Abr: ${finca['abreviaturaFinca'] ?? '-'}";


                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          // Icono indicando estado
                          leading: Icon(
                            Icons.location_on, 
                            color: isActive ? Colors.white : Colors.redAccent, 
                          ),
                          
                          // ➡️ Nombre de la Finca Resaltado en Blanco
                          title: Text(
                            finca['nombreFinca'] ?? 'Sin nombre',
                            style: const TextStyle( 
                              color: Colors.white, 
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          // ➡️ Subtítulo compacto con solo la abreviatura
                          subtitle: Text(
                            abbrev,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // El indicador de estado (ahora fijo en Habilitada)
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2), 
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white, // Borde blanco para activo
                              ),
                            ),
                            child: const Text(
                              "Habilitada",
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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