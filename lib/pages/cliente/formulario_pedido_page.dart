import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/producto.dart';
import '../../widgets/utils.dart';
import '../cliente/cliente_home_page.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as dp;

class FormularioPedidoPage extends StatefulWidget {
  final String descripcionGenerada;
  final double totalGenerado;
  final Map<Producto, int> carrito;
  final Map<Producto, String> personalizaciones;

  const FormularioPedidoPage({
    super.key,
    required this.descripcionGenerada,
    required this.totalGenerado,
    required this.carrito,
    required this.personalizaciones,
  });

  @override
  State<FormularioPedidoPage> createState() => _FormularioPedidoPageState();
}

class _FormularioPedidoPageState extends State<FormularioPedidoPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _fechaEntrega;
  String _metodoPago = 'Efectivo';
  String _comprobantePago = '';
  bool _subiendoImagen = false;
  bool isSaving = false;

  final List<String> metodos = [
    'Efectivo',
    'Transferencia',
    'Nequi',
    'Daviplata',
  ];
  Map<String, dynamic> _cliente = {};
  late TextEditingController _clienteController;

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController();
    _completarDatosCliente();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    super.dispose();
  }

  Future<void> _completarDatosCliente() async {
    final prefs = await SharedPreferences.getInstance();
    final correo = prefs.getString('correo');

    if (correo == null || correo.isEmpty) {
      mostrarAlerta(
        context: context,
        titulo: '⚠',
        mensaje: 'No se encontró el correo.',
      );
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("https://apicreartnino.somee.com/api/Clientes/Lista"),
      );
      if (res.statusCode == 200) {
        final List clientes = jsonDecode(res.body);
        final clienteEncontrado = clientes.firstWhere(
          (c) =>
              (c["Correo"] ?? '').toString().toLowerCase() ==
              correo.toLowerCase(),
          orElse: () => null,
        );

        if (clienteEncontrado != null) {
          setState(() {
            _cliente = clienteEncontrado;
            _clienteController.text = _cliente["NombreCompleto"] ?? '';
          });
        } else {
          final nombre = prefs.getString('nombre') ?? 'Usuario';
          final tipoDoc = prefs.getString('tipoDocumento') ?? 'CC';
          final numDoc = prefs.getString('numDocumento') ?? '0000000000';
          final celular = prefs.getString('celular') ?? '0000000000';
          final departamento = prefs.getString('departamento') ?? 'Sin depto';
          final ciudad = prefs.getString('ciudad') ?? 'Sin ciudad';

          final nuevoCliente = {
            "NombreCompleto": nombre,
            "TipoDocumento": tipoDoc,
            "NumDocumento": numDoc,
            "Correo": correo,
            "Celular": celular,
            "Departamento": departamento,
            "Ciudad": ciudad,
            "Direccion": "",
            "Estado": true,
          };

          final crearRes = await http.post(
            Uri.parse("https://apicreartnino.somee.com/api/Clientes/Crear"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(nuevoCliente),
          );

          if (crearRes.statusCode == 200 || crearRes.statusCode == 201) {
            final creado = jsonDecode(crearRes.body);
            setState(() {
              _cliente = creado;
              _clienteController.text = creado["NombreCompleto"] ?? '';
            });
            mostrarSnackBar(context, "✅ Cliente registrado exitosamente");
          } else {
            mostrarAlerta(
              context: context,
              titulo: '⚠',
              mensaje: 'No se pudo registrar el cliente.',
            );
          }
        }
      } else {
        mostrarAlerta(
          context: context,
          titulo: '❌',
          mensaje: 'Error al obtener clientes.',
        );
      }
    } catch (e) {
      mostrarAlerta(context: context, titulo: '❌', mensaje: 'Error: $e');
    }
  }

  void _mostrarModalMetodoPago() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFFF5F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.payments_rounded,
                size: 40,
                color: Colors.pinkAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                "Métodos de Pago",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const Divider(height: 20, thickness: 1, color: Colors.pinkAccent),
              const MetodoPagoItem(
                icono: "💵",
                metodo: "Efectivo",
                descripcion: "Pagas cuando recibas el producto.",
              ),
              const MetodoPagoItem(
                icono: "🏦",
                metodo: "Transferencia",
                descripcion: "Cuenta Bancolombia o Davivienda. proximamente...",
              ),
              const MetodoPagoItem(
                icono: "📲",
                metodo: "Nequi",
                descripcion: "Envía al número registrado. Num# 3246272022",
              ),
              const MetodoPagoItem(
                icono: "📲",
                metodo: "Daviplata",
                descripcion: "Envía al número registrado. proximamente...",
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Entendido"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _subirImagenACloudinary() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _subiendoImagen = true);
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/creartnino/image/upload",
    );

    final uploadRequest = http.MultipartRequest("POST", url)
      ..fields['upload_preset'] =
          "CreartNino" // <- correcto
      ..fields['folder'] =
          "Comprobantes" // <- carpeta dentro de tu cuenta
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await uploadRequest.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      setState(() => _comprobantePago = data['secure_url']);
      mostrarSnackBar(context, "✅ Imagen subida correctamente");
    } else {
      mostrarSnackBar(context, "❌ Error al subir imagen");
    }

    setState(() => _subiendoImagen = false);
  }

  void _confirmarMetodoEntrega() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFFF5F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                size: 40,
                color: Colors.pinkAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                "Método de Entrega",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const Divider(height: 20, thickness: 1, color: Colors.pinkAccent),

              // ✅ Opción: Punto físico
              _OpcionEntregaItem(
                icono: "🏪",
                metodo: "Punto físico",
                descripcion: "Recoge tu pedido directamente en la tienda.",
                onTap: () async {
                  Navigator.pop(context);
                  await _mostrarAlertaConfirmacion(
                    titulo: "📍 Punto Físico",
                    mensaje: "Dirección: Calle 28 # 81-90, Medellín.",
                    latitud: 6.2442,
                    longitud: -75.5812,
                  );

                  _guardarPedido();
                },
              ),

              // ✅ Opción: A domicilio
              _OpcionEntregaItem(
                icono: "🏠",
                metodo: "Mi domicilio",
                descripcion: "Lleva el pedido a la dirección actual.",
                onTap: () async {
                  Navigator.pop(context);
                  await _confirmarDireccionDomicilio();
                },
              ),

              const SizedBox(height: 20),

              // ✅ Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarDireccionDomicilio() async {
    final departamento = _cliente["Departamento"] ?? "";
    final ciudad = _cliente["Ciudad"] ?? "";
    final direccion = _cliente["Direccion"] ?? "";

    if (!mounted) return; // seguridad antes del showDialog

    final confirmar = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFFF5F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 40,
                color: Colors.pinkAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                "Confirmar dirección",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const Divider(height: 20, thickness: 1, color: Colors.pinkAccent),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 Departamento: $departamento"),
                    Text("🏙️ Ciudad: $ciudad"),
                    Text(
                      "🏠 Dirección: ${direccion.isNotEmpty ? direccion : 'No registrada'}",
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "¿Deseas recibir el pedido en esta dirección?",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.pinkAccent,
                        side: const BorderSide(color: Colors.pinkAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.edit_location_alt_rounded),
                      label: const Text("Editar"),
                      onPressed: () => Navigator.pop(context, "no"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text("Confirmar"),
                      onPressed: () => Navigator.pop(context, "si"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return; // ⚠️ Repetido por seguridad

    if (confirmar == "si") {
      _guardarPedido();
    } else {
      // Esperar al siguiente frame para evitar context muerto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editarDireccion();
      });
    }
  }

  List<Map<String, dynamic>> departamentos = [];
  List<Map<String, dynamic>> todasCiudades = [];
  List<Map<String, dynamic>> ciudadesFiltradas = [];
  String? ciudadSeleccionada;

  Future<void> fetchDepartamentos() async {
    final response = await http.get(
      Uri.parse('https://api-colombia.com/api/v1/Department'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (!context.mounted) return;
      setState(() {
        departamentos = List<Map<String, dynamic>>.from(data)
          ..sort((a, b) => a['name'].compareTo(b['name']));
      });
    }
  }

  Future<void> fetchCiudades() async {
    final response = await http.get(
      Uri.parse(
        'https://api-colombia.com/api/v1/City/pagedList?page=1&pageSize=1000',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List items = data['data'] ?? [];
      todasCiudades = List<Map<String, dynamic>>.from(items);
    }
  }

  void filtrarCiudades(String departamentoId) {
    final selectedDep = departamentos.firstWhere(
      (dep) => dep['id'].toString() == departamentoId,
      orElse: () => {},
    );
    if (selectedDep.isNotEmpty) {
      if (!context.mounted) return;
      setState(() {
        ciudadesFiltradas =
            todasCiudades
                .where(
                  (city) =>
                      city['departmentId'].toString() ==
                      selectedDep['id'].toString(),
                )
                .toSet()
                .toList()
              ..sort((a, b) => a['name'].compareTo(b['name']));
        ciudadSeleccionada = ciudadesFiltradas.firstWhere(
          (c) => c['name'] == _cliente['Ciudad'],
          orElse: () => {'name': null},
        )['name'];
      });
    }
  }

  void _editarDireccion() async {
    await fetchDepartamentos();
    await fetchCiudades();

    String? depSeleccionado = _cliente["Departamento"];
    String? ciuSeleccionado = _cliente["Ciudad"];
    final dirController = TextEditingController(
      text: _cliente["Direccion"] ?? "",
    );

    final depId = departamentos
        .firstWhere(
          (d) => d['name'] == depSeleccionado,
          orElse: () => departamentos.first,
        )['id']
        .toString();

    filtrarCiudades(depId);

    if (!mounted) return;

    final safeContext = context; // ⬅️ Aseguramos el contexto ANTES del diálogo

    await showDialog(
      context: safeContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text("✏️ Editar dirección"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: departamentos.any((d) => d['name'] == depSeleccionado)
                      ? depSeleccionado
                      : null,
                  items: departamentos
                      .map(
                        (dep) => DropdownMenuItem<String>(
                          value: dep['name'],
                          child: Text(dep['name']),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: "Departamento",
                    prefixIcon: Icon(Icons.map, color: Colors.pinkAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      depSeleccionado = value;
                      final depObj = departamentos.firstWhere(
                        (d) => d['name'] == value,
                        orElse: () => {},
                      );
                      if (depObj.isNotEmpty) {
                        filtrarCiudades(depObj['id'].toString());
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value:
                      ciudadesFiltradas.any((c) => c['name'] == ciuSeleccionado)
                      ? ciuSeleccionado
                      : null,
                  items: ciudadesFiltradas
                      .map(
                        (ciu) => DropdownMenuItem<String>(
                          value: ciu['name'],
                          child: Text(ciu['name']),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: "Ciudad",
                    prefixIcon: Icon(
                      Icons.location_city,
                      color: Colors.pinkAccent,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      ciuSeleccionado = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dirController,
                  decoration: const InputDecoration(
                    labelText: "Dirección",
                    prefixIcon: Icon(Icons.home, color: Colors.pinkAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  ); // ⬅️ Cerramos el diálogo ANTES del async

                  Future.microtask(() async {
                    final actualizado = {
                      "IdCliente": _cliente["IdCliente"],
                      "NombreCompleto": _cliente["NombreCompleto"],
                      "TipoDocumento": _cliente["TipoDocumento"],
                      "NumDocumento": _cliente["NumDocumento"],
                      "Correo": _cliente["Correo"],
                      "Celular": _cliente["Celular"],
                      "Estado": _cliente["Estado"],
                      "Pedidos": _cliente["Pedidos"] ?? [],
                      "Departamento": depSeleccionado ?? "",
                      "Ciudad": ciuSeleccionado ?? "",
                      "Direccion": dirController.text.trim(),
                    };

                    final res = await http.put(
                      Uri.parse(
                        "https://apicreartnino.somee.com/api/Clientes/Actualizar/${_cliente["IdCliente"]}",
                      ),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode(actualizado),
                    );

                    if (!mounted) return;

                    if (res.statusCode == 200) {
                      setState(() => _cliente = actualizado);

                      mostrarSnackBar(safeContext, "✅ Dirección actualizada");

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _confirmarDireccionDomicilio();
                      });
                    } else {
                      String mensajeError = 'Error al actualizar dirección';
                      try {
                        final json = jsonDecode(res.body);
                        mensajeError = json['mensaje'] ?? mensajeError;
                      } catch (_) {}

                      if (mounted) {
                        await _mostrarAlertaConfirmacionn(
                          titulo: "❌",
                          mensaje: mensajeError,
                        );
                      }
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Guardar y continuar"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _mostrarAlertaConfirmacionn({
    required String titulo,
    required String mensaje,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarAlertaConfirmacion({
    required String titulo,
    required String mensaje,
    required double latitud,
    required double longitud,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFFFF5F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Icon(
              Icons.location_on_rounded,
              size: 40,
              color: Colors.pinkAccent,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const Divider(height: 24, thickness: 1, color: Colors.pinkAccent),

            // 🌍 Mapa de OpenStreetMap
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(latitud, longitud),
                    zoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tuapp',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitud, longitud),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            size: 40,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                mensaje,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Entendido"),
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaEntrega == null) {
      mostrarAlerta(
        context: context,
        titulo: '⚠️',
        mensaje: 'Selecciona una fecha de entrega válida.',
      );
      return;
    }

    // Verificar días hábiles (contando sábados, pero no domingos)
    bool contienePersonalizados = widget.carrito.entries.any((entry) {
      final personalizacion = widget.personalizaciones[entry.key];
      return personalizacion != null && personalizacion.isNotEmpty;
    });

    final diasMinimos = contienePersonalizados ? 5 : 3;

    int contarDiasHabiles(DateTime desde, DateTime hasta) {
      int count = 0;
      for (
        DateTime d = desde;
        d.isBefore(hasta) || d.isAtSameMomentAs(hasta);
        d = d.add(const Duration(days: 1))
      ) {
        if (d.weekday != DateTime.sunday) count++;
      }
      return count;
    }

    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final entrega = DateTime(
      _fechaEntrega!.year,
      _fechaEntrega!.month,
      _fechaEntrega!.day,
    );

    final diasHabiles = contarDiasHabiles(
      inicio.add(const Duration(days: 1)),
      entrega,
    );

    if (diasHabiles < diasMinimos) {
      mostrarAlerta(
        context: context,
        titulo: '⚠️',
        mensaje:
            'La fecha seleccionada no cumple con los $diasMinimos días hábiles requeridos (${contienePersonalizados ? "por contener productos personalizados" : "para productos prediseñados"}).',
      );
      return;
    }

    if (_cliente["IdCliente"] == null ||
        (_cliente["IdCliente"] is int && _cliente["IdCliente"] <= 0)) {
      mostrarAlerta(
        context: context,
        titulo: '⚠️',
        mensaje: 'No se encontraron datos válidos del cliente.',
      );
      return;
    }

    if (_comprobantePago.isEmpty) {
      mostrarAlerta(
        context: context,
        titulo: '⚠️',
        mensaje: 'Debes subir el comprobante de pago.',
      );
      return;
    }

    setState(() => isSaving = true);

    final descripcionFinal = widget.carrito.entries
        .map((entry) {
          final tipo = widget.personalizaciones[entry.key]?.isNotEmpty == true
              ? 'Personalizado'
              : 'Prediseñado';
          final texto = "${entry.value} x ${entry.key.nombre} ($tipo)";
          final pers = widget.personalizaciones[entry.key];
          return pers != null && pers.isNotEmpty ? "$texto - $pers" : texto;
        })
        .join(", ");

    final pedido = {
      "IdCliente": _cliente["IdCliente"],
      "MetodoPago": _metodoPago,
      "FechaPedido": DateTime.now().toIso8601String().split("T").first,
      "FechaEntrega": _fechaEntrega!.toIso8601String().split("T").first,
      "Descripcion": descripcionFinal,
      "ValorInicial": (widget.totalGenerado * 0.5).round(),
      "ValorRestante": (widget.totalGenerado * 0.5).round(),
      "TotalPedido": widget.totalGenerado.round(),
      "ComprobantePago": _comprobantePago,
      "IdEstado": 1,
      "DetallePedidos": widget.carrito.entries.map((e) {
        return {
          "IdProducto": e.key.id,
          "Cantidad": e.value,
          "Subtotal": (e.key.precio * e.value).round(),
        };
      }).toList(),
    };

    final res = await http.post(
      Uri.parse("https://www.apicreartnino.somee.com/api/Pedidos/Crear"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(pedido),
    );

    setState(() => isSaving = false);

    if (res.statusCode == 200 || res.statusCode == 201) {
      // 🔹 Descontar stock producto por producto
      for (final entry in widget.carrito.entries) {
        final productoId = entry.key.id;
        final cantidadComprada = entry.value;

        try {
          // Obtener producto actual
          final respProd = await http.get(
            Uri.parse(
              "https://www.apicreartnino.somee.com/api/Productos/Obtener/$productoId",
            ),
          );
          if (respProd.statusCode != 200) continue;

          final producto = jsonDecode(respProd.body);

          // Crear objeto actualizado con stock reducido
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

          // PUT actualizar stock
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

      mostrarSnackBar(context, "✅ Pedido creado ");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ClienteHomePageConCategorias()),
        (route) => false,
      );
    } else {
      mostrarAlerta(
        context: context,
        titulo: '❌',
        mensaje: 'Error al crear pedido.\n${res.body}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clienteController,
                      enabled: false,
                      decoration: pastelInputDecoration(
                        "Cliente",
                        Icons.person,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.pink),
                    onPressed: _mostrarModalCliente,
                    tooltip: "Ver datos del cliente",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _metodoPago,
                      items: metodos
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _metodoPago = val!),
                      decoration: pastelInputDecoration(
                        "Método de pago",
                        Icons.payment,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.pink),
                    tooltip: "Ver métodos de pago",
                    onPressed: _mostrarModalMetodoPago,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              ListTile(
                tileColor: const Color(0xFFFFF0F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  _fechaEntrega == null
                      ? 'Seleccionar fecha de entrega'
                      : _fechaEntrega!.toIso8601String().split("T").first,
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: Colors.pinkAccent,
                ),
                onTap: () async {
                  final now = DateTime.now();

                  final contienePersonalizados = widget.carrito.entries.any((
                    entry,
                  ) {
                    final pers = widget.personalizaciones[entry.key];
                    return pers != null && pers.isNotEmpty;
                  });

                  final diasMinimos = contienePersonalizados ? 5 : 3;

                  bool esDiaHabil(DateTime date) {
                    return date.weekday != DateTime.sunday;
                  }

                  bool esDiaValido(DateTime date) {
                    int habiles = 0;
                    DateTime temp = now.add(const Duration(days: 1));
                    while (!temp.isAfter(date)) {
                      if (esDiaHabil(temp)) habiles++;
                      temp = temp.add(const Duration(days: 1));
                    }
                    return esDiaHabil(date) && habiles >= diasMinimos;
                  }

                  DateTime fechaInicio = now;
                  DateTime fechaFin = DateTime(now.year + 2);

                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        contentPadding: const EdgeInsets.all(8),
                        content: SizedBox(
                          width: 300,
                          height: 360,
                          child: dp.DayPicker.single(
                            selectedDate: _fechaEntrega ?? now,
                            onChanged: (date) {
                              if (esDiaValido(date)) {
                                setState(() {
                                  _fechaEntrega = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                  );
                                });
                                Navigator.pop(context);
                              }
                            },
                            firstDate: fechaInicio,
                            lastDate: fechaFin,
                            selectableDayPredicate: esDiaValido,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _subiendoImagen ? null : _subirImagenACloudinary,
                icon: const Icon(Icons.cloud_upload),
                label: Text(
                  _subiendoImagen ? "Subiendo..." : "Subir comprobante",
                ),
                style: pastelButtonStyle(),
              ),
              const SizedBox(height: 20),
              const Text(
                "🛒 Detalle del Pedido",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...widget.carrito.entries.map((entry) {
                final producto = entry.key;
                final cantidad = entry.value;
                final precio = producto.precio;
                final subtotal = precio * cantidad;
                final personalizacion =
                    widget.personalizaciones[producto] ?? '';
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  color: const Color(0xFFFFF0F5),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🧸 ${producto.nombre}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Cantidad: $cantidad"),
                        Text("Precio: \$${precio.toStringAsFixed(0)}"),
                        Text("Subtotal: \$${subtotal.toStringAsFixed(0)}"),
                        if (personalizacion.isNotEmpty)
                          Text("🎨 Personalización: $personalizacion"),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              Text(
                "📝 Descripción ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                readOnly: true,
                maxLines: 4,
                initialValue: widget.carrito.entries
                    .map((entry) {
                      final tipo =
                          widget.personalizaciones[entry.key]?.isNotEmpty ==
                              true
                          ? 'Personalizado'
                          : 'Prediseñado';
                      final texto =
                          "${entry.value} x ${entry.key.nombre} ($tipo)";
                      final pers = widget.personalizaciones[entry.key];
                      return pers != null && pers.isNotEmpty
                          ? "$texto - $pers"
                          : texto;
                    })
                    .join(", "),
                decoration: pastelInputDecoration(
                  "Descripción generada",
                  Icons.description,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "💰 Valores del Pedido",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                readOnly: true,
                initialValue: "\$${(widget.totalGenerado * 0.5).round()}",
                decoration: pastelInputDecoration(
                  "Valor Inicial (50%)",
                  Icons.attach_money,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: "\$${(widget.totalGenerado * 0.5).round()}",
                decoration: pastelInputDecoration(
                  "Valor Restante (50%)",
                  Icons.money_off,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                readOnly: true,
                initialValue: "\$${widget.totalGenerado.round()}",
                decoration: pastelInputDecoration(
                  "Total del Pedido",
                  Icons.monetization_on,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSaving ? null : _confirmarMetodoEntrega,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Enviar Pedido"),
                style: pastelButtonStyle(height: 50),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalCliente() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFEBEE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Datos del Cliente"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🧾 Nombre: ${_cliente["NombreCompleto"] ?? "null"}"),
            Text(
              "🪪 Documento: ${_cliente["TipoDocumento"] ?? "null"} - ${_cliente["NumDocumento"] ?? "null"}",
            ),
            Text("📱 Celular: ${_cliente["Celular"] ?? "null"}"),
            Text("📍 Dirección: ${_cliente["Direccion"] ?? "No registrada"}"),
            Text(
              "🏙️ Ciudad: ${_cliente["Departamento"] ?? "null"} - ${_cliente["Ciudad"] ?? "null"}",
            ),
            Text("📧 Correo: ${_cliente["Correo"] ?? "null"}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }
}

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
    minimumSize: Size(double.infinity, height),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  );
}

class MetodoPagoItem extends StatelessWidget {
  final String icono;
  final String metodo;
  final String descripcion;

  const MetodoPagoItem({
    super.key,
    required this.icono,
    required this.metodo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icono, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15.5,
                  color: Colors.black87,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: "$metodo: ",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.pink,
                    ),
                  ),
                  TextSpan(text: descripcion),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionEntregaItem extends StatelessWidget {
  final String icono;
  final String metodo;
  final String descripcion;
  final VoidCallback onTap;

  const _OpcionEntregaItem({
    required this.icono,
    required this.metodo,
    required this.descripcion,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        highlightColor: Colors.pinkAccent.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(icono, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metodo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
