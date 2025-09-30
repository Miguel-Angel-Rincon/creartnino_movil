class Categoria {
  final int id;
  final String nombre;
  final String descripcion;
  final bool estado;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json["IdCategoriaProducto"] is int
          ? json["IdCategoriaProducto"]
          : int.tryParse(json["IdCategoriaProducto"].toString()) ?? 0,
      nombre: json["CategoriaProducto1"]?.toString() ?? "Sin nombre",
      descripcion: json["Descripcion"]?.toString() ?? "",
      estado: _parseEstado(json["Estado"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "IdCategoriaProducto": id,
    "CategoriaProducto1": nombre,
    "Descripcion": descripcion,
    "Estado": estado,
  };

  /// 🔹 Conversión segura de Estado a bool
  static bool _parseEstado(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == "true" || value == "1";
    }
    return false;
  }
}
