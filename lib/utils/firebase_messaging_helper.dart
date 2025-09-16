import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart'; // Requerido en background
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Configura FCM para:
/// - Pedir permisos
/// - Manejar aperturas de notificación (tap) en background/killed
/// - Registrar handler de background
/// Nota: NO reproducimos audio aquí (lo maneja AlarmaScreen por Firestore).
Future<void> setupFCM(FlutterLocalNotificationsPlugin fln) async {
  final messaging = FirebaseMessaging.instance;

  // Permisos (iOS / Android 13+)
  await messaging.requestPermission();

  // Handler global en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Si la notificación abrió la app desde terminada
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    // print('getInitialMessage -> data: ${initialMessage.data}');
    await _handleNotificationTap(initialMessage);
  }

  // Cuando el usuario toca la notificación con la app en 2º plano
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    // print('onMessageOpenedApp -> data: ${message.data}');
    await _handleNotificationTap(message);
  });

  // ⚠️ Importante:
  // Si tienes onMessage en otro lado mostrando banners locales,
  // evita duplicarlo aquí para no mostrar dos notificaciones.
}

/// Lógica común cuando el usuario toca la notificación
/// - Filtra remitente (para no abrir en el dispositivo emisor)
/// - Abre Google Maps si viene 'mapUrl'
Future<void> _handleNotificationTap(RemoteMessage message) async {
  final data = message.data;

  // No hacer nada si el emisor es el mismo usuario
  final emisorId = data['emisorId'];
  final currentUid = FirebaseAuth.instance.currentUser?.uid;
  if (emisorId != null && currentUid != null && emisorId == currentUid) {
    return;
  }

  // Abrir mapas si corresponde
  final mapUrl = data['mapUrl'];
  if (mapUrl != null && mapUrl is String && mapUrl.isNotEmpty) {
    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Si quieres navegar a una pantalla según 'route': data['route']...
}

// Handler en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Log opcional:
  // print('📩 Background message: ${message.messageId}');
}

/// (Opcional) Limpia suscripciones antiguas de topics de alarma para evitar sonidos fantasma.
/// Llama una vez al iniciar (main o Home).
Future<void> unsubscribeLegacyAlarmTopics() async {
  final fcm = FirebaseMessaging.instance;
  // Agrega aquí los topics que usaste en pruebas:
  await fcm.unsubscribeFromTopic('alarma_global');
  await fcm.unsubscribeFromTopic('alarma_casa_k8');
  await fcm.unsubscribeFromTopic('alarma_casa_k9');
  // ...cualquier otro que recuerdes.
}
