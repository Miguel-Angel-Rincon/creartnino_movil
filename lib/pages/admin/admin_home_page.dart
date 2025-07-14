import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creartnino/pages/admin/pedidos_page_admin.dart';
import 'package:creartnino/pages/perfil/perfil_page.dart';
import '../../widgets/pastel_bottom_navbar.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _InicioAdminView(), // 🏠 Inicio
    PedidosPageAdmin(), // 📦 Pedidos
    PerfilPage(), // 👤 Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: PastelBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        esAdmin: true,
        onLogout: _cerrarSesion, // 👈 llamada directa al método de logout
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🧼 Limpia los datos de sesión
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
    }
  }
}

class _InicioAdminView extends StatelessWidget {
  const _InicioAdminView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Bienvenido, administrador 👨‍💼",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.pinkAccent,
        ),
      ),
    );
  }
}
