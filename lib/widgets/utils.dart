import 'package:flutter/material.dart';

void mostrarAlerta({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  bool esError = false,
}) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        titulo,
        style: TextStyle(
          color: esError ? Colors.red : Colors.pink,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

void mostrarSnackBar(BuildContext context, String mensaje) {
  // Verifica si el contexto todavía está montado
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (messenger == null || !messenger.mounted) return;

  // Usamos addPostFrameCallback para evitar conflictos con el ciclo de vida del widget
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null && scaffoldMessenger.mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(mensaje),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.pinkAccent,
        ),
      );
    }
  });
}
