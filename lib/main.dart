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

// 🔔 Handler para mensajes recibidos en segundo plano / app cerrada
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Mensaje recibido en background: ${message.messageId}");
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
/// 🔔 Pide el permiso de notificaciones en Android 13+
/// (En iOS el permiso lo maneja `FirebaseMessaging.instance.requestPermission()`.)
Future<void> _ensureNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      // Opcional: abrir ajustes si el usuario lo denegó para siempre.
      // await openAppSettings();
      print('Permiso de notificaciones denegado permanentemente.');
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
      print('ℹ️ No vino mapUrl en los datos: $data');
      return;
    }
    print('✅ mapUrl recibido: $mapUrl');

    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // 👈 clave para Android
      );
      if (!ok) {
        print('⚠️ launchUrl retornó false para $mapUrl');
      }
    } else {
      print('❌ No se pudo abrir el mapa (canLaunchUrl == false)');
    }
  } catch (e, st) {
    print('❌ Error abriendo mapUrl: $e');
    print(st);
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

  // 🔔 Crea/asegura el canal de alta prioridad en Android 8+
  await _ensureAndroidNotificationChannel();

  // 🔔 Solicita permisos para notificaciones
  await FirebaseMessaging.instance.requestPermission(); // iOS / Android 13+
  await _ensureNotificationPermission(); // Android 13+

  // 🚀 Inicializa FCM (listeners para taps, background, etc.)
  await setupFCM(flutterLocalNotificationsPlugin);

  // 🔔 Muestra banner local cuando la app está en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = notification?.android;
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mi_vecino_channel', // 👈 Debe coincidir con el canal creado
            'Notificaciones de Mi Vecino',
            channelDescription: 'Canal para notificaciones importantes',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    }
  });

    // 👇 Si la app estaba terminada y fue abierta tocando la noti
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('onGetInitialMessage -> data: ${initialMessage.data}');
    await openMapIfPresent(initialMessage);
  }

  // 👇 Si la app estaba en background y el usuario tocó la noti
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print('onMessageOpenedApp -> data: ${message.data}');
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
        '/camaras': (context) => const CamarasScreen(),
        '/panic': (context) => const PanicButtonScreen(),
      },
    );
  }
}
