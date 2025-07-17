import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// ✅ Listener modular para alarma comunitaria
Future<void> iniciarAlarmaListener(BuildContext context) async {
  final usuario = FirebaseAuth.instance.currentUser;
  final AudioPlayer player = AudioPlayer();

  if (usuario == null) return;

  // Obtener comunidad (usando el campo dirección como identificador comunitario)
  final userDoc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(usuario.uid)
      .get();

  final data = userDoc.data();
  if (data == null || !data.containsKey('direccion')) return;

  final comunidad = data['direccion'];

  // Escuchar cambios en el documento específico de esa comunidad
  FirebaseFirestore.instance
      .collection('alarmas_activas')
      .doc(comunidad)
      .snapshots()
      .listen((doc) async {
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      final bool activa = data['activa'] ?? false;

      if (activa) {
        // ✅ Reproducir sonido de alarma
        await player.play(
          AssetSource('sounds/alarma_vecinal_chat_ready.mp3'),
        );

        // ✅ Mostrar alerta visual
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🚨 ¡Alarma activada en tu comunidad!'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  });
}
