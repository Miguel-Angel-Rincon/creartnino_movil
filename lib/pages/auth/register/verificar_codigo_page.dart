import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificarCodigoPage extends StatefulWidget {
  final String correo;
  final Map<String, dynamic> usuarioPayload;
  final Map<String, dynamic> clientePayload;

  const VerificarCodigoPage({
    required this.correo,
    required this.usuarioPayload,
    required this.clientePayload,
    Key? key,
  }) : super(key: key);

  @override
  State<VerificarCodigoPage> createState() => _VerificarCodigoPageState();
}

class _VerificarCodigoPageState extends State<VerificarCodigoPage> {
  final TextEditingController codigoController = TextEditingController();
  bool _loading = false;
  bool _resendLoading = false;

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
  }

  Future<void> verificarCodigo() async {
    final verifyUrl = Uri.parse(
      'http://www.apicreartnino.somee.com/api/Usuarios/VerificarCodigoCorreo',
    );

    setState(() => _loading = true);

    try {
      final verifyResp = await http.post(
        verifyUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": widget.correo,
          "codigo": codigoController.text,
        }),
      );

      if (verifyResp.statusCode < 200 || verifyResp.statusCode >= 300) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Código incorrecto: ${verifyResp.body}')),
        );
        return;
      }

      // Si el código es correcto, creamos primero el usuario y luego el cliente
      final usuarioUrl = Uri.parse(
        "http://www.apicreartnino.somee.com/api/Usuarios/Crear",
      );
      final usuarioResp = await http.post(
        usuarioUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(widget.usuarioPayload),
      );

      if (usuarioResp.statusCode < 200 || usuarioResp.statusCode >= 300) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear usuario: ${usuarioResp.body}'),
          ),
        );
        return;
      }

      final clienteUrl = Uri.parse(
        "http://www.apicreartnino.somee.com/api/Clientes/Crear",
      );
      final clienteResp = await http.post(
        clienteUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(widget.clientePayload),
      );

      setState(() => _loading = false);

      if (clienteResp.statusCode < 200 || clienteResp.statusCode >= 300) {
        // Nota: aquí detectamos que el usuario ya se creó pero el cliente falló.
        // Si tu backend tiene una ruta para eliminar o deshacer el usuario, deberías llamarla aquí.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear cliente: ${clienteResp.body}'),
          ),
        );
        return;
      }

      // Todo ok
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Correo verificado y cuenta creada correctamente'),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> reenviarCodigo() async {
    setState(() => _resendLoading = true);
    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Usuarios/EnviarCodigoCorreo",
    );

    try {
      var resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(widget.correo),
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        resp = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"correo": widget.correo}),
        );
      }

      setState(() => _resendLoading = false);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado. Revisa tu correo.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reenviar: ${resp.body}')),
        );
      }
    } catch (e) {
      setState(() => _resendLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al reenviar: $e')));
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
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.pinkAccent,
                        ),
                      ),
                    ),
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
                    onPressed: _resendLoading ? null : reenviarCodigo,
                    child: Text(
                      _resendLoading
                          ? "Reenviando..."
                          : "¿No recibiste el código? Reenviar",
                      style: const TextStyle(color: Colors.pinkAccent),
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
