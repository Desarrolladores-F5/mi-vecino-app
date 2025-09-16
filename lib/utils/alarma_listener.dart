import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _fln = FlutterLocalNotificationsPlugin();

Future<void> iniciarAlarmaListener(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snap = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(user.uid)
      .get();
  final data = snap.data();
  if (data == null) return;

  final String comunidad = (data['nombre_comunidad'] ?? '').toString().trim();
  if (comunidad.isEmpty) return;

  bool yaMostrada = false;

  FirebaseFirestore.instance
      .collection('alarmas_activas')
      .doc(comunidad)
      .snapshots()
      .listen((doc) async {
    final d = doc.data() ?? {};
    final bool activa = d['activa'] == true;
    final String desde = (d['activada_por_direccion'] ?? d['activada_por'] ?? '').toString();

    if (activa && !yaMostrada) {
      yaMostrada = true;

      // 🔔 dispara notificación local con el canal de ALARMA (suena aunque estés en otra pantalla)
      await _fln.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        '🚨 Alarma vecinal',
        desde.isNotEmpty ? 'Alarma activada desde: $desde' : 'Se activó una alarma en tu comunidad',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarma_vecinal',           // 👈 canal ya creado en main.dart
            'Alarma Vecinal',
            channelDescription: 'Notificaciones de alarma comunitaria',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            // sonido del canal (alarma_vecinal_chat_ready) ya está configurado al crear el canal,
            // no hace falta repetirlo aquí.
          ),
        ),
      );

      // (Opcional) SnackBar visual:
      if (context.mounted && desde.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 ¡Alarma desde $desde!'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    if (!activa) {
      yaMostrada = false;
    }
  });
}