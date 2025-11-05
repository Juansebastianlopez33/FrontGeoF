// lib/models/user_model.dart

class User {
  final String cedula;
  final String nombre;
  final String tipoDocumento;
  final String? telefono;
  final String correo;

  User({
    required this.cedula,
    required this.nombre,
    required this.tipoDocumento,
    this.telefono,
    required this.correo,
  });

  // Método de fábrica para crear una instancia de User desde un mapa JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Usamos los nombres de clave (keys) tal como los devuelve la API Flask
      cedula: json['cedula'] ?? '',
      nombre: json['nombre'] ?? '',
      tipoDocumento: json['tipo_documento'] ?? '', // Nota el snake_case
      telefono: json['telefono'], // Puede ser null
      correo: json['correo'] ?? '',
    );
  }

  // Método opcional para imprimir el objeto
  @override
  String toString() {
    return 'User(cedula: $cedula, nombre: $nombre, correo: $correo)';
  }
}