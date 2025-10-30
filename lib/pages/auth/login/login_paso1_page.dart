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
    // Validar campos vacíos
    if (correoController.text.trim().isEmpty ||
        contrasenaController.text.trim().isEmpty) {
      _mostrarDialogo(
        "Campos vacíos",
        "Por favor completa todos los campos.",
        Icons.warning,
        Colors.orange,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ Primero verificar el estado del usuario
      final usuariosUrl = Uri.parse(
        "https://www.apicreartnino.somee.com/api/Usuarios/Lista",
      );

      final usuariosResponse = await http.get(usuariosUrl);

      if (usuariosResponse.statusCode != 200) {
        throw Exception("No se pudo verificar el usuario");
      }

      final List<dynamic> listaUsuarios = jsonDecode(usuariosResponse.body);

      // Buscar el usuario por correo
      final usuario = listaUsuarios.firstWhere(
        (u) =>
            u['Correo']?.toString().toLowerCase() ==
            correoController.text.trim().toLowerCase(),
        orElse: () => null,
      );

      if (usuario == null) {
        setState(() => _loading = false);
        _mostrarDialogo(
          "Error",
          "Usuario no encontrado",
          Icons.error,
          Colors.red,
        );
        return;
      }

      // 2️⃣ Verificar si el usuario está activo
      if (usuario['Estado'] == false) {
        setState(() => _loading = false);
        _mostrarDialogoEstadoInactivo();
        return;
      }

      // 3️⃣ Si está activo, proceder con el login normal
      final loginUrl = Uri.parse(
        "http://www.apicreartnino.somee.com/api/Auth/LoginPaso1",
      );

      final loginResponse = await http.post(
        loginUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "correo": correoController.text.trim(),
          "contrasena": contrasenaController.text,
        }),
      );

      setState(() => _loading = false);

      if (loginResponse.statusCode == 200) {
        _mostrarDialogo(
          "Verificación exitosa",
          "Ahora ingresa el código enviado a tu correo.",
          Icons.check_circle,
          Colors.green,
        );

        // Navegar a la siguiente pantalla
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                LoginPaso2Page(correo: correoController.text.trim()),
          ),
        );
      } else {
        final errorData = jsonDecode(loginResponse.body);
        _mostrarDialogo(
          "Error",
          errorData['mensaje'] ?? "Credenciales inválidas",
          Icons.error,
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      _mostrarDialogo(
        "Error de conexión",
        "Hubo un problema al conectar con el servidor. Intenta nuevamente.",
        Icons.error,
        Colors.red,
      );
    }
  }

  // Diálogo personalizado para cuenta desactivada
  void _mostrarDialogoEstadoInactivo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              "Acceso denegado",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tu cuenta ha sido desactivada",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              "Por favor, contacta al administrador para más información.",
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.phone, size: 18, color: Colors.pinkAccent),
                      SizedBox(width: 8),
                      Text(
                        "Teléfono:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("+57 324 627 2022"),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.email, size: 18, color: Colors.pinkAccent),
                      SizedBox(width: 8),
                      Text(
                        "Correo:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("creartnino23@gmail.com"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  // Diálogo genérico para otros mensajes
  void _mostrarDialogo(
    String titulo,
    String mensaje,
    IconData icono,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                titulo,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
                        // 🌸 Imagen del logo redondeada y más grande
                        Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.pinkAccent.shade100,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(90),
                            child: Image.asset(
                              'assets/logos/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
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
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
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
