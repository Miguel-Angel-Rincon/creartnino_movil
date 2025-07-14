import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './CambiarContrasenaPage.dart';

class RecuperarPaso2Page extends StatefulWidget {
  final String correo;
  const RecuperarPaso2Page({Key? key, required this.correo}) : super(key: key);

  @override
  State<RecuperarPaso2Page> createState() => _RecuperarPaso2PageState();
}

class _RecuperarPaso2PageState extends State<RecuperarPaso2Page> {
  final codigoController = TextEditingController();
  bool _loading = false;
  bool _reenviando = false;

  Future<void> validarCodigo() async {
    final codigo = codigoController.text.trim();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Ingresa el código de recuperación")),
      );
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Auth/ValidarCodigoRecuperacion",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": widget.correo, "codigo": codigo}),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CambiarContrasenaPage(correo: widget.correo, codigo: codigo),
        ),
      );
    } else {
      final mensaje =
          jsonDecode(response.body)["mensaje"] ??
          "Código incorrecto o expirado";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $mensaje")));
    }
  }

  Future<void> reenviarCodigo() async {
    setState(() => _reenviando = true);

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Auth/ReenviarCodigoRecuperacion",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(widget.correo),
    );

    setState(() => _reenviando = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Código reenviado correctamente.")),
      );
    } else {
      final mensaje =
          jsonDecode(response.body)["mensaje"] ?? "Error al reenviar el código";
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
                      Icons.lock_clock,
                      size: 80,
                      color: Color(0xFFF8BBD0),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Verifica tu código",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: codigoController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
                        "Código de recuperación",
                        Icons.key,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : validarCodigo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8BBD0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _loading ? "Verificando..." : "Validar Código",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _reenviando ? null : reenviarCodigo,
                      child: Text(
                        _reenviando
                            ? "Reenviando..."
                            : "¿No recibiste el código? Reenviar",
                        style: const TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.w600,
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
