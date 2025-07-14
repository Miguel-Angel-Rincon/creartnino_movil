import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificarCodigoPage extends StatefulWidget {
  final String correo;
  const VerificarCodigoPage({required this.correo});

  @override
  State<VerificarCodigoPage> createState() => _VerificarCodigoPageState();
}

class _VerificarCodigoPageState extends State<VerificarCodigoPage> {
  final TextEditingController codigoController = TextEditingController();
  bool _loading = false;

  Future<void> verificarCodigo() async {
    setState(() => _loading = true);

    final url = Uri.parse(
      'http://www.apicreartnino.somee.com/api/Usuarios/VerificarCodigoCorreo',
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": widget.correo,
        "codigo": codigoController.text,
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Correo verificado correctamente')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('❌ Código incorrecto')));
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 380,
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
                    Icons.verified_user,
                    size: 60,
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Verificación de Código",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Se envió un código de verificación a:",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.correo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: codigoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Código de verificación",
                      labelStyle: const TextStyle(color: Color(0xFF607D8B)),
                      filled: true,
                      fillColor: const Color(0xFFFFF0F5),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Colors.pinkAccent,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Loader mientras se verifica
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.pinkAccent,
                        ),
                      ),
                    ),

                  // Botón con degradado pastel
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
                      onPressed: _loading ? null : verificarCodigo,
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.black,
                      ),
                      label: Text(
                        _loading ? "Verificando..." : "Verificar",
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
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      // Aquí podrías implementar reenviar código si tu API lo permite
                    },
                    child: const Text(
                      "¿No recibiste el código? Reenviar",
                      style: TextStyle(color: Colors.pinkAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
