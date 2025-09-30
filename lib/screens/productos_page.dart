import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/carrito_page.dart';
import '../models/producto.dart';
import '../models/imagen.dart';

class ProductosPage extends StatefulWidget {
  final int categoriaId;
  final String categoriaNombre;
  final Map<Producto, int> carrito;

  const ProductosPage({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.carrito,
    super.key,
  });

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];
  late Map<Producto, int> carrito;
  Map<Producto, int> cantidadesSeleccionadas = {};
  bool isLoading = true;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    carrito = widget.carrito;
    fetchProductosYImagenes();
  }

  Future<void> fetchProductosYImagenes() async {
    final urlProductos = Uri.parse(
      'https://www.apicreartnino.somee.com/api/Productos/Lista',
    );
    final urlImagenes = Uri.parse(
      'https://www.apicreartnino.somee.com/api/Imagenes_Productos/Lista',
    );

    try {
      final respProd = await http.get(urlProductos);
      final respImgs = await http.get(urlImagenes);

      if (respProd.statusCode == 200 && respImgs.statusCode == 200) {
        final List decodedProductos = json.decode(respProd.body);
        final List decodedImagenes = json.decode(respImgs.body);

        final listaImagenes = decodedImagenes
            .map((j) => ImagenProducto.fromJson(j))
            .toList();

        final listaProductos = decodedProductos
            .where(
              (p) =>
                  p['CategoriaProducto'] == widget.categoriaId &&
                  p['Estado'] == true,
            ) // ✅ solo activos
            .map((j) => Producto.fromJson(j))
            .toList();

        for (var prod in listaProductos) {
          final img = listaImagenes.firstWhere(
            (im) => im.idImagen == prod.imagenId,
            orElse: () => ImagenProducto(idImagen: 0, url: '', descripcion: ''),
          );
          prod.imagenUrl = img.url;
        }

        setState(() {
          productos = listaProductos;
          productosFiltrados = listaProductos;
          cantidadesSeleccionadas = {for (var p in listaProductos) p: 1};
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error al cargar productos/imágenes: $e");
      setState(() => isLoading = false);
    }
  }

  void buscarProducto(String texto) {
    setState(() {
      searchText = texto.toLowerCase();
      productosFiltrados = productos
          .where(
            (producto) => producto.nombre.toLowerCase().contains(searchText),
          )
          .toList();
    });
  }

  void aumentarCantidad(Producto producto) {
    setState(() {
      cantidadesSeleccionadas[producto] =
          (cantidadesSeleccionadas[producto] ?? 1) + 1;
    });
  }

  void disminuirCantidad(Producto producto) {
    setState(() {
      final actual = cantidadesSeleccionadas[producto] ?? 1;
      if (actual > 1) {
        cantidadesSeleccionadas[producto] = actual - 1;
      }
    });
  }

  void agregarAlCarrito(Producto producto) {
    final cantidad = cantidadesSeleccionadas[producto] ?? 1;
    setState(() {
      carrito[producto] = (carrito[producto] ?? 0) + cantidad;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${producto.nombre} agregado al carrito"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void irAlCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CarritoPage(carrito: carrito)),
    );
  }

  int totalItemsCarrito() {
    return carrito.values.fold(0, (sum, cantidad) => sum + cantidad);
  }

  void mostrarDetalleProducto(Producto producto) {
    final cantidad = cantidadesSeleccionadas[producto] ?? 1;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                producto.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                '\$${producto.precio.toStringAsFixed(0)} COP',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      disminuirCantidad(producto);
                    },
                  ),
                  Text('$cantidad'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      aumentarCantidad(producto);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    agregarAlCarrito(producto);
                    Navigator.pop(context); // cerrar modal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Agregar al carrito",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF0),
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Text(widget.categoriaNombre),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 28),
                onPressed: irAlCarrito,
              ),
              if (totalItemsCarrito() > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.pink, width: 2),
                    ),
                    child: Text(
                      '${totalItemsCarrito()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔎 Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black45),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            onChanged: buscarProducto,
                            decoration: const InputDecoration(
                              hintText: 'Buscar producto',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: productosFiltrados.isEmpty
                      ? const Center(
                          child: Text("No se encontraron productos."),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = (anchoPantalla ~/ 180).clamp(
                              2,
                              6,
                            );
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.65,
                                  ),
                              itemCount: productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto = productosFiltrados[index];

                                final imagenUrl = (producto.imagenUrl != '')
                                    ? producto.imagenUrl
                                    : 'https://cdn-icons-png.flaticon.com/512/2748/2748558.png';

                                return GestureDetector(
                                  onTap: producto.cantidad > 0
                                      ? () => mostrarDetalleProducto(producto)
                                      : null,

                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                          child: Image.network(
                                            imagenUrl,
                                            height: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return Container(
                                                height: 150,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Text(
                                                producto.nombre,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              if (producto.cantidad > 0) ...[
                                                Text(
                                                  '\$${producto.precio.toStringAsFixed(0)} COP',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.deepPurple,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                const Text(
                                                  "Dar click para agregar",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ] else ...[
                                                const Text(
                                                  "AGOTADO",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
