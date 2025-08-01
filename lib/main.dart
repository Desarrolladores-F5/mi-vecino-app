import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart'; // 🌐 Traducciones generadas
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'utils/firebase_messaging_helper.dart'; // ✅ Ayuda a manejar notificaciones FCM
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ Notificaciones locales
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔔 NUEVO: FCM directo

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

// ✅ Canal de notificaciones (necesario para Android)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔔 NUEVO: Handler para mensajes en segundo plano/cerrada
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Mensaje recibido en background: ${message.messageId}");
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

  // 🔔 NUEVO: Configura handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 📩 Inicializa notificaciones locales
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 🚀 Inicializa Firebase Messaging y escucha mensajes (helper existente)
  await setupFCM(flutterLocalNotificationsPlugin);

  // 🔔 NUEVO: Solicita permiso para notificaciones (Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // 🔔 NUEVO: Listener para mostrar notificaciones cuando app está abierta
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
            'mi_vecino_channel',
            'Notificaciones de Mi Vecino',
            channelDescription: 'Canal para notificaciones importantes',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

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
        '/telefonos_emergencia': (context) => const TelefonosEmergenciaScreen(),
        '/camaras': (context) => const CamarasScreen(),
        '/panic': (context) => const PanicButtonScreen(),
      },
    );
  }
}
