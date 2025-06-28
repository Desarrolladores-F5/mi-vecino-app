// 📦 Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_vecino/screens/login_screen.dart';
import 'package:mi_vecino/screens/crear_publicacion_screen.dart';

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

  // 🔄 Cargar datos del usuario desde Firestore
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

  // 📴 Confirmar cierre de sesión con diálogo
  Future<void> confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro que deseas cerrar sesión?"),
        actions: [
          TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(context).pop(false)),
          ElevatedButton(child: const Text("Salir"), onPressed: () => Navigator.of(context).pop(true)),
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
              accountName: Text(nombre ?? 'Nombre', style: const TextStyle(fontSize: 18)),
              accountEmail: Text(direccion ?? 'Dirección'),
            ),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Ajustes'), onTap: () {}),
            ListTile(leading: const Icon(Icons.language), title: const Text('Idioma'), onTap: () {}),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('Acerca de la App'), onTap: () {}),
            ListTile(leading: const Icon(Icons.feedback_outlined), title: const Text('Sugerencias'), onTap: () {}),
            ListTile(leading: const Icon(Icons.wifi), title: const Text('Estado de la App'), subtitle: const Text("Conectado (Wi-Fi)"), onTap: () {}),
            const Divider(),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Cerrar Sesión'), onTap: confirmarCerrarSesion),
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
                  Text('Hola, ${nombre ?? '---'} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Dirección: ${direccion ?? '---'}'),
                  Text('Comunidad: ${comunidad ?? '---'}'),
                  const SizedBox(height: 24),

                  const Text('¿Qué quieres compartir?', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        children: const [
                          Icon(Icons.edit_note, color: Color(0xFF3EC6A8)),
                          SizedBox(width: 10),
                          Text('Agrega una publicación...', style: TextStyle(fontSize: 16, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Muro de publicaciones 🛎️', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // 📡 Mostrar publicaciones en tiempo real desde Firebase
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('publicaciones').orderBy('fecha', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Text('Aún no hay publicaciones.');
                      }

                      final publicaciones = snapshot.data!.docs;
                      return Column(
                        children: publicaciones.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final autor = data['autor'] ?? 'Desconocido'; // ✅ mostrar autor correcto
                          final fecha = data['fechaFormateada'] ?? '';
                          final mensaje = data['mensaje'] ?? '';
                          final archivoUrl = data['archivoUrl']; // ✅ leer la imagen

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

  // 🧱 Widget modular para mostrar publicación con texto e imagen si existe
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
              child: Image.network(archivoUrl), // ✅ renderiza la imagen desde la URL
            ),
          ]
        ],
      ),
    );
  }
}
