// lib/widgets/pastel_layout.dart
import 'package:flutter/material.dart';
import 'pastel_bottom_navbar.dart';

class PastelLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool esAdmin;

  const PastelLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.esAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: PastelBottomNavBar(
        currentIndex: currentIndex,
        onTap:
            (
              _,
            ) {}, // 👈 Solo necesario si lo requiere el widget, navegación ya se hace dentro
        esAdmin: esAdmin,
      ),
    );
  }
}
