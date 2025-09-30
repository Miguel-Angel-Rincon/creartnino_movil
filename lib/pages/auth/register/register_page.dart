import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './verificar_codigo_page.dart';
import '../login/login_paso1_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final numDocController = TextEditingController();
  final nombreController = TextEditingController();
  final celularController = TextEditingController();
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final confirmarContrasenaController = TextEditingController();
  final direccionController = TextEditingController();

  String? tipoDocumentoSeleccionado;
  String? departamentoSeleccionado;
  String? ciudadSeleccionada;
  List<Map<String, dynamic>> departamentos = [];
  List<Map<String, dynamic>> todasCiudades = [];
  List<Map<String, dynamic>> ciudadesFiltradas = [];
  bool _loading = false;

  final List<Map<String, String>> tiposDocumento = [
    {"abreviatura": "TI", "nombre": "Tarjeta de Identidad"},
    {"abreviatura": "CC", "nombre": "Cédula de Ciudadanía"},
    {"abreviatura": "CE", "nombre": "Cédula de Extranjería"},
    {"abreviatura": "PEP", "nombre": "Permiso Especial de Permanencia"},
  ];

  @override
  void initState() {
    super.initState();
    fetchDepartamentos();
    fetchCiudades();
  }

  @override
  void dispose() {
    numDocController.dispose();
    nombreController.dispose();
    celularController.dispose();
    correoController.dispose();
    contrasenaController.dispose();
    confirmarContrasenaController.dispose();
    super.dispose();
  }

  Future<void> fetchDepartamentos() async {
    final url = Uri.parse('https://api-colombia.com/api/v1/Department');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        departamentos = List<Map<String, dynamic>>.from(data)
          ..sort((a, b) => a['name'].compareTo(b['name']));
      });
    }
  }

  Future<void> fetchCiudades() async {
    final url = Uri.parse(
      'https://api-colombia.com/api/v1/City/pagedList?page=1&pageSize=1000',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List items = data['data'] ?? [];
      setState(() {
        todasCiudades = List<Map<String, dynamic>>.from(items);
        ciudadesFiltradas = [];
        if (departamentoSeleccionado != null) {
          filtrarCiudades(departamentoSeleccionado!);
        }
      });
    }
  }

  void filtrarCiudades(String departamentoId) {
    setState(() {
      final selectedDep = departamentos.firstWhere(
        (dep) => dep['id'].toString() == departamentoId,
        orElse: () => {},
      );
      if (selectedDep.isNotEmpty) {
        ciudadesFiltradas =
            todasCiudades
                .where(
                  (city) =>
                      city['departmentId'].toString() ==
                      selectedDep['id'].toString(),
                )
                .toList()
              ..sort((a, b) => a['name'].compareTo(b['name']));
      } else {
        ciudadesFiltradas = [];
      }
      ciudadSeleccionada = null;
    });
  }

  bool _emailValido(String email) {
    final re = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    return re.hasMatch(email);
  }

  Future<void> registrarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if ((tipoDocumentoSeleccionado ?? '').isEmpty ||
        (departamentoSeleccionado ?? '').isEmpty ||
        (ciudadSeleccionada ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    if (contrasenaController.text != confirmarContrasenaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    if (!_emailValido(correoController.text)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ingresa un correo válido")));
      return;
    }

    setState(() => _loading = true);

    // Construyo los payloads (NO los envío aquí)
    final departamentoNombre = departamentos.firstWhere(
      (dep) => dep['id'].toString() == departamentoSeleccionado,
    )['name'];

    final usuarioPayload = {
      "tipoDocumento": tipoDocumentoSeleccionado,
      "numDocumento": numDocController.text,
      "nombreCompleto": nombreController.text,
      "celular": celularController.text,
      "correo": correoController.text,
      "contrasena": contrasenaController.text,
      "departamento": departamentoNombre,
      "ciudad": ciudadSeleccionada,
      "direccion": direccionController.text,
      "estado": true,
      "idRol": 4,
    };

    final clientePayload = {
      "nombreCompleto": nombreController.text,
      "tipoDocumento": tipoDocumentoSeleccionado,
      "numDocumento": numDocController.text,
      "correo": correoController.text,
      "celular": celularController.text,
      "departamento": departamentoNombre,
      "ciudad": ciudadSeleccionada,
      "direccion": direccionController.text,
      "estado": true,
    };

    try {
      final url = Uri.parse(
        "http://www.apicreartnino.somee.com/api/Usuarios/EnviarCodigoCorreo",
      );

      // Intento 1: enviar como JSON string (jsonEncode(email))
      var resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(correoController.text),
      );

      // Si falla, intentar como objeto { "correo": "..." } (por compatibilidad)
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        resp = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"correo": correoController.text}),
        );
      }

      setState(() => _loading = false);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        // Navego a la pantalla de verificación y le paso los payloads (NO creamos usuario aquí)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificarCodigoPage(
              correo: correoController.text,
              usuarioPayload: usuarioPayload,
              clientePayload: clientePayload,
            ),
          ),
        );
      } else {
        // Mostrar el body del servidor si existe
        String serverMsg = resp.body.isNotEmpty
            ? resp.body
            : 'No se pudo enviar el código.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar el código: $serverMsg")),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al enviar el código: $e")));
    }
  }

  // --- UI (sin cambios importantes) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                        color: Colors.pinkAccent.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          "Registrarse",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        campoDropdown(
                          "Tipo de Documento",
                          tipoDocumentoSeleccionado,
                          tiposDocumento.map((tipo) {
                            return DropdownMenuItem<String>(
                              value:
                                  tipo["abreviatura"], // se guarda la abreviatura
                              child: SizedBox(
                                width:
                                    200, // 👈 ajusta este ancho según tu diseño
                                child: Text(
                                  tipo["nombre"]!,
                                  overflow: TextOverflow
                                      .ellipsis, // muestra "..." si se pasa
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            );
                          }).toList(),
                          icon: Icons.badge,
                          onChanged: (value) {
                            setState(() {
                              tipoDocumentoSeleccionado = value;
                            });
                          },
                        ),

                        campoTexto(
                          "Número de Documento",
                          numDocController,
                          Icons.credit_card,
                        ),
                        campoTexto(
                          "Nombre Completo",
                          nombreController,
                          Icons.person,
                        ),
                        campoTexto("Celular", celularController, Icons.phone),
                        campoDropdown(
                          "Departamento",
                          departamentoSeleccionado,
                          departamentos
                              .map(
                                (dep) => DropdownMenuItem(
                                  value: dep['id'].toString(),
                                  child: Text(dep['name']),
                                ),
                              )
                              .toList(),
                          icon: Icons.map,
                          onChanged: (value) {
                            setState(() => departamentoSeleccionado = value);
                            if (value != null) filtrarCiudades(value);
                          },
                        ),
                        campoDropdown(
                          "Ciudad",
                          ciudadSeleccionada,
                          ciudadesFiltradas
                              .map(
                                (city) => DropdownMenuItem<String>(
                                  value: city['name'] as String,
                                  child: Text(city['name']),
                                ),
                              )
                              .toList(),
                          icon: Icons.location_city,
                          onChanged: (value) =>
                              setState(() => ciudadSeleccionada = value),
                        ),
                        campoTexto(
                          "Dirección",
                          direccionController,
                          Icons.home,
                        ),
                        campoTexto(
                          "Correo Electrónico",
                          correoController,
                          Icons.email,
                        ),
                        campoTexto(
                          "Contraseña",
                          contrasenaController,
                          Icons.lock,
                          esPassword: true,
                        ),
                        campoTexto(
                          "Confirmar Contraseña",
                          confirmarContrasenaController,
                          Icons.lock_outline,
                          esPassword: true,
                        ),
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF8BBD0), Color(0xFFFFF3E0)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : registrarUsuario,
                            icon: const Icon(
                              Icons.person_add,
                              color: Colors.black,
                            ),
                            label: Text(
                              _loading ? "Enviando código..." : "REGISTRARSE",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("¿Ya tienes una cuenta? "),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPaso1Page(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Iniciar sesión",
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget campoTexto(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool esPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: esPassword,
        validator: (value) {
          // Eliminar espacios al inicio y al final
          final input = value?.trim() ?? "";

          if (input.isEmpty) return 'Campo requerido';

          switch (label) {
            case "Número de Documento":
              if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
                return "Solo números";
              }
              if (input.length < 7 || input.length > 11) {
                return "Debe tener entre 7 y 11 dígitos";
              }
              if (RegExp(r'^0+$').hasMatch(input)) {
                return "No puede ser solo ceros";
              }
              break;

            case "Nombre Completo":
              if (input.length < 3) return "Ingresa un nombre válido";
              if (!RegExp(r'^[a-zA-ZÁÉÍÓÚáéíóúñÑ ]+$').hasMatch(input)) {
                return "Solo letras y espacios";
              }
              break;

            case "Celular":
              if (!RegExp(r'^[0-9]{10}$').hasMatch(input)) {
                return "Debe tener 10 dígitos";
              }
              if (RegExp(r'^0+$').hasMatch(input)) {
                return "No puede ser solo ceros";
              }
              break;

            case "Correo Electrónico":
              if (!RegExp(
                r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$',
              ).hasMatch(input)) {
                return "Correo inválido";
              }
              break;

            case "Contraseña":
              if (input.length < 8) return "Mínimo 8 caracteres";
              if (!RegExp(
                r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).+$',
              ).hasMatch(input)) {
                return "Debe incluir mayúscula, minúscula, número y carácter especial";
              }
              break;

            case "Confirmar Contraseña":
              if (input != contrasenaController.text.trim()) {
                return "Las contraseñas no coinciden";
              }
              break;
          }

          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.pinkAccent),
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFFF0F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget campoDropdown(
    String label,
    String? valor,
    List<DropdownMenuItem<String>> items, {
    required IconData icon,
    void Function(String?)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: valor != "" ? valor : null,
        items: items,
        onChanged: onChanged ?? (value) => setState(() => valor = value),
        validator: (value) =>
            value == null || value.isEmpty ? 'Campo requerido' : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.pinkAccent),
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFFF0F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
