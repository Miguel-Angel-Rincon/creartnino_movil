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
      id: json['IdCategoriaProducto'],
      nombre: json['CategoriaProducto1'],
      descripcion: json['Descripcion'],
      estado: json['Estado'],
    );
  }
}
