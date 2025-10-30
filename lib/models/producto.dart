class Producto {
  final int id;
  final int categoriaId;
  final String nombre;
  final int? imagenId; // puede venir null
  final String descripcion;
  final int cantidad;
  final String marca;
  final double precio;
  final bool estado;

  String imagenUrl; // se llenará después
  List<String> imagenesUrls; // para el carrusel

  Producto({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    required this.imagenId,
    required this.descripcion,
    required this.cantidad,
    required this.marca,
    required this.precio,
    required this.estado,
    this.imagenUrl = '',
    this.imagenesUrls = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['IdProducto'] ?? 0,
      categoriaId: json['CategoriaProducto'] ?? 0,
      nombre: json['Nombre'] ?? '',
      imagenId: json['Imagen'],
      descripcion: json['Descripcion'] ?? '',
      cantidad: json['Cantidad'] ?? 0,
      marca: json['Marca'] ?? '',
      precio: (json['Precio'] ?? 0).toDouble(),
      estado: json['Estado'] ?? false,
    );
  }
}
