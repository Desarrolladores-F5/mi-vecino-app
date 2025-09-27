import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart'; // 🌐 Traducciones generadas
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'utils/firebase_messaging_helper.dart'; // ✅ Ayuda a manejar notificaciones FCM
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ Notificaciones locales
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔔 FCM directo
import 'dart:io'; // 🔔 Detectar plataforma
import 'package:permission_handler/permission_handler.dart'; // 🔔 Pedir permiso Android 13+
import 'package:url_launcher/url_launcher.dart'; // ✅ Abrir URLs externas (Maps/Navegador)
import 'package:mi_vecino/core/topic_subscription.dart';
import 'package:flutter/foundation.dart'; // para kDebugMode y debugPrint

// 📱 Pantallas de la app
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/check_auth_screen.dart';
import 'screens/idioma_screen.dart'; // 🌍 Pantalla para cambiar idioma
import 'screens/telefonos_emergencia_screen.dart';
import 'screens/camaras_screen.dart';
import 'screens/panic_button_screen.dart';

// 🔑 Clave global para acceder al estado de la app y cambiar idioma
final GlobalKey<_MiVecinoAppState> appKey = GlobalKey<_MiVecinoAppState>();

// ✅ Plugin de notificaciones locales (Android/iOS)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    const String kPanicChannelId = 'mi_vecino_panic_channel';

// 🔔 Handler para mensajes recibidos en segundo plano / app cerrada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    debugPrint("Mensaje recibido en background: ${message.messageId}");
  }  
}

/// 🔔 Crea/asegura un canal de notificaciones de alta prioridad en Android 8+
///    (ayuda a que suenen/vibren las alertas importantes).
Future<void> _ensureAndroidNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'mi_vecino_channel', // Debe coincidir con el channelId usado al mostrar
    'Notificaciones de Mi Vecino',
    description: 'Canal para notificaciones importantes',
    importance: Importance.max,
    playSound: true,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
  }
}

/// 🔔 Canal específico para la ALARMA (sonido custom en notificación del sistema)
Future<void> _ensureAlarmNotificationChannel() async {
  const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
    'alarma_vecinal', // 👈 debe coincidir con channelId en tu Cloud Function
    'Alarma Vecinal',
    description: 'Notificaciones de alarma comunitaria',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarma_vecinal_chat_ready'),
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(alarmChannel);
  }
  
}

/// 🔔 Canal específico para el BOTÓN DE PÁNICO (sonido custom)
Future<void> _ensurePanicNotificationChannel() async {
  const AndroidNotificationChannel panicChannel = AndroidNotificationChannel(
    kPanicChannelId, // 👈 debe coincidir con channelId en tu Cloud Function
    'Alertas de Pánico',
    description: 'Notificaciones del botón de pánico',
    importance: Importance.max,
    playSound: true,
    // res/raw/panic_alert.mp3  (nombre sin extensión)
    sound: RawResourceAndroidNotificationSound('panic_alert'),
    enableVibration: true,
    showBadge: true,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(panicChannel);
  }
}

/// 🔔 Pide el permiso de notificaciones en Android 13+
/// (En iOS el permiso lo maneja `FirebaseMessaging.instance.requestPermission()`.)
Future<void> _ensureNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      // Opcional: abrir ajustes si el usuario lo denegó para siempre.
      // await openAppSettings();
      if (kDebugMode) {
        debugPrint('Permiso de notificaciones denegado permanentemente.');
      }
    }
  }
}
/// 🗺️ Intenta abrir el mapa si viene `mapUrl` en los datos de la notificación.
///    Usa modo externo para forzar Google Maps o el navegador.
Future<void> openMapIfPresent(RemoteMessage message) async {
  try {
    final data = message.data;
    final String? mapUrl = data['mapUrl'] as String?;
    if (mapUrl == null || mapUrl.trim().isEmpty) {
      if (kDebugMode) debugPrint('ℹ️ No vino mapUrl en los datos: $data');
      return;
    }
    if (kDebugMode) debugPrint('✅ mapUrl recibido: $mapUrl');

    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // 👈 clave para Android
      );
      if (!ok && kDebugMode) {
        debugPrint('⚠️ launchUrl retornó false para $mapUrl');
      }
    } else {
      if (kDebugMode) debugPrint('❌ No se pudo abrir el mapa (canLaunchUrl == false)');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('❌ Error abriendo mapUrl: $e');
      debugPrint(st.toString());
    }
  }
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🧱 Asegura que Flutter esté listo

  // 🔥 Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🛡️ Activa App Check (modo debug por ahora)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // 🔔 Registra el handler de background antes de cualquier listener
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 📩 Inicializa notificaciones locales (icono por defecto del app)
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
   
  // 🔔 Crea/asegura el canal de alta prioridad (general)
  await _ensureAndroidNotificationChannel();

  // 🔔 Crea/asegura el canal ESPECÍFICO de ALARMA (sonido custom en background)
  await _ensureAlarmNotificationChannel();

  // botón de pánico (sonido discreto)
  await _ensurePanicNotificationChannel();

  // 🔔 Solicita permisos para notificaciones
  await FirebaseMessaging.instance.requestPermission(); // iOS / Android 13+
  await _ensureNotificationPermission(); // Android 13+

  // 🚀 Inicializa FCM (listeners para taps, background, etc.)
  await setupFCM(flutterLocalNotificationsPlugin);

   // 🔔 Muestra banner local cuando la app está en primer plano
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final RemoteNotification? notification = message.notification;
  final AndroidNotification? android = notification?.android;
  if (notification == null || android == null) return;

  // Lee 'type' o 'tipo' desde los datos
  final String tipo = (message.data['type'] ?? message.data['tipo'] ?? '').toString();
  final bool isAlarm = tipo == 'alarm';

  flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails( // 👈 sin const
      android: AndroidNotificationDetails(
        isAlarm ? 'alarma_vecinal' : 'mi_vecino_channel', // canal según tipo
        isAlarm ? 'Alarma Vecinal' : 'Notificaciones de Mi Vecino',
        channelDescription: isAlarm
            ? 'Notificaciones de alarma comunitaria'
            : 'Canal para notificaciones importantes',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        // si quieres replicar el sonido de alarma también en foreground:
        sound: isAlarm
            ? RawResourceAndroidNotificationSound('alarma_vecinal_chat_ready')
            : null,
      ),
    ),
  );
});


    // 👇 Si la app estaba terminada y fue abierta tocando la noti
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    if (kDebugMode) debugPrint('onGetInitialMessage -> data: ${initialMessage.data}');
    await openMapIfPresent(initialMessage);
  }

  // 👇 Si la app estaba en background y el usuario tocó la noti
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    if (kDebugMode) debugPrint('onMessageOpenedApp -> data: ${message.data}');
    await openMapIfPresent(message);
  });

  await TopicSubscription.subscribeFromLocalPrefs();

  // 🚀 Lanza la aplicación con clave global
  runApp(MiVecinoApp(key: appKey));
}

// 🧠 StatefulWidget que nos permite cambiar el idioma dinámicamente
class MiVecinoApp extends StatefulWidget {
  const MiVecinoApp({super.key});

  @override
  State<MiVecinoApp> createState() => _MiVecinoAppState();
}

class _MiVecinoAppState extends State<MiVecinoApp> {
  Locale? _locale; // 🌍 Idioma actual

  // 📦 Permite cambiar el idioma desde cualquier parte usando appKey.currentState!.setLocale(...)
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Vecino',
      debugShowCheckedModeBanner: false,

      // 🎨 Tema base de la app
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (_locale != null) return _locale;
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },

      // 🧭 Rutas de navegación
      initialRoute: '/',
      routes: {
        '/': (context) => const CheckAuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/idioma': (context) => const IdiomaScreen(),
        '/telefonos_emergencia': (context) =>
            const TelefonosEmergenciaScreen(),
        '/camaras': (context) {
          final nombreComunidad =
              ModalRoute.of(context)!.settings.arguments as String?;
          return CamarasScreen(nombreComunidad: nombreComunidad);
        },
        '/panic': (context) => const PanicButtonScreen(),
      },
    );
  }
}
