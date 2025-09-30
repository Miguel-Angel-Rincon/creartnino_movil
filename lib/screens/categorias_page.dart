import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/categoria.dart';
import 'productos_page.dart';
import '../models/producto.dart';

class CategoriasPage extends StatefulWidget {
  @override
  _CategoriasPageState createState() => _CategoriasPageState();
}

class _CategoriasPageState extends State<CategoriasPage> {
  List<Categoria> categorias = [];
  List<Categoria> categoriasFiltradas = [];
  bool isLoading = true;
  bool isError = false;
  String searchText = '';

  // ✅ Carrito compartido entre todas las categorías
  final Map<Producto, int> carritoGlobal = {};

  final String imagenDefault =
      'https://res.cloudinary.com/ddsakxqhd/image/upload/v1751577043/topper_a4mfcj.png';

  final Map<int, String> imagenesCategoria = {
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
    fetchCategorias();
  }

  Future<void> fetchCategorias() async {
    setState(() {
      isLoading = true;
      isError = false;
    });

    try {
      final url = Uri.parse(
        'https://apicreartnino.somee.com/api/Categoria_productos/Lista',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List decoded = json.decode(response.body);
        final lista = decoded.map((e) => Categoria.fromJson(e)).toList();

        setState(() {
          categorias = lista;
          categoriasFiltradas = lista;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  void filtrarCategorias(String texto) {
    setState(() {
      searchText = texto.toLowerCase();
      categoriasFiltradas = categorias
          .where((c) => c.nombre.toLowerCase().contains(searchText))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEBF0),
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text('Seleccionar Categoría'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error al cargar categorías.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: fetchCategorias,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : categorias.isEmpty
          ? const Center(
              child: Text(
                'No hay categorías disponibles.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Selecciona la categoría de tu interes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: filtrarCategorias,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Buscar',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  categoriasFiltradas.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text(
                              'No se encontraron coincidencias.',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : Expanded(
                          child: GridView.builder(
                            itemCount: categoriasFiltradas.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                            itemBuilder: (context, index) {
                              final categoria = categoriasFiltradas[index];
                              final imagenUrl =
                                  imagenesCategoria[categoria.id] ??
                                  imagenDefault;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductosPage(
                                        categoriaId: categoria.id,
                                        categoriaNombre: categoria.nombre,
                                        carrito:
                                            carritoGlobal, // ✅ Pasamos carrito compartido
                                      ),
                                    ),
                                  );
                                },
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                        child: Image.network(
                                          imagenUrl,
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    height: 100,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          categoria.nombre,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
