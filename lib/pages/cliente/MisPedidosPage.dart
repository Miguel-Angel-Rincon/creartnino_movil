import 'package:creartnino/pages/cliente/PedidosPageCliente.dart';
import 'package:flutter/material.dart';

class MisPedidosPage extends StatelessWidget {
  final String numDocumento;

  const MisPedidosPage({super.key, required this.numDocumento});

  @override
  Widget build(BuildContext context) {
    return PedidosPageCliente(numDocumentoUsuario: numDocumento);
  }
}
