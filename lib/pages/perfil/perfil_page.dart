import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/usuario_model.dart';
import 'editar_perfil_page.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Usuario? usuario;

  @override
  void initState() {
    super.initState();
    obtenerPerfil();
  }

  Future<void> obtenerPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Sesión expirada, inicia sesión nuevamente"),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final url = Uri.parse(
      "http://www.apicreartnino.somee.com/api/Usuarios/perfil",
    );

    try {
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          usuario = Usuario.perfilFromJson(data);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ No se pudo cargar el perfil")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (usuario == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 90),
            child: ListView(
              children: [
                const Text(
                  "Información del Perfil",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                buildItem("🪪 Tipo Documento", usuario!.tipoDocumento),
                buildItem("🔢 Número Documento", usuario!.numDocumento),
                buildItem("👤 Nombre Completo", usuario!.nombreCompleto),
                buildItem("📱 Celular", usuario!.celular),
                buildItem("📍 Departamento", usuario!.departamento),
                buildItem("🏙️ Ciudad", usuario!.ciudad),
                buildItem(
                  "🏠 Dirección",
                  usuario!.direccion?.isEmpty ?? true
                      ? "No registrada"
                      : usuario!.direccion!,
                ),
                buildItem("📧 Correo Electrónico", usuario!.correo),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8BBD0), Color(0xFFFFF3E0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final actualizado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarPerfilPage(usuario: usuario!),
                    ),
                  );
                  if (actualizado == true) obtenerPerfil();
                },
                icon: const Icon(Icons.edit, color: Colors.black),
                label: const Text(
                  "Editar Perfil",
                  style: TextStyle(
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
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
