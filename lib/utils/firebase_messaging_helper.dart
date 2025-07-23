import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Necesario para background handler

Future<void> setupFCM(FlutterLocalNotificationsPlugin fln) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Solicita permisos para notificaciones (Android 13+ requiere confirmación)
  await messaging.requestPermission();

  // ⏬ Escucha notificaciones cuando la app está en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification!.android;

      if (notification != null && android != null) {
        fln.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'canal_principal', // ID del canal
              'Notificaciones Importantes', // Nombre del canal
              channelDescription: 'Este canal se usa para alertas vecinales.',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
            ),
          ),
        );
      }
    }
  });

  // ✅ Escucha mensajes cuando la app está en segundo plano o terminada
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// ✅ Handler para mensajes en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Requerido para acceder a Firebase en background

  // Aquí puedes manejar datos del mensaje si necesitas
  print('📩 Mensaje en segundo plano: ${message.messageId}');
}
