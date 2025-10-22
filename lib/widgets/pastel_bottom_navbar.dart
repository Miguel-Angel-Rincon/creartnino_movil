import 'package:flutter/material.dart';

class PastelBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool esAdmin;
  final VoidCallback? onLogout; // 👈 NUEVO parámetro

  const PastelBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.esAdmin = false,
    this.onLogout, // 👈 Agregado al constructor
  });

  @override
  Widget build(BuildContext context) {
    final List<_NavItem> navItems = esAdmin
        ? [
            _NavItem(Icons.home, ''),
            _NavItem(Icons.shopping_bag_outlined, ''),
            _NavItem(Icons.person_outline, ''),
            _NavItem(Icons.logout, 'Salir'),
          ]
        : [
            _NavItem(Icons.home, ''),
            _NavItem(Icons.receipt_long_outlined, ''),
            _NavItem(Icons.person_outline, ''),
            _NavItem(Icons.logout, 'Salir'),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.pink.shade100.withOpacity(0.3),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade100.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: BottomNavigationBar(
        currentIndex: currentIndex.clamp(
          0,
          navItems.length - 2,
        ), // ✅ seguridad extra
        onTap: (index) {
          final isSalir = index == navItems.length - 1;

          if (isSalir) {
            _confirmarCerrarSesion(context);
          } else if (index != currentIndex) {
            onTap(index);
          }
        },
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: List.generate(navItems.length, (i) {
          final isSelected = i == currentIndex;
          final item = navItems[i];

          return BottomNavigationBarItem(
            label: '',
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.pinkAccent.withOpacity(0.9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isSelected ? Colors.white : Colors.grey[500],
                  ),
                  if (isSelected) const SizedBox(width: 6),
                  if (isSelected)
                    Flexible(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro de que deseas salir?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Salir"),
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              if (onLogout != null) {
                onLogout!(); // 👈 Ejecuta la lógica de logout sin cambiar currentIndex
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem(this.icon, this.label);
}
