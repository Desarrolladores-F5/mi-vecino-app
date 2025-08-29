// lib/widgets/publicacion_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicacionWidget extends StatelessWidget {
  final String autor;
  final String mensaje;
  final String fecha;

  // Para responder
  final String? publicacionId;
  final String? autorActual;

  // Imagen adjunta
  final String? imageUrl;

  // 👇 NUEVO: likes / dislikes
  final String uidActual;                 // uid del usuario logeado (puede ser "")
  final List<String> likes;               // uids que dieron like
  final List<String> dislikes;            // uids que dieron dislike

  const PublicacionWidget({
    super.key,
    required this.autor,
    required this.mensaje,
    required this.fecha,
    this.publicacionId,
    this.autorActual,
    this.imageUrl,
    // nuevos
    required this.uidActual,
    required this.likes,
    required this.dislikes,
  });

  bool get _yaLike => uidActual.isNotEmpty && likes.contains(uidActual);
  bool get _yaDislike => uidActual.isNotEmpty && dislikes.contains(uidActual);

  Future<void> _toggleLike() async {
    if (publicacionId == null || uidActual.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('publicaciones').doc(publicacionId);

    final batch = FirebaseFirestore.instance.batch();
    if (_yaLike) {
      batch.update(ref, {'likes': FieldValue.arrayRemove([uidActual])});
    } else {
      batch.update(ref, {'likes': FieldValue.arrayUnion([uidActual])});
      if (_yaDislike) {
        batch.update(ref, {'dislikes': FieldValue.arrayRemove([uidActual])});
      }
    }
    await batch.commit();
  }

  Future<void> _toggleDislike() async {
    if (publicacionId == null || uidActual.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('publicaciones').doc(publicacionId);

    final batch = FirebaseFirestore.instance.batch();
    if (_yaDislike) {
      batch.update(ref, {'dislikes': FieldValue.arrayRemove([uidActual])});
    } else {
      batch.update(ref, {'dislikes': FieldValue.arrayUnion([uidActual])});
      if (_yaLike) {
        batch.update(ref, {'likes': FieldValue.arrayRemove([uidActual])});
      }
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: const [
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

            // 🖼️ Imagen (si viene)
            if (imageUrl != null && imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      final total = progress.expectedTotalBytes;
                      final loaded = progress.cumulativeBytesLoaded;
                      final value = total != null ? loaded / total : null;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: Colors.black.withOpacity(0.04)),
                          Center(child: CircularProgressIndicator(value: value)),
                        ],
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, size: 28),
                    ),
                  ),
                ),
              ),
            ],

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
                _Reaction(
                  active: _yaLike,
                  count: likes.length,
                  onTap: _toggleLike,
                  activeColor: Colors.green,
                  iconOn: Icons.thumb_up,
                  iconOff: Icons.thumb_up_outlined,
                ),
                const SizedBox(width: 12),
                _Reaction(
                  active: _yaDislike,
                  count: dislikes.length,
                  onTap: _toggleDislike,
                  activeColor: Colors.red,
                  iconOn: Icons.thumb_down,
                  iconOff: Icons.thumb_down_outlined,
                ),
                const Spacer(),
                TextButton(
                  onPressed: (publicacionId == null || autorActual == null)
                      ? null
                      : () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => ResponderSheet(
                              publicacionId: publicacionId!,
                              autor: autorActual!,
                            ),
                          );
                        },
                  child: const Text('Responder'),
                ),
              ],
            ),
            
            // 💬 Respuestas (si hay publicacionId)
            if (publicacionId != null) ...[
              const SizedBox(height: 6),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('publicaciones')
                    .doc(publicacionId)
                    .collection('respuestas')
                    .orderBy('fecha', descending: false)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final docs = snap.data!.docs;
                  return Column(
                    children: docs.map((d) {
                      final r = d.data() as Map<String, dynamic>;
                      final rAutor = (r['autor'] ?? '—').toString();
                      final rMsg = (r['mensaje'] ?? '').toString();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.subdirectory_arrow_right,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7FB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: text.bodyMedium?.copyWith(
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '$rAutor: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(text: rMsg),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet para escribir y enviar la respuesta
class ResponderSheet extends StatefulWidget {
  final String publicacionId;
  final String autor;

  const ResponderSheet({
    super.key,
    required this.publicacionId,
    required this.autor,
  });

  @override
  State<ResponderSheet> createState() => _ResponderSheetState();
}

class _ResponderSheetState extends State<ResponderSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _enviando = false;

  Future<void> _enviar() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) return;

    setState(() => _enviando = true);

    await FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(widget.publicacionId)
        .collection('respuestas')
        .add({
      'autor': widget.autor,
      'mensaje': msg,
      'fecha': Timestamp.now(),
    });

    if (mounted) {
      setState(() => _enviando = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: inset,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Escribe tu respuesta...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                child: _enviando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de reacción con animación “bump” en icono y contador.
/// Usa AnimatedSwitcher + ScaleTransition cuando cambia `active` o `count`.
/// Botón de reacción con bump garantizado al tap (independiente del stream).
class _Reaction extends StatefulWidget {
  final bool active;
  final int count;
  final VoidCallback onTap;
  final Color activeColor;
  final IconData iconOn;
  final IconData iconOff;

  const _Reaction({
    required this.active,
    required this.count,
    required this.onTap,
    required this.activeColor,
    required this.iconOn,
    required this.iconOff,
  });

  @override
  State<_Reaction> createState() => _ReactionState();
}

class _ReactionState extends State<_Reaction> {
  // contador local para forzar una nueva animación en cada tap
  int _pulse = 0;

  void _handleTap() {
    // 1) disparamos el bump local
    setState(() => _pulse++);
    // 2) ejecutamos la lógica real (arrayUnion/arrayRemove)
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final muted = Colors.grey.shade600;

    // Clave distinta cuando cambian: estado activo, conteo o pulso local
    final animKey = ValueKey('${widget.active}-${widget.count}-$_pulse');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _handleTap,
      child: TweenAnimationBuilder<double>(
        key: animKey,
        tween: Tween(begin: 0.85, end: 1.0),     // escala visible
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutBack,             // rebote suave
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Icon(
                widget.active ? widget.iconOn : widget.iconOff,
                size: 20,
                color: widget.active ? widget.activeColor : muted,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.count}',
                style: TextStyle(
                  color: widget.active ? widget.activeColor : muted,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
