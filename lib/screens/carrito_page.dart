import 'package:flutter/material.dart';
import 'package:creartnino/pages/cliente/formulario_pedido_page.dart';
import '../models/producto.dart';
import 'package:intl/intl.dart';

class CarritoPage extends StatefulWidget {
  final Map<Producto, int> carrito;

  const CarritoPage({Key? key, required this.carrito}) : super(key: key);

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final Map<Producto, String> personalizaciones = {};

  void mostrarPersonalizar(BuildContext context, Producto producto) {
    final controller = TextEditingController(
      text: personalizaciones[producto] ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF0F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎨 Personalización'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe tu personalización aquí...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                personalizaciones[producto] = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String formatCOP(num value) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: 'COP ',
      decimalDigits: 0, // 🔹 Sin decimales
    );
    return formatter.format(value);
  }

  void aumentarCantidad(Producto producto) {
    setState(() {
      final actual = widget.carrito[producto] ?? 1;

      if (actual < producto.cantidad) {
        widget.carrito[producto] = actual + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solo hay ${producto.cantidad} unidades disponibles de ${producto.nombre}.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.pinkAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void disminuirCantidad(Producto producto) {
    setState(() {
      final actual = widget.carrito[producto] ?? 1;
      if (actual > 1) {
        widget.carrito[producto] = actual - 1;
      }
    });
  }

  void eliminarProductoConfirmado(Producto producto) {
    setState(() {
      widget.carrito.remove(producto);
      personalizaciones.remove(producto);
    });
  }

  void confirmarEliminarProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('❗ Eliminar producto'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${producto.nombre}" del carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              eliminarProductoConfirmado(producto);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade300,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void vaciarCarrito() {
    setState(() {
      widget.carrito.clear();
      personalizaciones.clear();
    });
  }

  double calcularTotalGeneral() {
    return widget.carrito.entries.fold(
      0,
      (sum, e) => sum + (e.key.precio * e.value),
    );
  }

  String generarDescripcionPedido() {
    List<String> descripciones = [];
    widget.carrito.forEach((producto, cantidad) {
      final tipo = personalizaciones[producto]?.isNotEmpty == true
          ? 'Personalizado'
          : 'Prediseñado';
      descripciones.add("$cantidad x ${producto.nombre} ($tipo)");
    });
    return descripciones.join(", ");
  }

  void confirmarPedido() {
    // 🔹 Validar antes de continuar
    bool hayError = false;
    String mensajeError = '';

    widget.carrito.forEach((producto, cantidad) {
      if (cantidad <= 0) {
        hayError = true;
        mensajeError = 'La cantidad de ${producto.nombre} no puede ser 0.';
      } else if (cantidad > producto.cantidad) {
        hayError = true;
        mensajeError =
            'No hay suficiente stock de ${producto.nombre}. Solo quedan ${producto.cantidad}.';
      }
    });

    if (hayError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensajeError,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      return; // 🔸 Evita continuar con el pedido
    }

    // ✅ Si todo está bien, procede con el pedido
    final descripcion = generarDescripcionPedido();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioPedidoPage(
          descripcionGenerada: descripcion,
          totalGenerado: calcularTotalGeneral(),
          carrito: widget.carrito,
          personalizaciones: personalizaciones,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Carrito'),
        backgroundColor: Colors.pinkAccent.shade100,
        actions: [
          IconButton(
            onPressed: vaciarCarrito,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Vaciar carrito',
          ),
        ],
      ),
      body: widget.carrito.isEmpty
          ? const Center(child: Text('El carrito está vacío.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.carrito.length,
                    itemBuilder: (_, index) {
                      final producto = widget.carrito.keys.elementAt(index);
                      final cantidad = widget.carrito[producto]!;
                      final subtotal = producto.precio * cantidad;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: const Color(0xFFFFF0F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                producto.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text("💵 Precio: ${formatCOP(producto.precio)}"),

                              Text("🔢 Cantidad: $cantidad"),
                              Text("💰 Subtotal: ${formatCOP(subtotal)}"),
                              if ((personalizaciones[producto] ?? '')
                                  .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    "🎨 Personalización: ${personalizaciones[producto]}",
                                    style: const TextStyle(
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      pastelIconButton(
                                        icon: Icons.remove,
                                        color: Colors.orange,
                                        onPressed: () =>
                                            disminuirCantidad(producto),
                                      ),
                                      const SizedBox(width: 8),
                                      pastelIconButton(
                                        icon: Icons.add,
                                        color: Colors.green,
                                        onPressed: () =>
                                            aumentarCantidad(producto),
                                      ),
                                      const SizedBox(width: 8),
                                      pastelIconButton(
                                        icon: Icons.brush,
                                        color: Colors.purple,
                                        onPressed: () => mostrarPersonalizar(
                                          context,
                                          producto,
                                        ),
                                      ),
                                    ],
                                  ),
                                  pastelIconButton(
                                    icon: Icons.delete,
                                    color: Colors.red,
                                    onPressed: () =>
                                        confirmarEliminarProducto(producto),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🧾 Total: \$${calcularTotalGeneral().toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: confirmarPedido,
                        icon: const Icon(Icons.check),
                        label: const Text('Confirmar Pedido'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8BBD0),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

Widget pastelIconButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color color = Colors.pinkAccent,
}) {
  return Container(
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onPressed,
      splashRadius: 22,
    ),
  );
}
