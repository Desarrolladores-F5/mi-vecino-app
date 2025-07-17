import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

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

  // 🛑 También puedes manejar mensajes en segundo plano si quieres:
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

// (Opcional) Si quieres usar mensajes en segundo plano, define esta función:
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   // Puedes manejar datos aquí
// }
