// PedidosPageAdmin.dart

import 'dart:convert';
import 'package:creartnino/pages/admin/CrearPedidoPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Pedido {
  final int idPedido;
  final int idCliente;
  final String metodoPago;
  final String fechaPedido;
  final String fechaEntrega;
  final String descripcion;
  final int valorInicial;
  final int valorRestante;
  final int totalPedido;
  final String comprobantePago;
  int idEstado;
  Map<String, dynamic>? idClienteNavigation;
  Map<String, dynamic>? idEstadoNavigation;

  Pedido({
    required this.idPedido,
    required this.idCliente,
    required this.metodoPago,
    required this.fechaPedido,
    required this.fechaEntrega,
    required this.descripcion,
    required this.valorInicial,
    required this.valorRestante,
    required this.totalPedido,
    required this.comprobantePago,
    required this.idEstado,
    this.idClienteNavigation,
    this.idEstadoNavigation,
  });

  factory Pedido.fromJson(
    Map<String, dynamic> json,
    Map<int, dynamic> estadosMap,
    Map<int, dynamic> clientesMap,
  ) {
    final idCliente = int.tryParse(json['IdCliente'].toString()) ?? 0;
    final idEstado = int.tryParse(json['IdEstado'].toString()) ?? 0;

    return Pedido(
      idPedido: json['IdPedido'],
      idCliente: idCliente,
      metodoPago: json['MetodoPago'],
      fechaPedido: json['FechaPedido'],
      fechaEntrega: json['FechaEntrega'],
      descripcion: json['Descripcion'],
      valorInicial: json['ValorInicial'],
      valorRestante: json['ValorRestante'],
      totalPedido: json['TotalPedido'],
      comprobantePago: json['ComprobantePago'],
      idEstado: idEstado,
      idClienteNavigation: clientesMap[idCliente],
      idEstadoNavigation: estadosMap[idEstado],
    );
  }
}

class PedidosPageAdmin extends StatefulWidget {
  const PedidosPageAdmin({super.key});

  @override
  State<PedidosPageAdmin> createState() => _PedidosPageAdminState();
}

class _PedidosPageAdminState extends State<PedidosPageAdmin> {
  List<Pedido> pedidos = [];
  List<Pedido> pedidosFiltrados = []; // ✅ Lista para los resultados de búsqueda
  Map<int, dynamic> estadosMap = {};
  Map<int, dynamic> productosMap = {};
  bool isLoading = true;
  List<int> expandedCards = [];
  TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPedidos();
  }

  void _filtrarPedidos(String query) {
    final texto = query.trim().toLowerCase();

    if (texto.isEmpty) {
      pedidosFiltrados = [];
      return;
    }

    pedidosFiltrados = pedidos.where((pedido) {
      final nombre =
          pedido.idClienteNavigation?['NombreCompleto']
              ?.toString()
              .toLowerCase() ??
          '';
      final documento =
          pedido.idClienteNavigation?['NumDocumento']
              ?.toString()
              .toLowerCase() ??
          '';

      return nombre.contains(texto) || documento.contains(texto);
    }).toList();
  }

  Future<void> fetchPedidos() async {
    try {
      final pedidosRes = await http.get(
        Uri.parse('https://www.apicreartnino.somee.com/api/Pedidos/Lista'),
      );
      final clientesRes = await http.get(
        Uri.parse('https://www.apicreartnino.somee.com/api/Clientes/Lista'),
      );
      final estadosRes = await http.get(
        Uri.parse(
          'https://www.apicreartnino.somee.com/api/Estados_Pedido/Lista',
        ),
      );
      final productosRes = await http.get(
        Uri.parse('https://www.apicreartnino.somee.com/api/Productos/Lista'),
      );

      if (pedidosRes.statusCode == 200 &&
          clientesRes.statusCode == 200 &&
          estadosRes.statusCode == 200 &&
          productosRes.statusCode == 200) {
        final pedidosData = json.decode(pedidosRes.body);
        final clientesData = json.decode(clientesRes.body);
        final estadosData = json.decode(estadosRes.body);
        final productosData = json.decode(productosRes.body);

        final Map<int, dynamic> clientesMap = {
          for (var cliente in clientesData)
            int.tryParse(cliente['IdCliente'].toString()) ?? 0: cliente,
        };

        estadosMap = {
          for (var estado in estadosData)
            int.tryParse(estado['IdEstadoPedidos'].toString()) ?? 0: estado,
        };

        productosMap = {
          for (var p in productosData)
            int.tryParse(p['IdProducto'].toString()) ?? 0: p,
        };

        if (!mounted) return;
        setState(() {
          pedidos = List<Pedido>.from(
            pedidosData.map((p) => Pedido.fromJson(p, estadosMap, clientesMap)),
          );

          // ✅ Orden descendente por IdPedido (últimos pedidos primero)
          pedidos.sort((a, b) => b.idPedido.compareTo(a.idPedido));

          // Si quieres por fecha en vez de IdPedido:
          // pedidos.sort((a, b) =>
          //   DateTime.parse(b.fechaPedido).compareTo(DateTime.parse(a.fechaPedido)));

          isLoading = false;
        });
      } else {
        throw Exception('Error al cargar datos');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al cargar pedidos")),
      );
    }
  }

  Future<List<dynamic>> fetchDetalles(int idPedido) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://www.apicreartnino.somee.com/api/Detalles_Pedido/Lista',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data.where((d) => d['IdPedido'] == idPedido).toList();
      } else {
        throw Exception('Error al cargar detalles');
      }
    } catch (e) {
      return [];
    }
  }

  int _paginaActual = 1;
  int _itemsPorPagina = 3;

  void mostrarDetalleModal(BuildContext context, int idPedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.pink[50],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long, size: 40, color: Colors.pink),
              const SizedBox(height: 10),
              const Text(
                'Detalle del Pedido',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(thickness: 1, height: 24),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: FutureBuilder<List<dynamic>>(
                  future: fetchDetalles(idPedido),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text("❌ Error al cargar detalles"),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("No hay detalles del pedido."),
                      );
                    }

                    final detalles = snapshot.data!;
                    return ListView.separated(
                      itemCount: detalles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final detalle = detalles[index];
                        final idProducto = detalle['IdProducto'] ?? 0;
                        final producto = productosMap[idProducto] ?? {};
                        final nombre =
                            producto['Nombre'] ?? 'Producto desconocido';
                        final precio = producto['Precio'] ?? 0;
                        final cantidad = detalle['Cantidad'] ?? 0;
                        final subtotal = cantidad * precio;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.price_check,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Precio: ${formatCOP(precio)}'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.confirmation_number,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Cantidad: $cantidad'),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calculate_outlined,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Subtotal: ${formatCOP(subtotal)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text("Cerrar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String formatCOP(num value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0, // 🔹 Sin decimales
    );
    return formatter.format(value);
  }

  Color _colorEstado(int idEstado) {
    final nombre =
        estadosMap[idEstado]?['NombreEstado']?.toString().toLowerCase() ?? '';
    if (nombre.contains('primer pago')) return Colors.orangeAccent;
    if (nombre.contains('en proceso')) return Colors.amber;
    if (nombre.contains('en producción')) return Colors.lightBlueAccent;
    if (nombre.contains('proceso de entrega')) return Colors.cyan;
    if (nombre.contains('entregado')) return Colors.green;
    if (nombre.contains('anulado')) return Colors.redAccent;
    return Colors.grey;
  }

  bool _puedeAnular(int idEstado) {
    // No se puede anular si está en: Entregado (5), En proceso de entrega (4),
    // Anulado (6) o Venta Directa (7)
    return !(idEstado == 4 || idEstado == 5 || idEstado == 6 || idEstado == 7);
  }

  void _mostrarMenuEstados(Pedido pedido) {
    final estadoActual =
        pedido.idEstadoNavigation?['NombreEstado']?.toString().toLowerCase() ??
        '';

    List<MapEntry<int, dynamic>> estadosFiltrados = [];

    if (estadoActual.contains("proceso de entrega")) {
      // 👉 solo se puede pasar a Entregado
      estadosFiltrados = estadosMap.entries.where((entry) {
        final nombre =
            entry.value['NombreEstado']?.toString().toLowerCase() ?? '';
        return nombre.contains("entregado");
      }).toList();
    } else if (estadoActual.contains("entregado") ||
        estadoActual.contains("anulado") ||
        estadoActual.contains("venta directa") ||
        estadoActual.contains("producción")) {
      // 👉 no se puede cambiar más
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Este pedido no puede cambiar de estado"),
        ),
      );
      return;
    } else {
      // 👉 en los demás casos solo "Primer pago" y "En proceso"
      estadosFiltrados = estadosMap.entries.where((entry) {
        final nombre =
            entry.value['NombreEstado']?.toString().toLowerCase() ?? '';
        return nombre == "primer pago" || nombre == "en proceso";
      }).toList();
    }

    if (estadosFiltrados.isEmpty) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: estadosFiltrados.map((entry) {
            return ListTile(
              title: Text(entry.value['NombreEstado'] ?? ''),
              onTap: () {
                Navigator.pop(context);
                actualizarEstado(pedido, entry.key);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> actualizarEstado(Pedido pedido, int nuevoIdEstado) async {
    final url = Uri.parse(
      'https://www.apicreartnino.somee.com/api/Pedidos/Actualizar/${pedido.idPedido}',
    );
    final body = jsonEncode({
      "idPedido": pedido.idPedido,
      "idCliente": pedido.idCliente,
      "metodoPago": pedido.metodoPago,
      "fechaPedido": pedido.fechaPedido,
      "fechaEntrega": pedido.fechaEntrega,
      "descripcion": pedido.descripcion,
      "valorInicial": pedido.valorInicial,
      "valorRestante": pedido.valorRestante,
      "totalPedido": pedido.totalPedido,
      "comprobantePago": pedido.comprobantePago,
      "idEstado": nuevoIdEstado,
    });

    final res = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (res.statusCode == 200) {
      setState(() {
        pedido.idEstado = nuevoIdEstado;
        pedido.idEstadoNavigation = estadosMap[nuevoIdEstado];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Estado actualizado correctamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al actualizar estado: ${res.body}")),
      );
    }
  }

  Future<void> anularPedido(Pedido pedido) async {
    // 1️⃣ Buscar estado "Anulado"
    final anulado = estadosMap.entries.firstWhere(
      (e) => e.value['NombreEstado']?.toString().toLowerCase() == 'anulado',
      orElse: () => MapEntry(-1, {}),
    );

    if (anulado.key == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Estado 'Anulado' no encontrado")),
      );
      return;
    }

    // 2️⃣ Confirmación
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar anulación"),
        content: const Text("¿Estás seguro de que deseas anular este pedido?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Sí, anular"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      // 3️⃣ Actualizar estado del pedido a "Anulado"
      final body = {
        "idPedido": pedido.idPedido,
        "idCliente": pedido.idCliente,
        "metodoPago": pedido.metodoPago,
        "fechaPedido": pedido.fechaPedido,
        "fechaEntrega": pedido.fechaEntrega,
        "descripcion": pedido.descripcion,
        "valorInicial": pedido.valorInicial,
        "valorRestante": pedido.valorRestante,
        "totalPedido": pedido.totalPedido,
        "comprobantePago": pedido.comprobantePago,
        "idEstado": anulado.key, // 👈 tomado de estadosMap
      };

      final res = await http.put(
        Uri.parse(
          'https://www.apicreartnino.somee.com/api/Pedidos/Actualizar/${pedido.idPedido}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        throw Exception("No se pudo anular el pedido");
      }

      // 4️⃣ Obtener detalles del pedido
      final rDet = await http.get(
        Uri.parse(
          "https://www.apicreartnino.somee.com/api/Detalles_Pedido/Lista",
        ),
      );

      if (rDet.statusCode != 200) {
        throw Exception("No se pudieron obtener los detalles");
      }

      final allDetalles = jsonDecode(rDet.body) as List;
      final detalles = allDetalles
          .where((d) => d['IdPedido'] == pedido.idPedido)
          .toList();

      // 5️⃣ Devolver stock de cada producto
      for (final det in detalles) {
        final rProd = await http.get(
          Uri.parse(
            "https://www.apicreartnino.somee.com/api/Productos/Obtener/${det['IdProducto']}",
          ),
        );
        if (rProd.statusCode != 200) continue;

        final producto = jsonDecode(rProd.body);

        final actualizado = {
          "IdProducto": producto['IdProducto'],
          "CategoriaProducto": producto['CategoriaProducto'],
          "Nombre": producto['Nombre'],
          "Imagen": producto['Imagen'],
          "Cantidad": (producto['Cantidad'] ?? 0) + (det['Cantidad'] ?? 0),
          "Marca": producto['Marca'],
          "Precio": producto['Precio'],
          "Estado": producto['Estado'],
        };

        final rUpd = await http.put(
          Uri.parse(
            "https://www.apicreartnino.somee.com/api/Productos/Actualizar/${det['IdProducto']}",
          ),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(actualizado),
        );

        if (rUpd.statusCode != 200) {
          debugPrint(
            "❌ Error al devolver stock del producto ${det['IdProducto']}: ${rUpd.body}",
          );
        }
      }

      // 6️⃣ Refrescar pedidos
      await fetchPedidos();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Pedido anulado y stock devuelto")),
      );
    } catch (e) {
      debugPrint("❌ Error en anularPedido: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No se pudo anular el pedido")),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    // 🔹 Calcular lista base (según búsqueda)
    final bool hayBusqueda = _busquedaController.text.trim().isNotEmpty;
    final listaBase = hayBusqueda ? pedidosFiltrados : pedidos;

    // 🔹 Calcular paginación real
    final totalPaginas = (listaBase.length / _itemsPorPagina)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();
    if (_paginaActual > totalPaginas) _paginaActual = 1;

    final inicio = (_paginaActual - 1) * _itemsPorPagina;
    final fin = (inicio + _itemsPorPagina > listaBase.length)
        ? listaBase.length
        : inicio + _itemsPorPagina;
    final listaMostrar = listaBase.sublist(inicio, fin);

    return SafeArea(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20, top: 16, bottom: 8),
                  child: Text(
                    "📋 Lista de Pedidos",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                // 🔍 Barra de búsqueda + botón crear
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _busquedaController,
                          decoration: InputDecoration(
                            hintText: '🔍 Buscar por cliente...',
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _filtrarPedidos(value);
                              _paginaActual =
                                  1; // 🔄 Reiniciar paginación al filtrar
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.pinkAccent,
                          size: 32,
                        ),
                        tooltip: 'Crear nuevo pedido',
                        onPressed: () async {
                          final creado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CrearPedidoPage(),
                            ),
                          );
                          if (creado == true) fetchPedidos();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 🧾 Lista principal
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: listaMostrar.length,
                    itemBuilder: (context, index) {
                      final pedido = listaMostrar[index];
                      final isExpanded = expandedCards.contains(index);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              expandedCards.remove(index);
                            } else {
                              expandedCards.add(index);
                            }
                          });
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: Colors.white,
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      pedido.idClienteNavigation?['NombreCompleto'] ??
                                          'Cliente desconocido',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('📅 Fecha: ${pedido.fechaPedido}'),
                                Text(
                                  '💰 Inicial: ${formatCOP(pedido.valorInicial)}',
                                ),
                                Text(
                                  '💵 Total: ${formatCOP(pedido.totalPedido)}',
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Estado: '),
                                    GestureDetector(
                                      onTap: () => _mostrarMenuEstados(pedido),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _colorEstado(pedido.idEstado),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          pedido.idEstadoNavigation?['NombreEstado'] ??
                                              'Desconocido',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      tooltip: 'Ver detalle',
                                      onPressed: () {
                                        mostrarDetalleModal(
                                          context,
                                          pedido.idPedido,
                                        );
                                      },
                                    ),
                                    if (_puedeAnular(pedido.idEstado))
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Anular pedido',
                                        onPressed: () => anularPedido(pedido),
                                      ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  const Divider(height: 24, thickness: 1),
                                  Text(
                                    '🧾 Método de pago: ${pedido.metodoPago}',
                                  ),
                                  Text('📦 Entrega: ${pedido.fechaEntrega}'),
                                  Text('📝 Descripción: ${pedido.descripcion}'),
                                  Text(
                                    '💳 Restante: ${formatCOP(pedido.valorRestante)}',
                                  ),
                                  Text(
                                    '📁 Comprobante: ${pedido.comprobantePago}',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 🔸 Paginación visible tanto con o sin búsqueda
                if (listaBase.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: _paginaActual > 1
                                  ? Colors.blueAccent
                                  : Colors.grey[300],
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: _paginaActual > 1
                                    ? () => setState(() => _paginaActual--)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "Página $_paginaActual de $totalPaginas",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              backgroundColor: _paginaActual < totalPaginas
                                  ? const Color.fromARGB(255, 243, 160, 242)
                                  : Colors.grey[300],
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                                onPressed: _paginaActual < totalPaginas
                                    ? () => setState(() => _paginaActual++)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
