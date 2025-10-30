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
  double _valorInicial = 0; // ✅ CAMBIO 1: int -> double
  int _valorRestante = 0;
  int _totalPedido = 0;
  String _comprobantePago = '';
  bool _subiendoImagen = false;
  TextEditingController? _valorInicialController;
  String _valorInicialTexto = '';

  List<dynamic> clientes = [];
  List<dynamic> productos = [];
  List<dynamic> categorias = [];
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
    _valorInicialController =
        TextEditingController(); // ✅ CAMBIO 2: sin formatCOP(0)
    fetchData();
  }

  @override
  void dispose() {
    _valorInicialController?.dispose();
    super.dispose();
  }

  String formatCOP(num value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0,
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

      if (!mounted) return;
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

  // ✅ CAMBIO 3: Actualizar _calcularTotal con formato sin "COP"
  void _calcularTotal() {
    int subtotal = 0;
    for (var item in productosSeleccionados) {
      final precio = (item['Precio'] as num?)?.toInt() ?? 0;
      final cantidad = (item['Cantidad'] as num?)?.toInt() ?? 1;
      subtotal += precio * cantidad;
    }
    setState(() {
      _totalPedido = subtotal;

      // ✅ Si no hay productos, resetear todo
      if (subtotal == 0) {
        _valorInicial = 0;
        _valorRestante = 0;
        _valorInicialTexto = '';
        _valorInicialController?.text = '';
      } else {
        _valorInicial = (subtotal * 0.5);
        _valorRestante = subtotal - _valorInicial.round();

        final formatter = NumberFormat('#,###', 'es_CO');
        _valorInicialTexto = formatter.format(_valorInicial);
        _valorInicialController?.text = _valorInicialTexto;
      }
    });
  }

  Future<void> _subirImagenACloudinary() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;
    setState(() => _subiendoImagen = true);

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

  Future<void> _seleccionarProducto() async {
    if (categorias.isEmpty) {
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
              productosSeleccionados: productosSeleccionados,
            );
          },
        );

    if (productoSeleccionado != null) {
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

  Future<void> _guardarPedido() async {
    if (!_formKey.currentState!.validate()) return;
    if (productosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Agrega al menos un producto")));
      return;
    }
    // ✅ Validar fecha de entrega
    if (_fechaEntrega == null) {
      mostrarAlerta(
        context: context,
        titulo: '⚠️',
        mensaje: 'Selecciona una fecha de entrega',
      );
      return;
    }

    // ✅ Validar días mínimos según descripción
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final entrega = DateTime(
      _fechaEntrega!.year,
      _fechaEntrega!.month,
      _fechaEntrega!.day,
    );
    final diferenciaDias = entrega.difference(hoy).inDays;

    // Determinar días mínimos según descripción
    final tieneDescripcion = _descripcion.trim().isNotEmpty;
    final diasMinimos = tieneDescripcion ? 5 : 3;
    final tipoProducto = tieneDescripcion ? "personalizado" : "prediseñado";

    if (diferenciaDias < diasMinimos) {
      mostrarAlerta(
        context: context,
        titulo: '⚠️ Fecha muy cercana',
        mensaje:
            'Para productos ${tipoProducto}s se requieren mínimo $diasMinimos días. '
            'La fecha seleccionada solo tiene $diferenciaDias día(s) de diferencia.',
      );
      return;
    }
    // ✅ Validar comprobante solo si el método NO es Efectivo
    if (_metodoPago != 'Efectivo' && _comprobantePago.isEmpty) {
      mostrarAlerta(
        context: context,
        titulo: '⚠️',
        mensaje: 'Debes subir el comprobante de pago para $_metodoPago',
      );
      return;
    }
    _formKey.currentState!.save();

    final clienteSeleccionado = clientes.firstWhere((c) {
      final id = c['EsUsuarioNuevo'] ? c['IdUsuario'] : c['IdCliente'];
      return id.toString() == _idCliente;
    }, orElse: () => null);
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
      "ValorInicial": _valorInicial.round(), // ✅ Convertir a int para enviar
      "ValorRestante": _valorRestante,
      "TotalPedido": _totalPedido,
      "ComprobantePago": _comprobantePago,
      "IdEstado": _valorInicial >= _totalPedido ? 1007 : 1,
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

  void mostrarAlerta({
    required BuildContext context,
    required String titulo,
    required String mensaje,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFFFF5F7),
        title: Text(
          titulo,
          style: const TextStyle(
            color: Colors.pinkAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(mensaje, style: const TextStyle(color: Colors.black87)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
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
                      onChanged: (val) {
                        setState(() {
                          _metodoPago = val;
                          // ✅ Limpiar comprobante si cambia a Efectivo
                          if (val == 'Efectivo') {
                            _comprobantePago = '';
                          }
                        });
                      },
                      validator: (val) => val == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),

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

                        // ✅ Determinar días mínimos según descripción
                        final tieneDescripcion = _descripcion.trim().isNotEmpty;
                        final diasMinimos = tieneDescripcion ? 5 : 3;

                        // Fecha mínima permitida
                        final fechaMinima = now.add(
                          Duration(days: diasMinimos),
                        );

                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: fechaMinima,
                          firstDate: fechaMinima,
                          lastDate: DateTime(now.year + 2),
                          helpText: tieneDescripcion
                              ? 'Productos personalizados (mín. 5 días)'
                              : 'Productos prediseñados (mín. 3 días)',
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Colors.pinkAccent,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (fecha != null) {
                          setState(() => _fechaEntrega = fecha);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      decoration: pastelInputDecoration(
                        "Descripción ${_descripcion.trim().isEmpty ? '(opcional - 3 días)' : '(+2 días entrega)'}",
                        Icons.description,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _descripcion = val;
                          // ✅ Si cambia la descripción, limpiar fecha para que revalide
                          if (_fechaEntrega != null) {
                            final ahora = DateTime.now();
                            final diferencia = _fechaEntrega!
                                .difference(ahora)
                                .inDays;
                            final nuevoMinimo = val.trim().isNotEmpty ? 5 : 3;
                            if (diferencia < nuevoMinimo) {
                              _fechaEntrega = null; // Limpiar fecha inválida
                            }
                          }
                        });
                      },
                      onSaved: (val) => _descripcion = val ?? '',
                    ),
                    const SizedBox(height: 12),

                    // ✅ CAMBIO 4: Solo mostrar si hay productos
                    if (productosSeleccionados.isNotEmpty) ...[
                      TextFormField(
                        controller: _valorInicialController,
                        keyboardType: TextInputType.number,
                        decoration: pastelInputDecoration(
                          "Valor Inicial (mínimo: ${formatCOP(_totalPedido * 0.5)})",
                          Icons.attach_money,
                        ),
                        onChanged: (valor) {
                          // Remover todo excepto números
                          final soloNumeros = valor.replaceAll(
                            RegExp(r'[^\d]'),
                            '',
                          );

                          if (soloNumeros.isEmpty) {
                            setState(() {
                              _valorInicial = 0;
                              _valorRestante = _totalPedido;
                            });
                            return;
                          }

                          // Limitar a 8 cifras
                          final numerosLimitados = soloNumeros.length > 8
                              ? soloNumeros.substring(0, 8)
                              : soloNumeros;

                          final numero = double.tryParse(numerosLimitados) ?? 0;

                          setState(() {
                            _valorInicial = numero;
                            _valorRestante = _totalPedido - numero.round();
                          });

                          // Formatear con separadores de miles SIN "COP"
                          final formatter = NumberFormat('#,###', 'es_CO');
                          final textoFormateado = formatter.format(numero);

                          // Actualizar el texto
                          _valorInicialController?.value = TextEditingValue(
                            text: textoFormateado,
                            selection: TextSelection.collapsed(
                              offset: textoFormateado.length,
                            ),
                          );
                        },
                        onEditingComplete: () {
                          final minimo = (_totalPedido * 0.5);

                          if (_valorInicial == 0) {
                            mostrarAlerta(
                              context: context,
                              titulo: '⚠️',
                              mensaje:
                                  'Debes ingresar el pago inicial (mínimo ${formatCOP(minimo)})',
                            );
                            setState(() {
                              _valorInicial = minimo;
                              _valorRestante = _totalPedido - minimo.round();
                              final formatter = NumberFormat('#,###', 'es_CO');
                              _valorInicialTexto = formatter.format(minimo);
                              _valorInicialController?.text =
                                  _valorInicialTexto;
                            });
                          } else if (_valorInicial < minimo) {
                            mostrarAlerta(
                              context: context,
                              titulo: '⚠️',
                              mensaje:
                                  'El pago inicial mínimo es ${formatCOP(minimo)} (50% del total)',
                            );
                            setState(() {
                              _valorInicial = minimo;
                              _valorRestante = _totalPedido - minimo.round();
                              final formatter = NumberFormat('#,###', 'es_CO');
                              _valorInicialTexto = formatter.format(minimo);
                              _valorInicialController?.text =
                                  _valorInicialTexto;
                            });
                          } else if (_valorInicial > _totalPedido) {
                            mostrarAlerta(
                              context: context,
                              titulo: '⚠️',
                              mensaje:
                                  'El pago inicial no puede superar el total (${formatCOP(_totalPedido)})',
                            );
                            setState(() {
                              _valorInicial = _totalPedido.toDouble();
                              _valorRestante = 0;
                              final formatter = NumberFormat('#,###', 'es_CO');
                              _valorInicialTexto = formatter.format(
                                _totalPedido,
                              );
                              _valorInicialController?.text =
                                  _valorInicialTexto;
                            });
                          } else {
                            // Si el valor es válido, solo formatearlo
                            setState(() {
                              final formatter = NumberFormat('#,###', 'es_CO');
                              _valorInicialTexto = formatter.format(
                                _valorInicial,
                              );
                              _valorInicialController?.text =
                                  _valorInicialTexto;
                            });
                          }

                          FocusScope.of(context).unfocus();
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ✅ Solo mostrar si el método de pago NO es Efectivo
                    if (_metodoPago != null && _metodoPago != 'Efectivo') ...[
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
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 20),

                    const Text(
                      "🛒 Productos seleccionados",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),

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

                    ElevatedButton.icon(
                      style: pastelButtonStyle(),
                      onPressed: _seleccionarProducto,
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar producto"),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "💸 Restante: ${formatCOP(_valorRestante)}",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "🧾 Total: ${formatCOP(_totalPedido)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
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

// -------------------- WIDGET MODAL --------------------
class CategoryProductPicker extends StatefulWidget {
  final List<dynamic> categorias;
  final List<dynamic> productos;
  final List<Map<String, dynamic>> productosSeleccionados;

  const CategoryProductPicker({
    required this.categorias,
    required this.productos,
    required this.productosSeleccionados,
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
    if (!mounted) return;
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

                          // ✅ NUEVO: Verificar si es producto y si está agotado
                          final esProducto = mostrandoProductos;
                          final cantidad = esProducto
                              ? (item['Cantidad'] ?? 0)
                              : 0;
                          final estaAgotado = esProducto && cantidad <= 0;

                          return Card(
                            color: estaAgotado
                                ? Colors
                                      .grey
                                      .shade300 // Color gris para agotados
                                : const Color(0xFFFFF0F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              enabled:
                                  !estaAgotado, // ✅ Deshabilitar si está agotado
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mostrandoProductos
                                          ? item['Nombre'] ?? 'Sin nombre'
                                          : item['CategoriaProducto1'] ??
                                                'Sin nombre',
                                      style: TextStyle(
                                        color: estaAgotado
                                            ? Colors.grey.shade600
                                            : Colors.black,
                                        decoration: estaAgotado
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  // ✅ Badge de AGOTADO
                                  if (estaAgotado)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'AGOTADO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                mostrandoProductos
                                    ? estaAgotado
                                          ? "Sin stock disponible"
                                          : "Precio: ${formatCOP(item['Precio'])} | Stock: $cantidad"
                                    : (item['Descripcion'] ?? ""),
                                style: TextStyle(
                                  color: estaAgotado
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                              onTap: estaAgotado
                                  ? null // ✅ No hacer nada si está agotado
                                  : () {
                                      if (mostrandoProductos) {
                                        Navigator.pop(
                                          context,
                                          Map<String, dynamic>.from(item),
                                        );
                                      } else {
                                        final idCat =
                                            item['IdCategoriaProducto'];
                                        final prods = widget.productos
                                            .where(
                                              (p) =>
                                                  p['CategoriaProducto'] ==
                                                      idCat &&
                                                  !widget.productosSeleccionados
                                                      .any(
                                                        (sel) =>
                                                            sel['IdProducto'] ==
                                                            p['IdProducto'],
                                                      ),
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
