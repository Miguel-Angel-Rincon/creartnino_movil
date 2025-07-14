import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:creartnino/providers/auth_provider.dart';

// Páginas principales
import 'package:creartnino/pages/admin/admin_home_page.dart';
import 'package:creartnino/pages/cliente/cliente_home_page.dart';
import 'package:creartnino/pages/perfil/perfil_page.dart';
import 'package:creartnino/pages/admin/pedidos_page_admin.dart';
import 'package:creartnino/pages/cliente/MisPedidosPage.dart';
import 'screens/categorias_page.dart';

// Páginas de autenticación
import 'pages/auth/login/login_paso1_page.dart';
import 'pages/auth/login/login_paso2_page.dart';
import 'pages/auth/register/register_page.dart';
import 'pages/auth/welcome_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AuthProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CreartNiño App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFFDE8F0),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFFFF0F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomePage(),
            '/login': (context) => const LoginPaso1Page(),
            '/verificar-login': (context) => const LoginPaso2Page(correo: ''),
            '/registro': (context) => const RegisterPage(),
            '/adminHome': (context) => const AdminHomePage(),
            '/clienteHome': (context) => const ClienteHomePageConCategorias(),
            '/perfil': (context) => const PerfilPage(),
            '/adminPedidos': (context) => const PedidosPageAdmin(),
            '/Categorias': (context) => CategoriasPage(),
            '/misPedidos': (context) {
              final usuario = authProvider.usuario;
              return MisPedidosPage(numDocumento: usuario?.numDocumento ?? '');
            },
          },
        );
      },
    );
  }
}
