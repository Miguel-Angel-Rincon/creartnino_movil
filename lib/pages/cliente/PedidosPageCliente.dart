import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedidosPageCliente extends StatefulWidget {
  final String numDocumentoUsuario;

  const PedidosPageCliente({required this.numDocumentoUsuario, super.key});

  @override
  State<PedidosPageCliente> createState() => _PedidosPageClienteState();
}

class _PedidosPageClienteState extends State<PedidosPageCliente> {
  List<int> pedidosIgnorarAlerta = [];
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

  String formatCOP(num value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0, // 🔹 Sin decimales
    );
    return formatter.format(value);
  }

  @override
  void didUpdateWidget(covariant PedidosPageCliente oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.numDocumentoUsuario != widget.numDocumentoUsuario) {
      fetchPedidosDelCliente();
    }
  }

  void revisarPedidosModificados() {
    final pedidosModificados = _pedidosFiltrados
        .where((p) {
          final id = p['IdPedido'];
          return fueModificado(p) && !pedidosIgnorarAlerta.contains(id);
        })
        .map<int>((p) => p['IdPedido'])
        .toList();

    if (pedidosModificados.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        mostrarAlertaPedidosModificados(context, pedidosModificados);
      });
    }
  }

  void verificarYMostrarAlerta(BuildContext context, List<int> ids) async {
    if (await seDebeMostrarAlerta()) {
      mostrarAlertaPedidosModificados(context, ids);
    }
  }

  Future<void> fetchPedidosDelCliente() async {
    setState(() {
      isLoading = true;
      pedidosCliente = [];
      noEsCliente = false;
    });

    revisarPedidosModificados();

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
        final idsModificados = filtrados
            .where((p) => fueModificado(p))
            .map<int>((p) => p['IdPedido'])
            .toList();

        if (idsModificados.isNotEmpty) {
          verificarYMostrarAlerta(context, idsModificados);
        }
      } else {
        print("❌ Error al obtener datos de la API.");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Excepción al obtener pedidos: $e");
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
      }
    } catch (_) {}
    return [];
  }

  bool fueModificado(dynamic pedido) {
    final inicial = pedido['ValorInicial'] ?? 0;
    final restante = pedido['ValorRestante'] ?? 0;
    final total = pedido['TotalPedido'] ?? 0;

    final totalOriginal = inicial + restante; // Este es el original

    return total != totalOriginal; // Si es distinto, fue modificado
  }

  num calcularNuevoRestante(dynamic pedido) {
    final inicial = pedido['ValorInicial'] ?? 0;
    final totalActual = pedido['TotalPedido'] ?? 0;
    return totalActual - inicial; // Nuevo restante basado en total actualizado
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
    if (pedido == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Pedido no encontrado")));
      return;
    }

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
      "idEstado": 6, // ✅ estado anulado
    };

    try {
      // 1️⃣ Actualizar estado del pedido
      final res = await http.put(
        Uri.parse(
          'https://www.apicreartnino.somee.com/api/Pedidos/Actualizar/$idPedido',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        throw Exception("No se pudo anular el pedido");
      }

      // 2️⃣ Obtener detalles del pedido
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
          .where((d) => d['IdPedido'] == idPedido)
          .toList();

      // 3️⃣ Devolver stock de cada producto
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
          "Cantidad":
              (producto['Cantidad'] ?? 0) +
              (det['Cantidad'] ?? 0), // ✅ sumamos stock
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

      // 4️⃣ Refrescar pedidos
      await fetchPedidosDelCliente();

      revisarPedidosModificados();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Pedido anulado")));
    } catch (e) {
      debugPrint("❌ Error en anularPedido: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ No se pudo anular el pedido")),
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
    if (nombre.contains('venta directa'))
      return const Color.fromARGB(255, 242, 68, 248);
    if (nombre.contains('pedido pagado'))
      return const Color.fromARGB(255, 12, 89, 255);
    return Colors.grey;
  }

  bool _puedeAnular(int idEstado) {
    return !(idEstado == 4 || idEstado == 5 || idEstado == 6 || idEstado == 7);
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

              // 🔹 Buscar el pedido actual para mostrar la descripción
              final pedido = pedidosCliente.firstWhere(
                (p) => p['IdPedido'] == idPedido,
                orElse: () => {},
              );
              final descripcionLimpia =
                  (pedido['Descripcion'] ?? "Sin descripción")
                      .toString()
                      .replaceAll('"', '')
                      .replaceAll("Este pedido fue realizado desde la web.", "")
                      .trim();

              // 🔹 Separar la descripción en líneas (por comas)
              final lineasDescripcion = descripcionLimpia
                  .split(',')
                  .map((linea) => linea.trim())
                  .where((linea) => linea.isNotEmpty)
                  .toList();

              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView(
                  children: [
                    const Center(
                      child: Text(
                        "🧾 Detalles del Pedido",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 🔹 Lista de productos
                    ...detalles.map((d) {
                      final producto = productosMap[d['IdProducto']] ?? {};
                      final nombre = producto['Nombre'] ?? 'Producto';
                      final cantidad = d['Cantidad'];
                      final precio = producto['Precio'] ?? 0;
                      final subtotal = cantidad * precio;

                      return Card(
                        color: Colors.white,
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
                          subtitle: Text(
                            "Cantidad: $cantidad • Precio: ${formatCOP(precio)}",
                          ),
                          trailing: Text(
                            formatCOP(subtotal),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const Divider(thickness: 1, height: 30),

                    // 🔹 Descripción al final (una línea por producto)
                    const Text(
                      "📝 Descripción:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...lineasDescripcion.map(
                      (linea) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text("• $linea"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void mostrarAlertaPedidosModificados(BuildContext context, List<int> ids) {
    final esUno = ids.length == 1;
    final idsTexto = ids.join(", ");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            esUno ? "⚠ Pedido modificado" : "⚠ Pedidos modificados",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          content: Text(
            esUno
                ? "El precio del pedido #$idsTexto fue actualizado sea por precio si personalizastes o por cobro de envio."
                : "Los precios de los pedidos #$idsTexto fueron actualizados sea por precio si personalizastes o por cobro de envio.",
          ),
          actions: [
            // ❌ No volver a mostrar esos pedidos
            TextButton(
              child: const Text(
                "No recordarme más",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final fechaLimite =
                    DateTime.now().millisecondsSinceEpoch +
                    (15 * 60 * 1000); // 15 min
                await prefs.setInt('noMostrarAlertaPedidos', fechaLimite);
                Navigator.pop(context);
              },
            ),
            // ✅ Seguir recordando en el futuro
            TextButton(
              child: const Text(
                "Recordármelo",
                style: TextStyle(color: Colors.purple),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<bool> seDebeMostrarAlerta() async {
    final prefs = await SharedPreferences.getInstance();
    final fechaGuardada = prefs.getInt('noMostrarAlertaPedidos');

    if (fechaGuardada == null) {
      print("🟢 No hay fecha guardada → mostrar alerta");
      return true;
    }

    final ahora = DateTime.now().millisecondsSinceEpoch;

    if (ahora > fechaGuardada) {
      print("🟢 Ya pasaron los 30 min → borrar preferencia y mostrar alerta");
      await prefs.remove('noMostrarAlertaPedidos');
      return true;
    } else {
      final restanteMs = fechaGuardada - ahora;
      final minutosRestantes = (restanteMs / 60000).toStringAsFixed(1);
      print(
        "⏳ Todavía faltan $minutosRestantes min para volver a mostrar alerta",
      );
      return false;
    }
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

                                    // 🔹 Control de expansión
                                    bool isExpanded = p['expanded'] == true;

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
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  p['expanded'] = !isExpanded;
                                                });
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Pedido #${p['IdPedido']}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Icon(
                                                    isExpanded
                                                        ? Icons.expand_less
                                                        : Icons.expand_more,
                                                    color: Colors.grey,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Mostrar solo la fecha (sin tiempo)
                                            Text(
                                              "📦 Entrega: ${(() {
                                                final raw = p['FechaEntrega']?.toString();
                                                if (raw == null || raw.isEmpty) return 'No definida';
                                                final dt = DateTime.tryParse(raw);
                                                if (dt != null) return DateFormat('yyyy-MM-dd').format(dt);
                                                return raw.split(' ').first;
                                              })()}",
                                            ),
                                            const SizedBox(height: 10),
                                            const SizedBox(height: 10),
                                            // ✅ Si el pedido fue modificado, mostrar solo el nuevo restante y mensaje.
                                            // Si no fue modificado, mostrar el restante normal.
                                            fueModificado(p)
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(height: 8),

                                                      // 🟡 Estado de modificado
                                                      Text(
                                                        "🟡 Pedido Modificado",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .orange[800],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),

                                                      // 💡 Nuevo restante
                                                      Text(
                                                        "💡 Nuevo restante: ${formatCOP(calcularNuevoRestante(p))}",
                                                        style: const TextStyle(
                                                          color: Colors.red,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    "💳 Restante: ${formatCOP(p['ValorRestante'] ?? 0)}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                            const SizedBox(height: 10),
                                            const SizedBox(height: 10),
                                            Text(
                                              "💵 Total: ${formatCOP(p['TotalPedido'])}",
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
                                                if (_puedeAnular(p['IdEstado']))
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

                                            // 🔹 Contenido expandido
                                            if (isExpanded) ...[
                                              const Divider(
                                                height: 20,
                                                thickness: 1,
                                              ),

                                              Text("📅 Fecha: $fecha"),
                                              const SizedBox(height: 8),

                                              Text(
                                                "💰 Inicial: ${formatCOP(p['ValorInicial'])}",
                                              ),
                                              const SizedBox(height: 8),

                                              Text(
                                                "📁 Comprobante: ${p['ComprobantePago'] ?? 'Sin comprobante'}",
                                              ),
                                              const SizedBox(height: 12),

                                              const Text(
                                                "ℹ️ Nota: Los tiempos de entrega pueden variar según la producción y ubicación. "
                                                "Además ten en cuenta que si personalizas tu pedido, los tiempos de entrega pueden "
                                                "ser mayores y el precio puede aumentar.",
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // 🔹 Paginación
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
