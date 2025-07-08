import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';
import 'package:mi_vecino/screens/login_screen.dart';
import 'package:mi_vecino/screens/crear_publicacion_screen.dart';
import 'package:mi_vecino/screens/acerca_app_screen.dart';
import 'package:mi_vecino/screens/sugerencias_screen.dart';
import 'package:mi_vecino/screens/idioma_screen.dart';

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

  Future<void> cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
        if (doc.exists) {
          setState(() {
            nombre = doc.data()?['nombre'];
            direccion = doc.data()?['direccion'];
            comunidad = doc.data()?['nombre_comunidad'];
            cargandoUsuario = false;
          });
        }
      } catch (e) {
        print('❌ Error al cargar datos del usuario: $e');
        setState(() => cargandoUsuario = false);
      }
    }
  }

  Future<void> confirmarCerrarSesion() async {
    final localizations = AppLocalizations.of(context)!;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.cerrarSesion),
        content: Text(localizations.seguroCerrarSesion),
        actions: [
          TextButton(child: Text(localizations.cancelar), onPressed: () => Navigator.of(context).pop(false)),
          ElevatedButton(child: Text(localizations.salir), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3EC6A8)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              accountName: Text(nombre ?? localizations.nombre, style: const TextStyle(fontSize: 18)),
              accountEmail: Text(direccion ?? localizations.direccion),
            ),
            ListTile(leading: const Icon(Icons.settings), title: Text(localizations.ajustes), onTap: () {}),
            ListTile(leading: const Icon(Icons.language), title: Text(localizations.idioma), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IdiomaScreen()));
            }),
            ListTile(leading: const Icon(Icons.info_outline), title: Text(localizations.acercaDe), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AcercaAppScreen()));
            }),
            ListTile(leading: const Icon(Icons.feedback_outlined), title: Text(localizations.sugerencias), onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SugerenciasScreen()));
            }),
            ListTile(leading: const Icon(Icons.wifi), title: Text(localizations.estadoApp), subtitle: Text(localizations.estadoConectado), onTap: () {}),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout), title: Text(localizations.cerrarSesion), onTap: confirmarCerrarSesion),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Mi Vecino',
          style: TextStyle(
            fontFamily: 'MiVecinoFont',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: cargandoUsuario
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${localizations.hola}, ${nombre ?? '---'} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${localizations.direccion}: ${direccion ?? '---'}'),
                  Text('${localizations.comunidad}: ${comunidad ?? '---'}'),
                  const SizedBox(height: 24),

                  Text(localizations.queCompartir, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CrearPublicacionScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7F1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3EC6A8), width: 1.2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, color: Color(0xFF3EC6A8)),
                          const SizedBox(width: 10),
                          Text(localizations.agregaPublicacion, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(localizations.muroPublicaciones, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('publicaciones').orderBy('fecha', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text(localizations.sinPublicaciones);
                      }

                      final publicaciones = snapshot.data!.docs;
                      return Column(
                        children: publicaciones.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final autor = data['autor'] ?? localizations.desconocido;
                          final fecha = data['fechaFormateada'] ?? '';
                          final mensaje = data['mensaje'] ?? '';
                          final archivoUrl = data['archivoUrl'];

                          return _publicacionUsuario(autor, fecha, mensaje, archivoUrl);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _publicacionUsuario(String autor, String fecha, String texto, String? archivoUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0F6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(autor, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (fecha.isNotEmpty) Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(texto),
          if (archivoUrl != null && archivoUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(archivoUrl),
            ),
          ]
        ],
      ),
    );
  }
}
