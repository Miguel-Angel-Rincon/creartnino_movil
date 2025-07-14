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

  String? tipoDocumentoSeleccionado;
  String? departamentoSeleccionado;
  String? ciudadSeleccionada;
  List<Map<String, dynamic>> departamentos = [];
  List<Map<String, dynamic>> todasCiudades = [];
  List<Map<String, dynamic>> ciudadesFiltradas = [];
  bool _loading = false;

  final List<String> tiposDocumento = ['RC', 'TI', 'CC', 'CE', 'PP', 'PEP'];

  @override
  void initState() {
    super.initState();
    fetchDepartamentos();
    fetchCiudades();
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

    setState(() => _loading = true);

    final usuario = {
      "tipoDocumento": tipoDocumentoSeleccionado,
      "numDocumento": numDocController.text,
      "nombreCompleto": nombreController.text,
      "celular": celularController.text,
      "correo": correoController.text,
      "contrasena": contrasenaController.text,
      "departamento": departamentos.firstWhere(
        (dep) => dep['id'].toString() == departamentoSeleccionado,
      )['name'],
      "ciudad": ciudadSeleccionada,
      "direccion": null,
      "estado": true,
      "idRol": 4,
    };

    final response = await http.post(
      Uri.parse("http://www.apicreartnino.somee.com/api/Usuarios/Crear"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(usuario),
    );

    if (response.statusCode == 200) {
      final codigoResponse = await http.post(
        Uri.parse(
          "http://www.apicreartnino.somee.com/api/Usuarios/EnviarCodigoCorreo",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(correoController.text),
      );

      setState(() => _loading = false);

      if (codigoResponse.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificarCodigoPage(correo: correoController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al enviar el código: ${codigoResponse.body}"),
          ),
        );
      }
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar: ${response.body}")),
      );
    }
  }

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
                          tiposDocumento
                              .map(
                                (tipo) => DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo),
                                ),
                              )
                              .toList(),
                          icon: Icons.badge,
                          onChanged: (value) =>
                              setState(() => tipoDocumentoSeleccionado = value),
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
                              _loading ? "Registrando..." : "REGISTRARSE",
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
