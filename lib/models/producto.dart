class Producto {
  final int id;
  final int categoriaId;
  final String nombre;
  final int imagenId; // ese campo “Imagen” del JSON
  final int cantidad;
  final String marca;
  final double precio;
  final bool estado;

  String imagenUrl; // vamos a asignarle esta URL luego

  Producto({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    required this.imagenId,
    required this.cantidad,
    required this.marca,
    required this.precio,
    required this.estado,
    this.imagenUrl = '',
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
}
