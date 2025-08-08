import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart'; // Necesario para background handler
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 Para filtrar al emisor

/// Configura FCM para:
/// - Pedir permisos
/// - Manejar aperturas de notificación (segundo plano / app terminada)
/// - Registrar handler de background
Future<void> setupFCM(FlutterLocalNotificationsPlugin fln) async {
  final messaging = FirebaseMessaging.instance;

  // ✅ Solicita permisos para notificaciones (iOS / Android 13+ se respeta)
  await messaging.requestPermission();

  // ✅ Registrar handler para mensajes en segundo plano (obligatorio antes de cualquier listener)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Si la notificación abrió la app desde "terminada" (killed)
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('getInitialMessage -> data: ${initialMessage.data}');
    await _handleNotificationTap(initialMessage);
  }

  // ✅ Cuando el usuario TOCA la notificación y la app pasa a primer plano (estaba en 2º plano)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print('onMessageOpenedApp -> data: ${message.data}');
    await _handleNotificationTap(message);
  });

  // ⚠️ Importante:
  // NO mostramos banner aquí en onMessage (foreground) para NO duplicar,
  // porque ya lo estás manejando en main.dart con flutterLocalNotificationsPlugin.show(...)
  // Si algún día quieres mover esa lógica aquí, avísame y lo centralizamos en un solo lugar.
}

/// ✅ Lógica común cuando el usuario toca la notificación
/// - Filtra emisor
/// - Abre Google Maps si viene mapUrl
Future<void> _handleNotificationTap(RemoteMessage message) async {
  final data = message.data;

  // Filtrar al emisor (si el UID actual coincide con emisorId, no hacemos nada)
  final emisorId = data['emisorId'];
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (emisorId != null && currentUid != null && emisorId == currentUid) {
    // Es el dispositivo que envió la alerta: no abrimos nada.
    return;
  }

  // Si viene un link de mapa, lo abrimos en Google Maps
  final mapUrl = data['mapUrl'];
  if (mapUrl != null && mapUrl is String && mapUrl.isNotEmpty) {
    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ✅ Handler para mensajes en segundo plano (Android/iOS)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Requerido para acceder a Firebase en background
  // Aquí puedes manejar datos del mensaje si necesitas (logging, etc.)
  // print('📩 Mensaje en segundo plano: ${message.messageId}');
}
