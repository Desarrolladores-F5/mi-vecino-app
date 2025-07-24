import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart'; // 🌐 Traducciones generadas
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'utils/firebase_messaging_helper.dart'; // ✅ Ayuda a manejar notificaciones FCM
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ Notificaciones locales

// 📱 Pantallas de la app
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/check_auth_screen.dart';
import 'screens/idioma_screen.dart'; // 🌍 Pantalla para cambiar idioma
import 'screens/telefonos_emergencia_screen.dart'; // Agrega el import

// 🔑 Clave global para acceder al estado de la app y cambiar idioma
final GlobalKey<_MiVecinoAppState> appKey = GlobalKey<_MiVecinoAppState>();

// ✅ Canal de notificaciones (necesario para Android)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🧱 Asegura que Flutter esté listo

  // 🔥 Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🛡️ Activa App Check (modo debug por ahora, al publicar cambiar por androidProvider: AndroidProvider.playIntegrity,)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // 📩 Inicializa notificaciones locales
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // 🔔 Ícono de la notificación

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // 🚀 Inicializa Firebase Messaging y escucha mensajes
  await setupFCM(flutterLocalNotificationsPlugin);

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

      locale: _locale, // 🌐 Idioma actual
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
      },
    );
  }
}
