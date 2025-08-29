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
      backgroundColor: const Color(0xFFFFF9C4), // 👈 fondo amarillo
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
              leading: const Icon(Icons.campaign),
              title: Text(localizations.alarmaVecinal),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlarmaScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.local_phone),
              title: Text(AppLocalizations.of(context).telefonosEmergencia),
              onTap: () {Navigator.pop(context);Navigator.pushNamed(context, '/telefonos_emergencia');},
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(AppLocalizations.of(context).camarasComunitarias),
              onTap: () {Navigator.pop(context);Navigator.pushNamed(context, '/camaras');},
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Botón de Pánico'),
              onTap: () {Navigator.pop(context);Navigator.pushNamed(context, '/panic');
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: Text(localizations.sugerencias),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SugerenciasScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: Text(localizations.estadoApp),
              subtitle: Text(localizations.estadoConectado),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EstadoAppScreen())),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(localizations.acercaDe),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AcercaAppScreen())),
            ),
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
                  // ---------- CABECERA BONITA ----------
                  HomeHeaderCardPro(
                    localizations: localizations,
                    nombre: nombre ?? '---',
                    direccion: direccion ?? '---',
                    comunidad: comunidad ?? '---',
                    fotoUrl: fotoUrl,
                    onCompose: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CrearPublicacionScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(               // 👈 AQUI
                    thickness: 2,
                    height: 24,
                    indent: 8,
                    endIndent: 8,
                    color: Color(0xFFE0E0E0),
                  ),
                  _SectionDivider(
                    label: 'Muro de Publicaciones', // o localizations.muroPublicaciones
                    icon: Icons.dynamic_feed_outlined,
                  ),
                  const SizedBox(height: 8),
                  // ---------- FIN CABECERA ----------
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBDEFB), // Azul claro 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFF0B3)),
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('publicaciones')
                          .where('nombre_comunidad', isEqualTo: comunidad?.trim())
                          .orderBy('fecha', descending: true)
                          .snapshots(),
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

class _HomeHeaderCard extends StatelessWidget {
  final AppLocalizations localizations;
  final String nombre;
  final String direccion;
  final String comunidad;
  final String? fotoUrl;
  final VoidCallback onCompose;

  const _HomeHeaderCard({
    required this.localizations,
    required this.nombre,
    required this.direccion,
    required this.comunidad,
    required this.fotoUrl,
    required this.onCompose,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF), // 👈 leve tinte azulado distinto a las cards del muro
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow( // 👈 un poco más de presencia que una card normal
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Column(
        children: [
          // Franja superior para diferenciarlo del muro
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: (fotoUrl != null && fotoUrl!.isNotEmpty)
                          ? NetworkImage(fotoUrl!)
                          : null,
                      child: (fotoUrl == null || fotoUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 26, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${localizations.hola}, $nombre 👋',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(icon: Icons.home_outlined, label: '${localizations.direccion}: $direccion'),
                              _InfoChip(icon: Icons.groups_2_outlined, label: '${localizations.comunidad}: $comunidad'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ComposeButton(
                  label: localizations.agregaPublicacion,
                  onPressed: onCompose,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: const Color(0xFFF0F3FA),
      shape: const StadiumBorder(
        side: BorderSide(color: Color(0xFFE2E7F2)),
      ),
    );
  }
}

class _ComposeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _ComposeButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_comment_outlined),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionDivider({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1.2,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E8F2),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeHeaderCardPro extends StatelessWidget {
  final AppLocalizations localizations;
  final String nombre;
  final String direccion;
  final String comunidad;
  final String? fotoUrl;
  final VoidCallback onCompose;

  const HomeHeaderCardPro({
    super.key,
    required this.localizations,
    required this.nombre,
    required this.direccion,
    required this.comunidad,
    required this.fotoUrl,
    required this.onCompose,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,              // 👈 antes tenía horizontal 16
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Franja superior a todo el ancho (marca jerarquía de sección)
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          // Cuerpo de la tarjeta
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF), // 👈 lavanda muy claro (header)
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border.all(color: const Color(0xFFE6ECF7)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Columna izquierda: saludo + info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${localizations.hola}, $nombre 👋',
                            style: t.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _HeaderInfoRow(
                            icon: Icons.home_outlined,
                            text: '${localizations.direccion}: $direccion',
                          ),
                          const SizedBox(height: 4),
                          _HeaderInfoRow(
                            icon: Icons.groups_2_outlined,
                            text: '${localizations.comunidad}: $comunidad',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Avatar a la derecha
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: (fotoUrl != null && fotoUrl!.isNotEmpty)
                          ? NetworkImage(fotoUrl!)
                          : null,
                      child: (fotoUrl == null || fotoUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 28, color: Colors.grey)
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Botón centrado (ancho cómodo)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
                    child: OutlinedButton.icon(
                      onPressed: onCompose,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: Text(localizations.agregaPublicacion),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: scheme.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeaderInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

