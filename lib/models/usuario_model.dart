class Usuario {
  final int idUsuarios;
  final String nombreCompleto;
  final String tipoDocumento;
  final String numDocumento;
  final String celular;
  final String departamento;
  final String ciudad;
  final String? direccion;
  final String correo;
  final String? contrasena;
  final int idRol;
  final bool estado;

  Usuario({
    required this.idUsuarios,
    required this.nombreCompleto,
    required this.tipoDocumento,
    required this.numDocumento,
    required this.celular,
    required this.departamento,
    required this.ciudad,
    this.direccion,
    required this.correo,
    this.contrasena,
    required this.idRol,
    required this.estado,
  });

  /// Constructor desde JSON general (API principal)
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuarios: json['idUsuarios'] ?? json['IdUsuarios'] ?? 0,
      nombreCompleto: json['nombreCompleto'] ?? '',
      tipoDocumento: json['tipoDocumento'] ?? '',
      numDocumento: json['numDocumento'] ?? '',
      celular: json['celular'] ?? '',
      departamento: json['departamento'] ?? '',
      ciudad: json['ciudad'] ?? '',
      direccion: json['direccion'],
      correo: json['correo'] ?? '',
      contrasena: json['contrasena'],
      idRol: json['idRol'] ?? 0,
      estado: json['estado'] ?? true,
    );
  }

  /// Constructor desde JSON para perfil (sin contraseña ni campos sensibles)
  factory Usuario.perfilFromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuarios: json['idUsuarios'] ?? json['IdUsuarios'] ?? 0,
      nombreCompleto: json['nombreCompleto'] ?? '',
      tipoDocumento: json['tipoDocumento'] ?? '',
      numDocumento: json['numDocumento'] ?? '',
      celular: json['celular'] ?? '',
      departamento: json['departamento'] ?? '',
      ciudad: json['ciudad'] ?? '',
      direccion: json['direccion'],
      correo: json['correo'] ?? '',
      contrasena: null,
      idRol: json['idRol'] ?? 0,
      estado: json['estado'] ?? true,
    );
  }

  /// Convertir a JSON (para envío o almacenamiento)
  Map<String, dynamic> toJson() {
    return {
      'idUsuarios': idUsuarios,
      'nombreCompleto': nombreCompleto,
      'tipoDocumento': tipoDocumento,
      'numDocumento': numDocumento,
      'celular': celular,
      'departamento': departamento,
      'ciudad': ciudad,
      'direccion': direccion,
      'correo': correo,
      'contrasena': contrasena,
      'idRol': idRol,
      'estado': estado,
    };
  }

  /// Convertir a JSON seguro (para guardar en preferencias, sin contraseña)
  Map<String, dynamic> toJsonSafe() {
    return {
      'idUsuarios': idUsuarios,
      'nombreCompleto': nombreCompleto,
      'tipoDocumento': tipoDocumento,
      'numDocumento': numDocumento,
      'celular': celular,
      'departamento': departamento,
      'ciudad': ciudad,
      'direccion': direccion,
      'correo': correo,
      'idRol': idRol,
      'estado': estado,
    };
  }
}
