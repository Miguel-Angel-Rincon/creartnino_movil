import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PedidosPageCliente extends StatefulWidget {
  final String numDocumentoUsuario;

  const PedidosPageCliente({required this.numDocumentoUsuario, super.key});

  @override
  State<PedidosPageCliente> createState() => _PedidosPageClienteState();
}

class _PedidosPageClienteState extends State<PedidosPageCliente> {
  List<dynamic> pedidosCliente = [];
  Map<int, dynamic> estadosMap = {};
  Map<int, dynamic> productosMap = {};
  bool isLoading = true;
  bool noEsCliente = false;

  DateTime? fechaDesde;
  DateTime? fechaHasta;

  int paginaActual = 1;
  int pedidosPorPagina = 3;

  @override
  void initState() {
    super.initState();
    fetchPedidosDelCliente();
  }

  @override
  void didUpdateWidget(covariant PedidosPageCliente oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.numDocumentoUsuario != widget.numDocumentoUsuario) {
      fetchPedidosDelCliente();
    }
  }

  Future<void> fetchPedidosDelCliente() async {
    setState(() {
      isLoading = true;
      pedidosCliente = [];
      noEsCliente = false;
    });

    final documentoUsuario = widget.numDocumentoUsuario.trim();
    print('🔍 Buscando pedidos para usuario: "$documentoUsuario"');

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
        final pedidos = json.decode(pedidosRes.body);
        final clientes = json.decode(clientesRes.body);
        final estados = json.decode(estadosRes.body);
        final productos = json.decode(productosRes.body);

        print(
          "📋 Lista de documentos en clientes: ${clientes.map((c) => c['NumDocumento'].toString().trim()).toList()}",
        );

        final clienteActual = clientes.firstWhere(
          (c) => c['NumDocumento'].toString().trim() == documentoUsuario,
          orElse: () => null,
        );

        if (clienteActual == null) {
          print("❌ No se encontró cliente con documento $documentoUsuario");
          setState(() {
            noEsCliente = true;
            isLoading = false;
          });
          return;
        }

        final idCliente = clienteActual['IdCliente'];
        print("✅ Cliente encontrado. ID: $idCliente");

        estadosMap = {
          for (var estado in estados)
            int.tryParse(estado['IdEstadoPedidos'].toString()) ?? 0: estado,
        };

        productosMap = {
          for (var p in productos)
            int.tryParse(p['IdProducto'].toString()) ?? 0: p,
        };

        List<dynamic> filtrados = pedidos
            .where((p) => p['IdCliente'] == idCliente)
            .toList();

        print("📦 Pedidos encontrados: ${filtrados.length}");

        filtrados.sort((a, b) => b['IdPedido'].compareTo(a['IdPedido']));

        setState(() {
          pedidosCliente = filtrados;
          isLoading = false;
          paginaActual = 1;
        });
      } else {
        print("❌ Error al obtener datos de la API.");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Excepción al obtener pedidos: $e");
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
      }
    } catch (_) {}
    return [];
  }

  Future<void> anularPedido(int idPedido) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar anulación"),
        content: const Text("¿Estás seguro de que deseas anular este pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Anular", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final pedido = pedidosCliente.firstWhere(
      (p) => p['IdPedido'] == idPedido,
      orElse: () => null,
    );
    if (pedido == null) return;

    final body = {
      "idPedido": pedido['IdPedido'],
      "idCliente": pedido['IdCliente'],
      "metodoPago": pedido['MetodoPago'],
      "fechaPedido": pedido['FechaPedido'],
      "fechaEntrega": pedido['FechaEntrega'],
      "descripcion": pedido['Descripcion'],
      "valorInicial": pedido['ValorInicial'],
      "valorRestante": pedido['ValorRestante'],
      "totalPedido": pedido['TotalPedido'],
      "comprobantePago": pedido['ComprobantePago'],
      "idEstado": 6,
    };

    try {
      final response = await http.put(
        Uri.parse(
          'https://www.apicreartnino.somee.com/api/Pedidos/Actualizar/$idPedido',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        fetchPedidosDelCliente();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pedido anulado exitosamente")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ No se pudo anular el pedido")),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al conectar con el servidor")),
      );
    }
  }

  Color _colorEstado(int idEstado) {
    final nombre =
        estadosMap[idEstado]?['NombreEstado']?.toString().toLowerCase() ?? '';
    if (nombre.contains('primer pago')) return Colors.orange;
    if (nombre.contains('en proceso')) return Colors.amber;
    if (nombre.contains('en producción')) return Colors.lightBlue;
    if (nombre.contains('proceso de entrega')) return Colors.cyan;
    if (nombre.contains('entregado')) return Colors.green;
    if (nombre.contains('anulado')) return Colors.redAccent;
    return Colors.grey;
  }

  List<dynamic> get _pedidosFiltrados {
    if (fechaDesde == null && fechaHasta == null) return pedidosCliente;

    return pedidosCliente.where((p) {
      final fecha = DateTime.tryParse(p['FechaPedido']) ?? DateTime.now();
      final cumpleDesde =
          fechaDesde == null ||
          fecha.isAfter(fechaDesde!.subtract(const Duration(days: 1)));
      final cumpleHasta =
          fechaHasta == null ||
          fecha.isBefore(fechaHasta!.add(const Duration(days: 1)));
      return cumpleDesde && cumpleHasta;
    }).toList();
  }

  List<dynamic> get _pedidosPaginados {
    final inicio = (paginaActual - 1) * pedidosPorPagina;
    final fin = inicio + pedidosPorPagina;
    return _pedidosFiltrados.sublist(
      inicio,
      fin > _pedidosFiltrados.length ? _pedidosFiltrados.length : fin,
    );
  }

  void mostrarDetalleModal(BuildContext context, int idPedido) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.pink[50],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<List<dynamic>>(
            future: fetchDetalles(idPedido),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final detalles = snapshot.data ?? [];
              if (detalles.isEmpty) {
                return const Center(child: Text("No hay detalles del pedido."));
              }

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final d = detalles[index];
                    final producto = productosMap[d['IdProducto']] ?? {};
                    final nombre = producto['Nombre'] ?? 'Producto';
                    final cantidad = d['Cantidad'];
                    final precio = producto['Precio'] ?? 0;
                    final subtotal = cantidad * precio;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.inventory,
                          size: 30,
                          color: Colors.purple,
                        ),
                        title: Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Cantidad: $cantidad"),
                        trailing: Text(
                          "\$$subtotal",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("📦 Mis Pedidos")),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : noEsCliente
            ? const Center(child: Text("📝 No estás registrado como cliente."))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              fechaDesde != null
                                  ? DateFormat('yyyy-MM-dd').format(fechaDesde!)
                                  : 'Desde',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  fechaDesde = picked;
                                  paginaActual = 1;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              fechaHasta != null
                                  ? DateFormat('yyyy-MM-dd').format(fechaHasta!)
                                  : 'Hasta',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  fechaHasta = picked;
                                  paginaActual = 1;
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
                          tooltip: "Borrar filtro",
                          onPressed: () => setState(() {
                            fechaDesde = null;
                            fechaHasta = null;
                            paginaActual = 1;
                          }),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _pedidosFiltrados.isEmpty
                        ? const Center(
                            child: Text("😕 No hay pedidos en ese rango."),
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: _pedidosPaginados.length,
                                  itemBuilder: (context, index) {
                                    final p = _pedidosPaginados[index];
                                    final estado =
                                        estadosMap[p['IdEstado']]?['NombreEstado'] ??
                                        'Desconocido';
                                    final fecha = DateFormat('yyyy-MM-dd')
                                        .format(
                                          DateTime.tryParse(p['FechaPedido']) ??
                                              DateTime.now(),
                                        );

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.pinkAccent
                                                  .withOpacity(0.15),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Pedido #${p['IdPedido']}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.expand_more,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text("📅 Fecha: $fecha"),
                                            Text(
                                              "💰 Inicial: \$${p['ValorInicial']}",
                                            ),
                                            Text(
                                              "💵 Total: \$${p['TotalPedido']}",
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                const Text("Estado: "),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _colorEstado(
                                                      p['IdEstado'],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    estado,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.visibility,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () =>
                                                      mostrarDetalleModal(
                                                        context,
                                                        p['IdPedido'],
                                                      ),
                                                ),
                                                if (p['IdEstado'] != 6)
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.redAccent,
                                                    ),
                                                    onPressed: () =>
                                                        anularPedido(
                                                          p['IdPedido'],
                                                        ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: paginaActual > 1
                                        ? () => setState(() => paginaActual--)
                                        : null,
                                  ),
                                  Text('Página $paginaActual'),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed:
                                        (paginaActual * pedidosPorPagina) <
                                            _pedidosFiltrados.length
                                        ? () => setState(() => paginaActual++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
