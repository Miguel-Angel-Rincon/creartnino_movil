import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './recuperar_paso2_page.dart';

class RecuperarPaso1Page extends StatefulWidget {
  const RecuperarPaso1Page({Key? key}) : super(key: key);

  @override
  State<RecuperarPaso1Page> createState() => _RecuperarPaso1PageState();
}

class _RecuperarPaso1PageState extends State<RecuperarPaso1Page> {
  final correoController = TextEditingController();
  bool _loading = false;

  Future<void> enviarCodigo() async {
    final correo = correoController.text.trim();

    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Por favor ingresa tu correo registrado"),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Auth/RecuperarPaso1",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(correo),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecuperarPaso2Page(correo: correo)),
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
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
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
                          "¿Olvidaste tu contraseña?",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Ingresa tu correo para enviarte un código de recuperación",
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: correoController,
                          decoration: InputDecoration(
                            labelText: "Correo registrado",
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.pinkAccent,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
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
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : enviarCodigo,
                            icon: const Icon(Icons.send, color: Colors.black),
                            label: Text(
                              _loading ? "Enviando..." : "Enviar Código",
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
}
