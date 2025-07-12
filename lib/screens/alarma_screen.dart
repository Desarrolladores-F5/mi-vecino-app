import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // ✅ Importamos audioplayers

class AlarmaScreen extends StatelessWidget {
  const AlarmaScreen({super.key});

  // ✅ Función para reproducir el sonido de la alarma
  Future<void> reproducirAlarma() async {
    final player = AudioPlayer();
    await player.play(AssetSource('sounds/alarma_vecinal_chat_ready.mp3'));
  }

  // ✅ Función para activar la alarma en Firestore y reproducir el sonido
  Future<void> activarAlarma(BuildContext context) async {
    final usuario = FirebaseAuth.instance.currentUser;

    // ⚠️ Verificamos si el usuario está autenticado
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario no autenticado.')),
      );
      return;
    }

    // ✅ Obtenemos los datos del usuario desde Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(usuario.uid)
        .get();

    final datos = userDoc.data();

    // ⚠️ Verificamos si el documento tiene la dirección asociada
    if (datos == null || !datos.containsKey('direccion')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se ha definido la comunidad del usuario.')),
      );
      return;
    }

    final comunidad = datos['direccion'];

    // ✅ Guardamos en la colección "alarmas_activas" el estado de alarma
    await FirebaseFirestore.instance
        .collection('alarmas_activas')
        .doc(comunidad)
        .set({
      'activa': true,
      'hora': Timestamp.now(),
      'activada_por': usuario.displayName ?? usuario.email ?? 'Desconocido',
    });

    // ✅ Reproducimos el sonido de la alarma
    await reproducirAlarma();

    // ✅ Mostramos mensaje de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🚨 Alarma activada para $comunidad')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alarma Vecinal'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => activarAlarma(context),
          icon: Icon(Icons.warning, size: 36),
          label: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '🚨 ACTIVAR ALARMA VECINAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}
