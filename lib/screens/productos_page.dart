import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/carrito_page.dart';



import '../models/producto.dart';

class ProductosPage extends StatefulWidget {
  final int categoriaId;
  final String categoriaNombre;
  final Map<Producto, int> carrito; // ✅ Se recibe el carrito compartido

  const ProductosPage({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.carrito,
  });

  @override
  _ProductosPageState createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  List<Producto> productos = [];
  List<Producto> productosFiltrados = [];
  late Map<Producto, int> carrito; // ✅ inicializado con widget.carrito
  Map<Producto, int> cantidadesSeleccionadas = {};
  bool isLoading = true;
  String searchText = '';

  final Map<int, String> imagenesProducto = {
    1: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1751577043/taza_vsqehr.png',
    2: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1751577043/tarjeta_agjvrc.png',
    3: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1751577043/caja_e1jsel.png',
    4: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/images_3_fonbkf.jpg',
    5: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/images_zld9mq.jpg',
    6: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/images_2_gesirh.jpg',
    7: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/descarga_3_rztdgk.jpg',
    8: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/images_1_cgbod7.jpg',
    9: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/descarga_tvyzoh.jpg',
    10: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/descarga_4_ugwubr.jpg',
    11: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000648/descarga_2_zujnjo.jpg',
    12: 'https://res.cloudinary.com/ddsakxqhd/image/upload/v1752000647/descarga_1_wu0hqs.jpg',
  };

  @override
  void initState() {
    super.initState();
    carrito = widget.carrito; // ✅ Usamos carrito compartido
    fetchProductos();
  }

  Future<void> fetchProductos() async {
    final url = Uri.parse('https://apicreartnino.somee.com/api/Productos/Lista');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List decoded = json.decode(response.body);
      final lista = decoded
          .where((p) => p['CategoriaProducto'] == widget.categoriaId)
          .map((e) => Producto.fromJson(e))
          .toList();

      setState(() {
        productos = lista;
        productosFiltrados = lista;
        cantidadesSeleccionadas = {
          for (var p in lista) p: 1,
        };
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void buscarProducto(String texto) {
    setState(() {
      searchText = texto.toLowerCase();
      productosFiltrados = productos.where((producto) {
        return producto.nombre.toLowerCase().contains(searchText);
      }).toList();
    });
  }

  void aumentarCantidad(Producto producto) {
    setState(() {
      cantidadesSeleccionadas[producto] = (cantidadesSeleccionadas[producto] ?? 1) + 1;
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
  }

  void irAlCarrito() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarritoPage(carrito: carrito),
      ),
    );
  }

  int totalItemsCarrito() {
    return carrito.values.fold(0, (sum, cantidad) => sum + cantidad);
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
                      ? const Center(child: Text("No se encontraron productos."))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = (anchoPantalla / 180).floor();
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount > 2 ? crossAxisCount : 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                              itemCount: productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto = productosFiltrados[index];
                                final imagenUrl = imagenesProducto[producto.imagenId] ?? 'https://via.placeholder.com/150';
                                final cantidad = cantidadesSeleccionadas[producto] ?? 1;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          imagenUrl,
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 100,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.broken_image, size: 40),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: SingleChildScrollView(
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        producto.nombre,
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '\$${producto.precio.toStringAsFixed(0)} COP',
                                                        style: const TextStyle(fontSize: 13, color: Colors.deepPurple, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline),
                                                    onPressed: () => disminuirCantidad(producto),
                                                  ),
                                                  Text('$cantidad'),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle_outline),
                                                    onPressed: () => aumentarCantidad(producto),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              ElevatedButton(
                                                onPressed: () => agregarAlCarrito(producto),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.pinkAccent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                ),
                                                child: const Text(
                                                  "Agregar",
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
