import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SugerenciasScreen extends StatefulWidget {
  const SugerenciasScreen({super.key});

  @override
  State<SugerenciasScreen> createState() => _SugerenciasScreenState();
}

class _SugerenciasScreenState extends State<SugerenciasScreen> {
  final TextEditingController _sugerenciaController = TextEditingController();
  bool _enviando = false;

  // ✅ Enviar sugerencia a Firestore
  Future<void> enviarSugerencia() async {
    final mensaje = _sugerenciaController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (mensaje.isEmpty || uid == null) return;

    setState(() => _enviando = true);

    try {
      await FirebaseFirestore.instance.collection('sugerencias').add({
        'uid': uid,
        'mensaje': mensaje,
        'fecha': DateTime.now(),
      });

      _sugerenciaController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Sugerencia enviada')),
        );
      }
    } catch (e) {
      print('❌ Error al enviar sugerencia: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Hubo un error. Intenta más tarde')),
        );
      }
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerencias'),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Tienes una sugerencia o idea para mejorar la app?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sugerenciaController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Escribe tu sugerencia aquí...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _enviando ? null : enviarSugerencia,
              icon: const Icon(Icons.send),
              label: const Text('Enviar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3EC6A8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
