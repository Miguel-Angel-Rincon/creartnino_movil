class Producto {
  final int id;
  final int categoriaId;
  final String nombre;
  final int imagenId;
  final int cantidad;
  final String marca;
  final double precio;
  final bool estado;

  Producto({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    required this.imagenId,
    required this.cantidad,
    required this.marca,
    required this.precio,
    required this.estado,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['IdProducto'],
      categoriaId: json['CategoriaProducto'],
      nombre: json['Nombre'],
      imagenId: json['Imagen'],
      cantidad: json['Cantidad'],
      marca: json['Marca'],
      precio: (json['Precio'] as num).toDouble(),
      estado: json['Estado'],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Producto && runtimeType == other.runtimeType && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  int get idProducto => id;
}
