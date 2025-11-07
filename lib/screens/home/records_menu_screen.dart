import 'package:flutter/material.dart';
import '../home/theme/dark_theme.dart';
import '../fincas/finca_list_screen.dart';
import '../fincas/finca_create_screen.dart';
import '../fincas/finca_delete_screen.dart';

class RecordsMenuScreen extends StatelessWidget {
  final String mode; // "view" o "edit"

  const RecordsMenuScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    final isEdit = mode == 'edit';

    return Scaffold(
      backgroundColor: GeoFloraTheme.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Editar Registros' : 'Ver Registros',
        ),
        backgroundColor: Colors.black.withOpacity(0.7),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildCard(
            context,
            icon: Icons.agriculture_outlined,
            color: Colors.greenAccent,
            title: "Fincas",
            subtitle: isEdit
                ? "Crear, modificar o inhabilitar fincas."
                : "Consultar información de las fincas.",
            onTap: () {
              if (isEdit) {
                _abrirMenuFincas(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FincaListScreen(),
                  ),
                );
              }
            },
          ),
          // En el futuro puedes agregar más módulos aquí, por ejemplo:
          // _buildCard(..., title: "Cultivos", ...)
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 20)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  void _abrirMenuFincas(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: Colors.greenAccent),
                title: const Text("Registrar Nueva Finca",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FincaCreateScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.amberAccent),
                title: const Text("Editar Fincas",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FincaListScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: const Text("Inhabilitar Fincas",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FincaDeleteScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
