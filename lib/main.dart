import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// 🖼️ Pantallas del proyecto
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/check_auth_screen.dart'; // ✅ Verificación de sesión

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // ✅ Inicializa Firebase

  // ⛑️ Activar App Check con modo de depuración
  await FirebaseAppCheck.instance.activate(
    //webRecaptchaSiteKey: 'recaptcha-v3-site-key', // solo web, puedes ignorarlo
    androidProvider: AndroidProvider.debug,
  );

  runApp(const MiVecinoApp());
}

class MiVecinoApp extends StatelessWidget {
  const MiVecinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Vecino',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // 🔁 Ruta inicial
      routes: {
        '/': (context) => const CheckAuthScreen(), // 🔍 Revisa si ya inició sesión
        '/login': (context) => const LoginScreen(), // 🔐 Pantalla de login
        '/register': (context) => const RegisterScreen(), // 📝 Registro
        '/home': (context) => const HomeScreen(), // 🏠 Pantalla principal
      },
    );
  }
}
