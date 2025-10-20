import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CrearPedidoPage extends StatefulWidget {
  const CrearPedidoPage({super.key});

  @override
  State<CrearPedidoPage> createState() => _CrearPedidoPageState();
}

class _CrearPedidoPageState extends State<CrearPedidoPage> {
  final _formKey = GlobalKey<FormState>();
  String? _idCliente;
  String? _metodoPago;
  DateTime? _fechaEntrega;
  String _descripcion = '';
  int _valorInicial = 0;
  int _valorRestante = 0;
  int _totalPedido = 0;
  String _comprobantePago = '';
  bool _subiendoImagen = false;

  List<dynamic> clientes = [];
  List<dynamic> productos = [];
  List<dynamic> categorias = []; // <-- NUEVO: categorias
  List<Map<String, dynamic>> productosSeleccionados = [];

  final List<String> metodosPago = [
    'Efectivo',
    'Transferencia',
    'Nequi',
    'Daviplata',
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String formatCOP(num value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0, // 🔹 Sin decimales
    );
    return formatter.format(value);
  }

  Future<void> fetchData() async {
    final resClientes = await http.get(
      Uri.parse("https://www.apicreartnino.somee.com/api/Clientes/Lista"),
    );
    final resUsuarios = await http.get(
      Uri.parse("https://www.apicreartnino.somee.com/api/Usuarios/Lista"),
    );
    final resProductos = await http.get(
      Uri.parse("https://www.apicreartnino.somee.com/api/Productos/Lista"),
    );
    final resCategorias = await http.get(
      Uri.parse(
        "https://www.apicreartnino.somee.com/api/Categoria_productos/Lista",
      ),
    );

    if (resClientes.statusCode == 200 &&
        resUsuarios.statusCode == 200 &&
        resProductos.statusCode == 200 &&
        resCategorias.statusCode == 200) {
      final listaClientes = jsonDecode(resClientes.body);
      final listaUsuarios = jsonDecode(resUsuarios.body);
      final listaProductos = jsonDecode(resProductos.body);
      final listaCategorias = jsonDecode(resCategorias.body);

      final documentosClientes = listaClientes
          .map((c) => c['NumDocumento'].toString())
          .toSet();

      final usuariosConRol4 = listaUsuarios
          .where(
            (u) =>
                u['IdRol'] == 4 &&
                !documentosClientes.contains(u['NumDocumento'].toString()),
          )
          .map(
            (u) => {
              "IdCliente": null,
              "IdUsuario": u["IdUsuarios"],
              "NombreCompleto": u["NombreCompleto"] ?? "",
              "TipoDocumento": u["TipoDocumento"] ?? "",
              "NumDocumento": u["NumDocumento"] ?? "",
              "Correo": u["Correo"] ?? "",
              "Celular": u["Celular"] ?? "",
              "Departamento": u["Departamento"] ?? "",
              "Ciudad": u["Ciudad"] ?? "",
              "Direccion": u["Direccion"] ?? "",
              "EsUsuarioNuevo": true,
            },
          )
          .toList();

      if (!mounted) return; // 👈 FIX
      setState(() {
        clientes = [
          ...listaClientes.map((c) => {...c, "EsUsuarioNuevo": false}),
          ...usuariosConRol4,
        ];
        productos = listaProductos;
        categorias = listaCategorias;
      });
    } else {
      debugPrint("Error fetching data");
    }
  }

  void _calcularTotal() {
    int subtotal = 0;
    for (var item in productosSeleccionados) {
      final precio = (item['Precio'] as num?)?.toInt() ?? 0;
      final cantidad = (item['Cantidad'] as num?)?.toInt() ?? 1;
      subtotal += precio * cantidad;
    }
    setState(() {
      _totalPedido = subtotal;
      _valorInicial = (subtotal * 0.5).round();
      _valorRestante = subtotal - _valorInicial;
    });
  }

  Future<void> _subirImagenACloudinary() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;
    setState(() => _subiendoImagen = false);

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/creartnino/image/upload",
    );
    final uploadRequest = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] = "CreartNino"
      ..fields['folder'] = "Comprobantes"
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await uploadRequest.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      if (!mounted) return;
      setState(() => _comprobantePago = data['secure_url']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Imagen subida correctamente")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Error al subir imagen")));
    }
    if (!mounted) return;
    setState(() => _subiendoImagen = false);
  }

  // ---------- NUEVO: seleccionar por categoría -> luego producto (modal)
  Future<void> _seleccionarProducto() async {
    if (categorias.isEmpty) {
      // si por alguna razón no cargaron, intentar recargar
      await fetchData();
      if (categorias.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ No se encontraron categorías")),
        );
        return;
      }
    }

    final productoSeleccionado =
        await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return CategoryProductPicker(
              categorias: categorias,
              productos: productos,
              productosSeleccionados: productosSeleccionados, // 👈 AGREGA ESTO
            );
          },
        );

    if (productoSeleccionado != null) {
      // pedir cantidad (igual que antes)
      final cantidad = await showDialog<int>(
        context: context,
        builder: (context) {
          int tempCantidad = 1;
          return AlertDialog(
            title: const Text('Cantidad'),
            content: TextFormField(
              initialValue: '1',
              keyboardType: TextInputType.number,
              onChanged: (val) => tempCantidad = int.tryParse(val) ?? 1,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, tempCantidad),
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );

      if (cantidad != null && cantidad > 0) {
        setState(() {
          productosSeleccionados.add({
            'IdProducto': productoSeleccionado['IdProducto'],
            'Nombre': productoSeleccionado['Nombre'],
            'Precio': productoSeleccionado['Precio'],
            'Cantidad': cantidad,
          });
          _calcularTotal();
        });
      }
    }
  }
  // ---------- FIN NUEVO

  Future<void> _guardarPedido() async {
    if (!_formKey.currentState!.validate()) return;
    if (productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Agrega al menos un producto")));
      return;
    }
    if (_fechaEntrega == null || _fechaEntrega!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Selecciona una fecha válida")));
      return;
    }
    _formKey.currentState!.save();

    final clienteSeleccionado = clientes.firstWhere(
      (c) {
        final id = c['EsUsuarioNuevo'] ? c['IdUsuario'] : c['IdCliente'];
        return id.toString() == _idCliente;
      },
      orElse: () => null, // 👈 AGREGA ESTO TAMBIÉN
    );
    if (clienteSeleccionado == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Cliente no válido")));
      return;
    }

    if (clienteSeleccionado['EsUsuarioNuevo'] == true) {
      if ((clienteSeleccionado['NumDocumento'] ?? "").isEmpty ||
          (clienteSeleccionado['Correo'] ?? "").isEmpty ||
          (clienteSeleccionado['Celular'] ?? "").isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Datos insuficientes para crear cliente")),
        );
        return;
      }
      final nuevoCliente = {
        "NombreCompleto": clienteSeleccionado['NombreCompleto'],
        "TipoDocumento": clienteSeleccionado['TipoDocumento'] ?? "CC",
        "NumDocumento": clienteSeleccionado['NumDocumento'],
        "Correo": clienteSeleccionado['Correo'],
        "Celular": clienteSeleccionado['Celular'],
        "Departamento": clienteSeleccionado['Departamento'] ?? "",
        "Ciudad": clienteSeleccionado['Ciudad'] ?? "",
        "Direccion": clienteSeleccionado['Direccion'] ?? "",
        "Estado": true,
      };
      final res = await http.post(
        Uri.parse("https://www.apicreartnino.somee.com/api/Clientes/Crear"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(nuevoCliente),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _idCliente = data['IdCliente'].toString();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error al crear cliente")));
        return;
      }
    }

    final pedido = {
      "IdCliente": int.tryParse(_idCliente ?? '0'),
      "MetodoPago": _metodoPago,
      "FechaPedido": DateTime.now().toIso8601String().split('T').first,
      "FechaEntrega": _fechaEntrega!.toIso8601String().split('T').first,
      "Descripcion": _descripcion,
      "ValorInicial": _valorInicial,
      "ValorRestante": _valorRestante,
      "TotalPedido": _totalPedido,
      "ComprobantePago": _comprobantePago,
      "IdEstado": 1,
      "DetallePedidos": productosSeleccionados
          .map(
            (p) => {
              "IdProducto": p['IdProducto'],
              "Cantidad": p['Cantidad'],
              "Subtotal": p['Cantidad'] * p['Precio'],
            },
          )
          .toList(),
    };

    final res = await http.post(
      Uri.parse("https://www.apicreartnino.somee.com/api/Pedidos/Crear"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(pedido),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      // 🔹 Descontar stock de cada producto
      for (final p in productosSeleccionados) {
        final productoId = p['IdProducto'];
        final cantidadComprada = p['Cantidad'];

        try {
          final respProd = await http.get(
            Uri.parse(
              "https://www.apicreartnino.somee.com/api/Productos/Obtener/$productoId",
            ),
          );
          if (respProd.statusCode != 200) continue;

          final producto = jsonDecode(respProd.body);

          final actualizado = {
            "IdProducto": producto["IdProducto"],
            "CategoriaProducto": producto["CategoriaProducto"],
            "Nombre": producto["Nombre"],
            "Imagen": producto["Imagen"],
            "Cantidad": (producto["Cantidad"] ?? 0) - cantidadComprada,
            "Marca": producto["Marca"],
            "Precio": producto["Precio"],
            "Estado": producto["Estado"],
          };

          final respUpd = await http.put(
            Uri.parse(
              "https://www.apicreartnino.somee.com/api/Productos/Actualizar/$productoId",
            ),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(actualizado),
          );

          if (respUpd.statusCode != 200) {
            debugPrint(
              "❌ Error al actualizar stock de $productoId: ${respUpd.body}",
            );
          }
        } catch (e) {
          debugPrint("⚠️ Error procesando stock de producto $productoId: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Pedido creado y stock actualizado")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error al crear pedido")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Pedido"),
        backgroundColor: Colors.pinkAccent.shade100,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8BBD0), Color(0xFFFFF3E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pinkAccent.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // CLIENTE (mantengo simple para no romper lo que ya tenías)
                    DropdownSearch<Map<String, dynamic>>(
                      popupProps: PopupProps.menu(showSearchBox: true),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: pastelInputDecoration(
                          "Cliente",
                          Icons.person,
                        ),
                      ),
                      items: clientes
                          .where((c) => c['EsUsuarioNuevo'] != true)
                          .map(
                            (c) => {
                              "id": c['IdCliente'].toString(),
                              "nombre": c['NombreCompleto'] ?? 'Sin nombre',
                            },
                          )
                          .toList(),
                      itemAsString: (item) => item["nombre"],
                      onChanged: (val) {
                        setState(() {
                          _idCliente = val?["id"];
                        });
                      },
                      selectedItem: _idCliente != null
                          ? {
                              "id": _idCliente,
                              "nombre": clientes.firstWhere(
                                (c) => c['IdCliente'].toString() == _idCliente,
                                orElse: () => {"NombreCompleto": "Sin nombre"},
                              )["NombreCompleto"],
                            }
                          : null,
                      validator: (val) =>
                          val == null ? 'Selecciona un cliente' : null,
                    ),
                    const SizedBox(height: 12),

                    // MÉTODO DE PAGO
                    DropdownButtonFormField<String>(
                      decoration: pastelInputDecoration(
                        "Método de pago",
                        Icons.payment,
                      ),
                      value: _metodoPago,
                      items: metodosPago
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _metodoPago = val),
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

                    // FECHA
                    ListTile(
                      tileColor: const Color(0xFFFFF0F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        _fechaEntrega == null
                            ? "Selecciona la fecha de entrega"
                            : "Fecha: ${_fechaEntrega!.toLocal().toString().split(' ')[0]}",
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: Colors.pinkAccent,
                      ),
                      onTap: () async {
                        final now = DateTime.now();
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: now.add(const Duration(days: 1)),
                          firstDate: now,
                          lastDate: DateTime(now.year + 2),
                        );
                        if (fecha != null)
                          setState(() => _fechaEntrega = fecha);
                      },
                    ),
                    const SizedBox(height: 12),

                    // DESCRIPCION
                    TextFormField(
                      decoration: pastelInputDecoration(
                        "Descripción",
                        Icons.description,
                      ),
                      onSaved: (val) => _descripcion = val ?? '',
                    ),
                    const SizedBox(height: 12),

                    // SUBIR IMAGEN
                    ElevatedButton.icon(
                      style: pastelButtonStyle(),
                      onPressed: _subiendoImagen
                          ? null
                          : _subirImagenACloudinary,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(
                        _subiendoImagen ? "Subiendo..." : "Subir comprobante",
                      ),
                    ),
                    if (_comprobantePago.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("✅ Imagen subida: $_comprobantePago"),
                      ),

                    const SizedBox(height: 20),

                    const Text(
                      "🛒 Productos seleccionados",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Lista de productos seleccionados
                    ...productosSeleccionados.map((p) {
                      int index = productosSeleccionados.indexOf(p);
                      return Card(
                        color: const Color(0xFFFFF0F5),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(p['Nombre']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Precio: ${formatCOP(p['Precio'])}"),
                              Row(
                                children: [
                                  const Text("Cantidad: "),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: p['Cantidad'].toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        final nuevaCantidad = int.tryParse(val);
                                        if (nuevaCantidad != null &&
                                            nuevaCantidad > 0) {
                                          setState(() {
                                            productosSeleccionados[index]['Cantidad'] =
                                                nuevaCantidad;
                                            _calcularTotal();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                "Subtotal: ${formatCOP(p['Precio'] * p['Cantidad'])}",
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                productosSeleccionados.removeAt(index);
                                _calcularTotal();
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 12),

                    // BOTÓN AGREGAR PRODUCTO -> abre modal categoría->producto
                    ElevatedButton.icon(
                      style: pastelButtonStyle(),
                      onPressed: _seleccionarProducto,
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar producto"),
                    ),

                    const SizedBox(height: 20),

                    // TOTALES
                    Text(
                      "💰 Valor inicial: ${formatCOP(_valorInicial)}",
                      style: const TextStyle(color: Colors.green),
                    ),
                    Text(
                      "💸 Restante: ${formatCOP(_valorRestante)}",
                      style: const TextStyle(color: Colors.orange),
                    ),
                    Text(
                      "🧾 Total: ${formatCOP(_totalPedido)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: pastelButtonStyle(height: 50),
                      onPressed: _guardarPedido,
                      child: const Text("Guardar Pedido"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------- WIDGET MODAL (categoría -> producto) --------------------
class CategoryProductPicker extends StatefulWidget {
  final List<dynamic> categorias;
  final List<dynamic> productos;
  final List<Map<String, dynamic>> productosSeleccionados; // 👈 NUEVO

  const CategoryProductPicker({
    required this.categorias,
    required this.productos,
    required this.productosSeleccionados, // 👈 NUEVO
    super.key,
  });

  @override
  State<CategoryProductPicker> createState() => _CategoryProductPickerState();
}

class _CategoryProductPickerState extends State<CategoryProductPicker> {
  bool mostrandoProductos = false;
  List<dynamic> listaMostrar = [];
  int? categoriaSeleccionadaId;
  String searchText = "";

  @override
  void initState() {
    super.initState();
    listaMostrar = widget.categorias;
  }

  void filtrar(String q) {
    if (!mounted) return; // 👈 FIX
    setState(() {
      searchText = q;
      if (mostrandoProductos) {
        listaMostrar = widget.productos
            .where(
              (p) =>
                  (p['CategoriaProducto'] == categoriaSeleccionadaId) &&
                  (p['Nombre'] ?? '').toString().toLowerCase().contains(
                    q.toLowerCase(),
                  ),
            )
            .toList();
      } else {
        listaMostrar = widget.categorias
            .where(
              (c) => (c['CategoriaProducto1'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(q.toLowerCase()),
            )
            .toList();
      }
    });
  }

  String formatCOP(dynamic valor) {
    final number = double.tryParse(valor.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(number);
  }

  @override
  Widget build(BuildContext context) {
    final titleText = mostrandoProductos
        ? "Selecciona producto"
        : "Selecciona categoría";
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Container(
        height: size.height * 0.72,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  if (mostrandoProductos)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.pinkAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          mostrandoProductos = false;
                          listaMostrar = widget.categorias;
                          categoriaSeleccionadaId = null;
                          searchText = "";
                        });
                      },
                    ),
                  Expanded(
                    child: TextField(
                      onChanged: filtrar,
                      decoration: InputDecoration(
                        hintText: mostrandoProductos
                            ? "Buscar producto..."
                            : "Buscar categoría...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.pinkAccent,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFFF0F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  titleText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: listaMostrar.isEmpty
                    ? Center(
                        child: Text(
                          mostrandoProductos
                              ? "No se encontraron productos"
                              : "No se encontraron categorías",
                        ),
                      )
                    : ListView.builder(
                        itemCount: listaMostrar.length,
                        itemBuilder: (context, index) {
                          final item = listaMostrar[index];
                          return Card(
                            color: const Color(0xFFFFF0F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                mostrandoProductos
                                    ? item['Nombre'] ?? 'Sin nombre'
                                    : item['CategoriaProducto1'] ??
                                          'Sin nombre',
                              ),
                              subtitle: Text(
                                mostrandoProductos
                                    ? "Precio: ${formatCOP(item['Precio'])}"
                                    : (item['Descripcion'] ?? ""),
                              ),

                              onTap: () {
                                if (mostrandoProductos) {
                                  Navigator.pop(
                                    context,
                                    Map<String, dynamic>.from(item),
                                  );
                                } else {
                                  // pasar a productos de esa categoría
                                  final idCat = item['IdCategoriaProducto'];
                                  final prods = widget.productos
                                      .where(
                                        (p) =>
                                            p['CategoriaProducto'] == idCat &&
                                            !widget.productosSeleccionados.any(
                                              (sel) =>
                                                  sel['IdProducto'] ==
                                                  p['IdProducto'],
                                            ), // 👈 FILTRO NUEVO
                                      )
                                      .toList();

                                  setState(() {
                                    categoriaSeleccionadaId = idCat;
                                    listaMostrar = prods;
                                    mostrandoProductos = true;
                                    searchText = "";
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- DECORATORS --------------------
InputDecoration pastelInputDecoration(String label, IconData icon) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: Colors.pinkAccent),
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFFFF0F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}

ButtonStyle pastelButtonStyle({double height = 48}) {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFF8BBD0),
    foregroundColor: Colors.black,
    elevation: 2,
    minimumSize: Size(double.infinity, height),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  );
}
