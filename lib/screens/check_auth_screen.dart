import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  // ✅ Método para verificar si hay usuario activo
  void checkLoginStatus() async {
    // ⏱️ Simulamos carga por 1 segundo
    await Future.delayed(const Duration(seconds: 1));
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 🔐 Usuario logueado → ir al Home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // 👤 No logueado → ir al Login
      Navigator.pushReplacementNamed(context, '/login'); // ✅ CAMBIO AQUÍ
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus(); // ✅ Ejecutamos al iniciar
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // ⏳ Animación de carga
      ),
    );
  }
}
