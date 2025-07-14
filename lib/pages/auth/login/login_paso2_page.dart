import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:creartnino/models/usuario_model.dart';
import 'package:creartnino/providers/auth_provider.dart';

class LoginPaso2Page extends StatefulWidget {
  final String correo;
  const LoginPaso2Page({Key? key, required this.correo}) : super(key: key);

  @override
  State<LoginPaso2Page> createState() => _LoginPaso2PageState();
}

class _LoginPaso2PageState extends State<LoginPaso2Page> {
  final codigoController = TextEditingController();
  bool _loading = false;
  int segundosRestantes = 60;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    iniciarTemporizador();
  }

  void iniciarTemporizador() {
    setState(() => segundosRestantes = 60);
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (segundosRestantes == 0) {
        timer.cancel();
      } else {
        setState(() {
          segundosRestantes--;
        });
      }
    });
  }

  Future<void> verificarCodigo() async {
    setState(() => _loading = true);

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Auth/LoginPaso2",
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
      final data = jsonDecode(response.body);
      final token = data["token"];
      final idRol = data["idRol"];
      final usuarioJson = data["usuario"];

      // 🔍 Imprime datos para depuración
      print("🧪 Datos del usuario recibidos: $usuarioJson");

      // ✅ Asegúrate de tomar NumDocumento si viene así
      usuarioJson["numDocumento"] =
          usuarioJson["numDocumento"] ?? usuarioJson["NumDocumento"] ?? "";

      final usuarioObj = Usuario.fromJson(usuarioJson);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('idRol', idRol);
      await prefs.setString('correo', widget.correo);
      await prefs.setString(
        'NumDocumento',
        usuarioObj.numDocumento,
      ); // ← Aquí se guarda
      print("📄 Documento guardado en prefs: ${usuarioObj.numDocumento}");

      Provider.of<AuthProvider>(context, listen: false).setUsuario(usuarioObj);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ Sesión iniciada")));

      if (idRol == 1) {
        Navigator.pushReplacementNamed(context, '/adminHome');
      } else if (idRol == 4) {
        Navigator.pushReplacementNamed(context, '/clienteHome');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("⚠️ Rol no reconocido.")));
      }
    } else {
      final mensaje = jsonDecode(response.body)['mensaje'] ?? "Error";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $mensaje")));
    }
  }

  Future<void> reenviarCodigo() async {
    setState(() => _loading = true);

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Auth/ReenviarCodigoLogin",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(widget.correo),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      codigoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "📩 Se ha generado un nuevo código. Verifica tu correo.",
          ),
          duration: Duration(seconds: 4),
        ),
      );
      iniciarTemporizador();
    } else {
      final mensaje =
          jsonDecode(response.body)['mensaje'] ?? 'Error inesperado';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ $mensaje")));
    }
  }

  @override
  void dispose() {
    codigoController.dispose();
    _temporizador?.cancel();
    super.dispose();
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
                        Image.network(
                          'https://cdn-icons-png.flaticon.com/512/9068/9068678.png',
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Verificar Código",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Se envió un código al correo:",
                          style: TextStyle(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.correo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: codigoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Código de verificación",
                            prefixIcon: const Icon(
                              Icons.lock_open,
                              color: Colors.pinkAccent,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFFF0F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
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
                            onPressed: _loading ? null : verificarCodigo,
                            icon: const Icon(Icons.login, color: Colors.black),
                            label: Text(
                              _loading ? "Verificando..." : "Ingresar",
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
                        if (segundosRestantes > 0)
                          Text(
                            "Puedes reenviar en $segundosRestantes segundos",
                            style: const TextStyle(color: Colors.grey),
                          )
                        else
                          TextButton.icon(
                            onPressed: _loading ? null : reenviarCodigo,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.pinkAccent,
                            ),
                            label: const Text(
                              "Reenviar código",
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
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
