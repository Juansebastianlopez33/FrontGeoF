// lib/models/user_model.dart

class User {
  final String cedula;
  final String nombre;
  final String tipoDocumento;
  final String? telefono;
  final String correo;
  final String rol;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.cedula,
    required this.nombre,
    required this.tipoDocumento,
    this.telefono,
    required this.correo,
    this.rol = 'user',
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  // ==========================================================
  // Factory: crear User desde JSON (tal como llega del backend Flask)
  // ==========================================================
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      cedula: json['cedula'] ?? '',
      nombre: json['nombre'] ?? '',
      tipoDocumento: json['tipo_documento'] ?? '',
      telefono: json['telefono'],
      correo: json['correo'] ?? '',
      rol: json['rol'] ?? 'user',
      isActive: json['is_active'] ?? true,
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // ==========================================================
  // Convertir a JSON (por ejemplo, para editar o crear)
  // ==========================================================
  Map<String, dynamic> toJson() {
    return {
      'cedula': cedula,
      'nombre': nombre,
      'tipo_documento': tipoDocumento,
      'telefono': telefono,
      'correo': correo,
      'rol': rol,
      'is_active': isActive,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // ==========================================================
  // Copiar con cambios (útil en formularios o actualización)
  // ==========================================================
  User copyWith({
    String? nombre,
    String? telefono,
    String? correo,
    String? rol,
    bool? isActive,
  }) {
    return User(
      cedula: cedula,
      nombre: nombre ?? this.nombre,
      tipoDocumento: tipoDocumento,
      telefono: telefono ?? this.telefono,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ==========================================================
  // Debug / impresión
  // ==========================================================
  @override
  String toString() {
    return 'User(cedula: $cedula, nombre: $nombre, correo: $correo, rol: $rol, activo: $isActive)';
  }
}
