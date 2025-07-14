import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/usuario_model.dart';

class EditarPerfilPage extends StatefulWidget {
  final Usuario usuario;
  const EditarPerfilPage({super.key, required this.usuario});

  @override
  State<EditarPerfilPage> createState() => _EditarPerfilPageState();
}

class _EditarPerfilPageState extends State<EditarPerfilPage> {
  final formKey = GlobalKey<FormState>();

  late TextEditingController numDocCtrl,
      nombreCtrl,
      celularCtrl,
      correoCtrl,
      direccionCtrl,
      contrasenaCtrl,
      confirmarContrasenaCtrl;

  String? tipoDocumentoSeleccionado;
  String? departamentoSeleccionado;
  String? ciudadSeleccionada;
  bool mostrarCamposContrasena = false;

  List<Map<String, dynamic>> departamentos = [];
  List<Map<String, dynamic>> todasCiudades = [];
  List<Map<String, dynamic>> ciudadesFiltradas = [];

  final List<String> tiposDocumento = ['RC', 'TI', 'CC', 'CE', 'PP', 'PEP'];

  @override
  void initState() {
    super.initState();

    tipoDocumentoSeleccionado = widget.usuario.tipoDocumento;
    numDocCtrl = TextEditingController(text: widget.usuario.numDocumento);
    nombreCtrl = TextEditingController(text: widget.usuario.nombreCompleto);
    celularCtrl = TextEditingController(text: widget.usuario.celular);
    correoCtrl = TextEditingController(text: widget.usuario.correo);
    direccionCtrl = TextEditingController(text: widget.usuario.direccion ?? '');
    contrasenaCtrl = TextEditingController();
    confirmarContrasenaCtrl = TextEditingController();

    fetchDepartamentos();
    fetchCiudades();
  }

  Future<void> fetchDepartamentos() async {
    final response = await http.get(
      Uri.parse('https://api-colombia.com/api/v1/Department'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        departamentos = List<Map<String, dynamic>>.from(data)
          ..sort((a, b) => a['name'].compareTo(b['name']));
        departamentoSeleccionado = departamentos
            .firstWhere(
              (d) => d['name'] == widget.usuario.departamento,
              orElse: () => departamentos.first,
            )['id']
            .toString();
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
      if (departamentoSeleccionado != null) {
        filtrarCiudades(departamentoSeleccionado!);
      }
    }
  }

  void filtrarCiudades(String departamentoId) {
    final selectedDep = departamentos.firstWhere(
      (dep) => dep['id'].toString() == departamentoId,
      orElse: () => {},
    );
    if (selectedDep.isNotEmpty) {
      setState(() {
        ciudadesFiltradas =
            todasCiudades
                .where(
                  (city) =>
                      city['departmentId'].toString() ==
                      selectedDep['id'].toString(),
                )
                .toList()
              ..sort((a, b) => a['name'].compareTo(b['name']));
        ciudadSeleccionada = ciudadesFiltradas.firstWhere(
          (c) => c['name'] == widget.usuario.ciudad,
          orElse: () => {'name': null},
        )['name'];
      });
    }
  }

  Future<void> guardarCambios() async {
    if (!formKey.currentState!.validate()) return;

    if ((tipoDocumentoSeleccionado ?? '').isEmpty ||
        (departamentoSeleccionado ?? '').isEmpty ||
        (ciudadSeleccionada ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos obligatorios")),
      );
      return;
    }

    if (mostrarCamposContrasena) {
      if (contrasenaCtrl.text != confirmarContrasenaCtrl.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Las contraseñas no coinciden")),
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Usuarios/Actualizar/${widget.usuario.idUsuarios}",
    );

    final actualizado = Usuario(
      idUsuarios: widget.usuario.idUsuarios,
      nombreCompleto: nombreCtrl.text.trim(),
      tipoDocumento: tipoDocumentoSeleccionado!,
      numDocumento: numDocCtrl.text.trim(),
      celular: celularCtrl.text.trim(),
      departamento: departamentos.firstWhere(
        (dep) => dep['id'].toString() == departamentoSeleccionado,
      )['name'],
      ciudad: ciudadSeleccionada!,
      direccion: direccionCtrl.text.trim(),
      correo: correoCtrl.text.trim(),
      contrasena: contrasenaCtrl.text.isEmpty
          ? null
          : contrasenaCtrl.text.trim(),
      idRol: widget.usuario.idRol,
      estado: widget.usuario.estado,
    );

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(actualizado.toJson()),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Perfil actualizado exitosamente")),
      );
    } else {
      String mensaje = 'Error al actualizar';
      try {
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('mensaje')) {
            mensaje = data['mensaje'];
          }
        }
      } catch (_) {}
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $mensaje")));
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
                    key: formKey,
                    child: Column(
                      children: [
                        const Text(
                          "Editar Perfil",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        campoDropdown(
                          "Tipo de Documento",
                          tipoDocumentoSeleccionado,
                          tiposDocumento.map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo),
                            );
                          }).toList(),
                          icon: Icons.badge,
                          onChanged: (value) =>
                              setState(() => tipoDocumentoSeleccionado = value),
                        ),
                        campoTexto(
                          "Número Documento",
                          numDocCtrl,
                          Icons.credit_card,
                        ),
                        campoTexto("Nombre Completo", nombreCtrl, Icons.person),
                        campoTexto("Celular", celularCtrl, Icons.phone),
                        campoDropdown(
                          "Departamento",
                          departamentoSeleccionado,
                          departamentos.map((dep) {
                            return DropdownMenuItem(
                              value: dep['id'].toString(),
                              child: Text(dep['name']),
                            );
                          }).toList(),
                          icon: Icons.map,
                          onChanged: (value) {
                            setState(() => departamentoSeleccionado = value);
                            filtrarCiudades(value!);
                          },
                        ),
                        campoDropdown(
                          "Ciudad",
                          ciudadSeleccionada,
                          ciudadesFiltradas.map((city) {
                            return DropdownMenuItem<String>(
                              value: city['name'],
                              child: Text(city['name']),
                            );
                          }).toList(),
                          icon: Icons.location_city,
                          onChanged: (value) =>
                              setState(() => ciudadSeleccionada = value),
                        ),
                        campoTexto("Dirección", direccionCtrl, Icons.home),
                        campoTexto("Correo", correoCtrl, Icons.email),

                        TextButton.icon(
                          onPressed: () {
                            setState(
                              () => mostrarCamposContrasena =
                                  !mostrarCamposContrasena,
                            );
                          },
                          icon: const Icon(Icons.lock, color: Colors.pink),
                          label: Text(
                            mostrarCamposContrasena
                                ? "Cancelar cambio de contraseña"
                                : "Cambiar contraseña",
                            style: const TextStyle(color: Colors.pink),
                          ),
                        ),

                        if (mostrarCamposContrasena) ...[
                          campoTexto(
                            "Nueva Contraseña",
                            contrasenaCtrl,
                            Icons.lock,
                            esPassword: true,
                          ),
                          campoTexto(
                            "Confirmar Contraseña",
                            confirmarContrasenaCtrl,
                            Icons.lock_outline,
                            esPassword: true,
                          ),
                        ],

                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: guardarCambios,
                          icon: const Icon(Icons.save, color: Colors.black),
                          label: const Text(
                            "GUARDAR CAMBIOS",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
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
          if (label == "Dirección" ||
              label == "Nueva Contraseña" ||
              label == "Confirmar Contraseña")
            return null;
          return (value == null || value.isEmpty) ? 'Campo requerido' : null;
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
        onChanged: onChanged,
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
