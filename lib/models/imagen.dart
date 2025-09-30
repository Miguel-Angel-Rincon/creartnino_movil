class ImagenProducto {
  final int idImagen;
  final String url;
  final String descripcion;

  ImagenProducto({
    required this.idImagen,
    required this.url,
    required this.descripcion,
  });

  factory ImagenProducto.fromJson(Map<String, dynamic> json) {
    return ImagenProducto(
      idImagen: json['IdImagen'],
      url: json['Url'] ?? '',
      descripcion: json['Descripcion'] ?? '',
    );
  }
}
