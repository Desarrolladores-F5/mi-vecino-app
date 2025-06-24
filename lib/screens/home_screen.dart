import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_vecino/screens/login_screen.dart'; // Ajusta si cambia la ruta

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

  // 🔄 Carga los datos del usuario desde Firestore
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

  // 🔒 Diálogo para confirmar cierre de sesión
  Future<void> confirmarCerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro que deseas cerrar sesión?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            child: const Text("Salir"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
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
      // 📦 Menú lateral personalizado
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 🧍 Encabezado con nombre y dirección
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3EC6A8)),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              accountName: Text(nombre ?? 'Nombre', style: const TextStyle(fontSize: 18)),
              accountEmail: Text(direccion ?? 'Dirección'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              onTap: () {}, // 🛠 Acción futura
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Idioma'),
              onTap: () {}, // 🌐 Acción futura
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de la App'),
              onTap: () {}, // ℹ️ Acción futura
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Sugerencias o Feedback'),
              onTap: () {}, // 📬 Acción futura
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('Estado de la App'),
              subtitle: const Text("Conectado (Wi-Fi)"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: confirmarCerrarSesion,
            ),
          ],
        ),
      ),
      // 🟩 AppBar con fuente personalizada
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
      // 👤 Cuerpo principal
      body: cargandoUsuario
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👋 Bienvenida personalizada
                  Text(
                    'Hola, ${nombre ?? '---'} 👋',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('Dirección: ${direccion ?? '---'}'),
                  Text('Comunidad: ${comunidad ?? '---'}'),
                  const SizedBox(height: 24),

                  // 📝 Campo de publicación (diseño simple)
                  const Text('¿Qué quieres compartir?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Escribe algo...',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🧱 Muro de publicaciones (simulado por ahora)
                  const Text('Muro de publicaciones 🛎️', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _publicacionUsuario('Pamela', '7 junio 2025', 'Saludos, soy nueva!!'),
                  _publicacionUsuario('Ximena', '7 junio 2025', '¿Alguien tiene una llave inglesa???'),
                ],
              ),
            ),
    );
  }

  // 🧱 Widget de publicación individual
  Widget _publicacionUsuario(String autor, String fecha, String texto) {
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
          Text(fecha, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(texto),
        ],
      ),
    );
  }
}
