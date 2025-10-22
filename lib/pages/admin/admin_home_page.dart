import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:creartnino/pages/admin/pedidos_page_admin.dart';
import 'package:creartnino/pages/perfil/perfil_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/pastel_bottom_navbar.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _InicioAdminView(),
    PedidosPageAdmin(),
    PerfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: PastelBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        esAdmin: true,
        onLogout: _cerrarSesion,
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
    }
  }
}

class _InicioAdminView extends StatefulWidget {
  const _InicioAdminView();

  @override
  State<_InicioAdminView> createState() => _InicioAdminViewState();
}

class _InicioAdminViewState extends State<_InicioAdminView> {
  bool cargando = true;

  int pedidosHoy = 0;
  int pedidosSemana = 0;
  int pedidosMes = 0;
  int pedidosAnio = 0;

  double ingresosHoy = 0;
  double ingresosSemana = 0;
  double ingresosMes = 0;
  double ingresosAnio = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final res = await http.get(
        Uri.parse("https://www.apicreartnino.somee.com/api/Pedidos/Lista"),
      );
      if (res.statusCode != 200) throw Exception("Error al obtener pedidos");

      final List pedidos = json.decode(res.body);
      final hoy = DateTime.now();
      final inicioSemana = hoy.subtract(
        Duration(days: hoy.weekday - 1),
      ); // Lunes actual
      final finSemana = inicioSemana.add(const Duration(days: 6));

      int contHoy = 0, contSemana = 0, contMes = 0, contAnio = 0;
      double sumHoy = 0, sumSemana = 0, sumMes = 0, sumAnio = 0;

      for (final p in pedidos) {
        final idEstado = p['IdEstado'];
        final fechaPedidoStr = p['FechaPedido'];
        final fechaEntregaStr = p['FechaEntrega'];
        final totalPedido = (p['TotalPedido'] ?? 0).toDouble();

        if (fechaPedidoStr == null) continue;

        // 🔹 Parsear correctamente las fechas (sin hora)
        DateTime? fechaPedido;
        DateTime? fechaEntrega;
        try {
          fechaPedido = DateTime.parse(fechaPedidoStr.split("T")[0]);
          if (fechaEntregaStr != null) {
            fechaEntrega = DateTime.parse(fechaEntregaStr.split("T")[0]);
          }
        } catch (_) {}

        // ====== CONTAR PEDIDOS ======
        if (idEstado != 6 && fechaPedido != null) {
          if (_esMismoDia(fechaPedido, hoy)) contHoy++;
          if (fechaPedido.isAfter(
                inicioSemana.subtract(const Duration(days: 1)),
              ) &&
              fechaPedido.isBefore(finSemana.add(const Duration(days: 1))))
            contSemana++;
          if (fechaPedido.year == hoy.year && fechaPedido.month == hoy.month)
            contMes++;
          if (fechaPedido.year == hoy.year) contAnio++;
        }

        // ====== SUMAR INGRESOS ======
        if ((idEstado == 5 || idEstado == 7) && fechaEntrega != null) {
          if (_esMismoDia(fechaEntrega, hoy)) sumHoy += totalPedido;
          if (fechaEntrega.isAfter(
                inicioSemana.subtract(const Duration(days: 1)),
              ) &&
              fechaEntrega.isBefore(finSemana.add(const Duration(days: 1))))
            sumSemana += totalPedido;
          if (fechaEntrega.year == hoy.year && fechaEntrega.month == hoy.month)
            sumMes += totalPedido;
          if (fechaEntrega.year == hoy.year) sumAnio += totalPedido;
        }
      }

      setState(() {
        pedidosHoy = contHoy;
        pedidosSemana = contSemana;
        pedidosMes = contMes;
        pedidosAnio = contAnio;
        ingresosHoy = sumHoy;
        ingresosSemana = sumSemana;
        ingresosMes = sumMes;
        ingresosAnio = sumAnio;
        cargando = false;
      });
    } catch (e) {
      print("Error al cargar datos: $e");
      setState(() => cargando = false);
    }
  }

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Panel de Administración 👨‍💼",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            "📦 Pedidos",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStatCard("Hoy", pedidosHoy.toString(), Icons.today),
          _buildStatCard(
            "Semana actual",
            pedidosSemana.toString(),
            Icons.calendar_view_week,
          ),
          _buildStatCard(
            "Mes actual",
            pedidosMes.toString(),
            Icons.calendar_month,
          ),
          _buildStatCard("Año actual", pedidosAnio.toString(), Icons.event),

          const SizedBox(height: 30),
          const Text(
            "💰 Ingresos",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStatCard("Hoy", _formatMoney(ingresosHoy), Icons.attach_money),
          _buildStatCard(
            "Semana actual",
            _formatMoney(ingresosSemana),
            Icons.calendar_view_week,
          ),
          _buildStatCard(
            "Mes actual",
            _formatMoney(ingresosMes),
            Icons.calendar_month,
          ),
          _buildStatCard("Año actual", _formatMoney(ingresosAnio), Icons.event),

          const SizedBox(height: 40),
          Center(
            child: Text(
              "📊 Resumen general actualizado automáticamente",
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double valor) {
    return "\$${valor.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade100.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icono, color: Colors.pinkAccent, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "$titulo: $valor",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
