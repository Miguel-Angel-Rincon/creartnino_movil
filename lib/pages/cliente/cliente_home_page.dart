import 'dart:convert';
import 'package:creartnino/pages/cliente/PedidosPageCliente.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../widgets/pastel_bottom_navbar.dart';
import '../perfil/perfil_page.dart';
import '../../models/categoria.dart';
import '../../models/producto.dart';
import '../../screens/productos_page.dart';

class ClienteHomePageConCategorias extends StatefulWidget {
  const ClienteHomePageConCategorias({super.key});

  @override
  State<ClienteHomePageConCategorias> createState() =>
      _ClienteHomePageConCategoriasState();
}

class _ClienteHomePageConCategoriasState
    extends State<ClienteHomePageConCategorias> {
  int _currentIndex = 0;
  String? numDocumento;
  bool isLoadingUser = true;

  List<Categoria> categorias = [];
  List<Categoria> categoriasFiltradas = [];
  bool isLoadingCategorias = true;
  bool isError = false;
  String searchText = '';
  final Map<Producto, int> carritoGlobal = {};

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
    fetchCategorias();
  }

  Future<void> cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final doc = prefs.getString('NumDocumento') ?? '';
    print("🔐 Documento del usuario logueado: $doc");
    setState(() {
      numDocumento = doc;
      isLoadingUser = false;
    });
  }

  Future<void> fetchCategorias() async {
    setState(() {
      isLoadingCategorias = true;
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
          // ✅ Solo categorías activas
          categorias = lista.where((c) => c.estado).toList();
          categoriasFiltradas = categorias;
          isLoadingCategorias = false;
        });
      } else {
        setState(() {
          isLoadingCategorias = false;
          isError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingCategorias = false;
        isError = true;
      });
    }
  }

  void filtrarCategorias(String texto) {
    setState(() {
      searchText = texto.toLowerCase();
      categoriasFiltradas = categorias
          .where((c) => c.estado && c.nombre.toLowerCase().contains(searchText))
          .toList();
    });
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Widget _buildCategoriasView() {
    if (isLoadingCategorias) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isError) {
      return Center(
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
      );
    }

    if (categoriasFiltradas.isEmpty) {
      return const Center(child: Text('No hay categorías disponibles.'));
    }

    return RefreshIndicator(
      onRefresh: fetchCategorias, // ✅ Deslizar para refrescar
      child: Padding(
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
                    'Selecciona la categoría de tu interés',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
            Expanded(
              child: GridView.builder(
                itemCount: categoriasFiltradas.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final categoria = categoriasFiltradas[index];
                  const imagenUrl =
                      'https://res.cloudinary.com/creartnino/image/upload/v1759268895/logorina_g3ixkd.png';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductosPage(
                            categoriaId: categoria.id,
                            categoriaNombre: categoria.nombre,
                            carrito: carritoGlobal,
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
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              imagenUrl,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
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

  @override
  Widget build(BuildContext context) {
    if (isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> pages = [
      _buildCategoriasView(), // Inicio
      PedidosPageCliente(numDocumentoUsuario: numDocumento ?? ''),
      const PerfilPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: PastelBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        esAdmin: false,
        onLogout: _cerrarSesion,
      ),
    );
  }
}
