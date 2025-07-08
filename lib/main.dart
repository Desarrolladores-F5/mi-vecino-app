import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart'; // 🌐 Traducciones generadas

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// 📱 Pantallas de la app
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/check_auth_screen.dart';
import 'screens/idioma_screen.dart'; // 🌍 Pantalla para cambiar idioma

// 🔑 Clave global para acceder al estado de la app y cambiar idioma
final GlobalKey<_MiVecinoAppState> appKey = GlobalKey<_MiVecinoAppState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 🧱 Asegura que Flutter esté listo

  // 🔥 Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🛡️ Habilita App Check (modo debug por ahora)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

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
      localizationsDelegates: const [ // 📚 Delegados de traducción
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [ // 🌎 Idiomas disponibles
        Locale('es'),
        Locale('en'),
      ],

      // 🧠 Selección automática del idioma si no hay uno forzado
      localeResolutionCallback: (locale, supportedLocales) {
        if (_locale != null) return _locale; // ✅ Si hay idioma forzado, úsalo
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // Por defecto: español
      },

      // 🧭 Rutas de navegación
      initialRoute: '/',
      routes: {
        '/': (context) => const CheckAuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/idioma': (context) => const IdiomaScreen(),
      },
    );
  }
}
