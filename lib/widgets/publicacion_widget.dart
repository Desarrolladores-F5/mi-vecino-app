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
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // más redondeado
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: const [
          // sombra suave “premium”
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Autor + fecha
            Text(
              autor,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fecha,
              style: text.bodySmall?.copyWith(
                color: muted,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 10),

            // Mensaje
            Text(
              mensaje,
              style: text.bodyMedium?.copyWith(height: 1.25),
            ),

            // (si más adelante agregas imagen/contenido, va aquí)

            // Separador sutil
            const SizedBox(height: 12),
            Container(
              height: 1,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 6),

            // Footer con acciones
            Row(
              children: [
                Icon(Icons.thumb_up_outlined, size: 18, color: muted),
                const SizedBox(width: 16),
                Icon(Icons.thumb_down_outlined, size: 18, color: muted),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // TODO: conectar acción de responder
                  },
                  child: const Text('Responder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
