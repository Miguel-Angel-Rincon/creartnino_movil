import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/carrito_page.dart';
import '../models/producto.dart';
import '../models/imagen.dart';
import 'package:intl/intl.dart';

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

  String formatCOP(num value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0, // 🔹 Sin decimales
    );
    return formatter.format(value);
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 🔹 Cantidad inicial siempre 1
            int cantidad = cantidadesSeleccionadas[producto] ?? 1;
            cantidadesSeleccionadas[producto] = cantidad;

            // 🔹 Aumentar cantidad
            void aumentar() {
              if (cantidad < producto.cantidad) {
                setModalState(() => cantidad++);
                setState(() => cantidadesSeleccionadas[producto] = cantidad);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Solo hay ${producto.cantidad} disponibles",
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.pinkAccent,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }

            // 🔹 Disminuir cantidad
            void disminuir() {
              if (cantidad > 1) {
                setModalState(() => cantidad--);
                setState(() => cantidadesSeleccionadas[producto] = cantidad);
              }
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🏷️ Nombre
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  // 💰 Precio con formato COP
                  Text(
                    formatCOP(producto.precio),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // 📦 Disponibles
                  Text(
                    'Disponibles: ${producto.cantidad}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),

                  const SizedBox(height: 15),

                  // 🔢 Selector de cantidad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.pinkAccent,
                          size: 28,
                        ),
                        onPressed: disminuir,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.pinkAccent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$cantidad',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.pinkAccent,
                          size: 28,
                        ),
                        onPressed: aumentar,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🛒 Botón agregar al carrito
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        agregarAlCarrito(producto);
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Agregar al carrito",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
                                                  '${formatCOP(producto.precio)}',
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
