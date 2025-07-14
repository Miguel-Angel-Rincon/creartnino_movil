import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_paso2_page.dart';
import '../recuperar/recuperar_paso1_page.dart';
import '../register/register_page.dart';

class LoginPaso1Page extends StatefulWidget {
  const LoginPaso1Page({Key? key}) : super(key: key);

  @override
  State<LoginPaso1Page> createState() => _LoginPaso1PageState();
}

class _LoginPaso1PageState extends State<LoginPaso1Page> {
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  bool _loading = false;

  Future<void> enviarCodigo() async {
    setState(() => _loading = true);

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Auth/LoginPaso1",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": correoController.text,
        "contrasena": contrasenaController.text,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPaso2Page(correo: correoController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${jsonDecode(response.body)['mensaje']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8BBD0), Color(0xFFFFF3E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://cdn-icons-png.flaticon.com/512/9460/9460929.png',
                          height: 120,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Bienvenid@s CreartNino",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _campoTexto("Correo", correoController, Icons.email),
                        const SizedBox(height: 12),
                        _campoTexto(
                          "Contraseña",
                          contrasenaController,
                          Icons.lock,
                          esPassword: true,
                        ),
                        const SizedBox(height: 30),
                        _botonGradient(
                          text: _loading ? "Ingresando..." : "Ingresar",
                          icon: Icons.login,
                          onPressed: _loading ? null : enviarCodigo,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("¿Olvidaste tu contraseña? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RecuperarPaso1Page(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Recupérala aquí",
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("¿No tienes cuenta? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Regístrate",
                                style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool esPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: esPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        filled: true,
        fillColor: const Color(0xFFFFF0F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _botonGradient({
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
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
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black),
        label: Text(
          text,
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
    );
  }
}
