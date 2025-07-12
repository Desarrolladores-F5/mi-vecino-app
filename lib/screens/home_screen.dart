// Incluye: Drawer + Traducciones + Reacciones + Respuestas + Alarma Listener
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';
import 'package:mi_vecino/screens/login_screen.dart';
import 'package:mi_vecino/screens/crear_publicacion_screen.dart';
import 'package:mi_vecino/screens/acerca_app_screen.dart';
import 'package:mi_vecino/screens/sugerencias_screen.dart';
import 'package:mi_vecino/screens/idioma_screen.dart';
import 'package:mi_vecino/screens/estado_app_screen.dart';
import 'package:mi_vecino/screens/ajustes_screen.dart';
import 'package:mi_vecino/screens/alarma_screen.dart';
import 'package:mi_vecino/utils/alarma_listener.dart'; // ✅ Listener modular de alarma

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? nombre;
  String? direccion;
  String? comunidad;
  String? fotoUrl;
  bool cargandoUsuario = true;

  Map<String, bool> mostrarFormulario = {};
  Map<String, TextEditingController> controladoresRespuesta = {};

  @override
  void initState() {
    super.initState();
    cargarDatosUsuario();
    iniciarAlarmaListener(context); // ✅ Activa listener al entrar a home_screen
  }

  Future<void> cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            nombre = data?['nombre'];
            direccion = data?['direccion'];
            comunidad = data?['nombre_comunidad'];
            fotoUrl = data?['fotoPerfil'];
            cargandoUsuario = false;
          });
        }
      } catch (e) {
        setState(() => cargandoUsuario = false);
      }
    }
  }

  Future<void> confirmarCerrarSesion() async {
    final localizations = AppLocalizations.of(context);
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

  Future<void> _responderAPublicacion(String docId, String texto) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final usuario = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final nombreUsuario = usuario['nombre'] ?? 'Anónimo';

    await FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(docId)
        .collection('respuestas')
        .add({
      'texto': texto,
      'autor': nombreUsuario,
      'fecha': DateTime.now(),
    });

    controladoresRespuesta[docId]?.clear();
    setState(() {
      mostrarFormulario[docId] = false;
    });
  }

  Future<void> _toggleLike(String docId, List likes, List dislikes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance.collection('publicaciones').doc(docId);
    if (likes.contains(uid)) {
      await docRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await docRef.update({
        'likes': FieldValue.arrayUnion([uid]),
        'dislikes': FieldValue.arrayRemove([uid]),
      });
    }
  }

  Future<void> _toggleDislike(String docId, List likes, List dislikes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance.collection('publicaciones').doc(docId);
    if (dislikes.contains(uid)) {
      await docRef.update({'dislikes': FieldValue.arrayRemove([uid])});
    } else {
      await docRef.update({
        'dislikes': FieldValue.arrayUnion([uid]),
        'likes': FieldValue.arrayRemove([uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3EC6A8)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl!) : null,
                child: fotoUrl == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
              ),
              accountName: Text(nombre ?? localizations.nombre, style: const TextStyle(fontSize: 18)),
              accountEmail: Text(direccion ?? localizations.direccion),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(localizations.ajustes),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AjustesScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(localizations.idioma),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IdiomaScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(localizations.acercaDe),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcercaAppScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: Text(localizations.sugerencias),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SugerenciasScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.campaign),
              title: Text(localizations.alarmaVecinal),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmaScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: Text(localizations.estadoApp),
              subtitle: Text(localizations.estadoConectado),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EstadoAppScreen())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(localizations.cerrarSesion),
              onTap: confirmarCerrarSesion,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Mi Vecino',
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
                  Text('${localizations.hola}, ${nombre ?? '---'} 👋',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${localizations.direccion}: ${direccion ?? '---'}'),
                  Text('${localizations.comunidad}: ${comunidad ?? '---'}'),
                  const SizedBox(height: 24),
                  Text(localizations.queCompartir, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearPublicacionScreen())),
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
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Text(localizations.sinPublicaciones);

                      final publicaciones = snapshot.data!.docs;
                      return Column(
                        children: publicaciones.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _publicacionConRespuestas(
                            doc.id,
                            data['autor'] ?? localizations.desconocido,
                            data['fechaFormateada'] ?? '',
                            data['mensaje'] ?? '',
                            data['archivoUrl'],
                            data['fotoPerfil'],
                            List<String>.from(data['likes'] ?? []),
                            List<String>.from(data['dislikes'] ?? []),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _publicacionConRespuestas(String docId, String autor, String fecha, String texto, String? archivoUrl, String? fotoPerfil, List likes, List dislikes) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final yaDioLike = likes.contains(uid);
    final yaDioDislike = dislikes.contains(uid);
    final controller = controladoresRespuesta.putIfAbsent(docId, () => TextEditingController());

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0F6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundImage: fotoPerfil != null ? NetworkImage(fotoPerfil) : null,
            child: fotoPerfil == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(autor, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(fecha, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])
        ]),
        const SizedBox(height: 10),
        Text(texto),
        if (archivoUrl != null && archivoUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(archivoUrl),
            ),
          ),
        const SizedBox(height: 10),
        Row(children: [
          IconButton(icon: Icon(Icons.thumb_up, color: yaDioLike ? Colors.green : Colors.grey), onPressed: () => _toggleLike(docId, likes, dislikes)),
          Text('${likes.length}'),
          IconButton(icon: Icon(Icons.thumb_down, color: yaDioDislike ? Colors.red : Colors.grey), onPressed: () => _toggleDislike(docId, likes, dislikes)),
          Text('${dislikes.length}'),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                mostrarFormulario[docId] = !(mostrarFormulario[docId] ?? false);
              });
            },
            child: const Text('Responder'),
          )
        ]),
        if (mostrarFormulario[docId] == true)
          Column(children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Escribe tu respuesta')),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _responderAPublicacion(docId, controller.text.trim()),
              child: const Text('Enviar respuesta'),
            ),
          ]),
        const Divider(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('publicaciones').doc(docId).collection('respuestas').orderBy('fecha').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final respuestas = snapshot.data!.docs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: respuestas.map((r) {
                final d = r.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.reply, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text('${d['autor']}: ${d['texto']}')),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ]),
    );
  }
}
