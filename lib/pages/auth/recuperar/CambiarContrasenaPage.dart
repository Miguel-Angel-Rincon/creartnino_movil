import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login/login_paso1_page.dart';

class CambiarContrasenaPage extends StatefulWidget {
  final String correo;
  final String codigo;

  const CambiarContrasenaPage({
    Key? key,
    required this.correo,
    required this.codigo,
  }) : super(key: key);

  @override
  State<CambiarContrasenaPage> createState() => _CambiarContrasenaPageState();
}

class _CambiarContrasenaPageState extends State<CambiarContrasenaPage> {
  final nuevaController = TextEditingController();
  final confirmarController = TextEditingController();
  bool _loading = false;

  Future<void> cambiarContrasena() async {
    final nueva = nuevaController.text.trim();
    final confirmar = confirmarController.text.trim();

    if (nueva.isEmpty || confirmar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Llena todos los campos")),
      );
      return;
    }

    if (nueva != confirmar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Las contraseñas no coinciden")),
      );
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Auth/RecuperarPaso2",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": widget.correo,
        "codigo": widget.codigo,
        "nuevaContrasena": nueva,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Contraseña actualizada con éxito")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPaso1Page()),
        (route) => false,
      );
    } else {
      final mensaje =
          jsonDecode(response.body)["mensaje"] ?? "Error inesperado";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $mensaje")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8BBD0), Color(0xFFFFF3E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: Color(0xFFF8BBD0),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Nueva contraseña",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nuevaController,
                      obscureText: true,
                      decoration: _buildInputDecoration(
                        "Nueva contraseña",
                        Icons.lock_open,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmarController,
                      obscureText: true,
                      decoration: _buildInputDecoration(
                        "Confirmar contraseña",
                        Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : cambiarContrasena,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8BBD0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _loading ? "Procesando..." : "Cambiar Contraseña",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
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
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.pinkAccent),
      filled: true,
      fillColor: const Color(0xFFFFF0F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}
