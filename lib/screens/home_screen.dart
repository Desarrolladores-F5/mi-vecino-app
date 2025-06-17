// 📦 Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? nombre;
  String? direccion;
  String? comunidad;
  bool cargandoUsuario = true;

  // 📥 Carga los datos del usuario desde Firestore
  Future<void> cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
        if (doc.exists) {
          setState(() {
            nombre = doc.data()?['nombre'];
            direccion = doc.data()?['direccion'];
            comunidad = doc.data()?['comunidad'];
            cargandoUsuario = false;
          });
        }
      } catch (e) {
        print('❌ Error al cargar datos del usuario: $e');
        setState(() => cargandoUsuario = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario(); // 📡 Cargar info al entrar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Vecino'),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: cargandoUsuario
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¡Bienvenido!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Nombre: ${nombre ?? '---'}', style: const TextStyle(fontSize: 18)),
                  Text('Dirección: ${direccion ?? '---'}', style: const TextStyle(fontSize: 18)),
                  Text('Comunidad: ${comunidad ?? '---'}', style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),
    );
  }
}
