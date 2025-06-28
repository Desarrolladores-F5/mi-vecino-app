// lib/widgets/publicacion_widget.dart
import 'package:flutter/material.dart';

class PublicacionWidget extends StatelessWidget {
  final String autor;
  final String mensaje;
  final String fecha;

  const PublicacionWidget({
    super.key,
    required this.autor,
    required this.mensaje,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(autor, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(fecha, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(mensaje),
        ],
      ),
    );
  }
}
