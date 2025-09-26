import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _nombreController = TextEditingController();

  bool notificacionesActivadas = false;
  bool _cargando = false;

  File? _imagen;                 // Imagen elegida localmente (previa a subir)
  String? _urlFotoPerfil;        // URL base guardada en Firestore (sin bust)
  int? _bustTsMs;                // Timestamp (ms) para bustear cache de NetworkImage

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  /// Carga nombre, fotoPerfil y preferencias desde Firestore
  Future<void> _cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final data = doc.data();
    if (data == null) return;

    _nombreController.text = (data['nombre'] ?? '') as String;
    _urlFotoPerfil = data['fotoPerfil'] as String?;
    notificacionesActivadas = (data['notificaciones'] ?? false) as bool;

    // Si existe photoUpdatedAt, úsalo para bustear cache
    final ts = data['photoUpdatedAt'];
    if (ts is Timestamp) {
      _bustTsMs = ts.millisecondsSinceEpoch;
    }

    setState(() {});
  }

  /// Selecciona imagen desde galería
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // comprime para subir más rápido
    );
    if (imagen != null) {
      setState(() {
        _imagen = File(imagen.path);
      });
    }
  }

  /// Sube la imagen (si hay) y guarda nombre/foto/notificaciones en Firestore
  Future<void> _guardarCambios() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _cargando = true);

    try {
      // Mantén el valor actual por defecto
      String? urlImagenSubida = _urlFotoPerfil;

      // Si el usuario seleccionó una imagen, súbela y obtén el downloadURL
      if (_imagen != null) {
        final ref = FirebaseStorage.instance.ref().child('fotos_perfil/$uid.jpg');

        final uploadTask = ref.putFile(
          _imagen!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snap = await uploadTask.whenComplete(() {});
        urlImagenSubida = await snap.ref.getDownloadURL();

        // ignore: avoid_print
        print('Avatar subido. URL: $urlImagenSubida');
      }

      // Usa serverTimestamp para que todos los clientes lo vean igual
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'nombre': _nombreController.text.trim(),
        'fotoPerfil': urlImagenSubida,
        'notificaciones': notificacionesActivadas,
        'photoUpdatedAt': FieldValue.serverTimestamp(), // ayuda con cache-busting
      });

      // Refresca estado local: URL y bust de cache (usa NOW para reflejar altiro en UI)
      setState(() {
        _urlFotoPerfil = urlImagenSubida;
        _bustTsMs = DateTime.now().millisecondsSinceEpoch; // bust local inmediato
        _cargando = false;
        _imagen = null; // ya no necesitamos guardar el File local
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).cambiosGuardados)),
        );
      }
    } on FirebaseException catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Storage: ${e.code} - ${e.message}')),
        );
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  /// Devuelve una URL con query param para bustear cache si hay timestamp
  String? _urlConBust(String? base) {
    if (base == null || base.isEmpty) return null;
    if (_bustTsMs == null) return base;
    final sep = base.contains('?') ? '&' : '?';
    return '$base${sep}ts=$_bustTsMs';
    }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final String? busted = _urlConBust(_urlFotoPerfil);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.ajustes),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Avatar + botón para seleccionar imagen
                  GestureDetector(
                    onTap: _seleccionarImagen,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _imagen != null
                              // Si el usuario eligió una imagen, muéstrala al tiro
                              ? FileImage(_imagen!)
                              // Si hay URL (con bust), úsala; si no, usa el asset por defecto
                              : (busted != null
                                  ? NetworkImage(busted)
                                  : const AssetImage('assets/default_avatar.png')) as ImageProvider,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFF3EC6A8),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: localizations.nombre,
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: Text(localizations.activarNotificaciones),
                    value: notificacionesActivadas,
                    onChanged: (valor) async {
                      setState(() => notificacionesActivadas = valor);
                      // suscribe / desuscribe al topic de la comunidad
                      await _aplicarSuscripcionNovedades(valor);
                      // opcional: persistir inmediatamente la preferencia (o deja que lo haga "Guardar cambios")
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(uid)
                            .update({'notificaciones': valor});
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _guardarCambios,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3EC6A8),
                      ),
                      child: Text(localizations.guardarCambios),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _aplicarSuscripcionNovedades(bool activar) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // Leemos la comunidad del usuario
  final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
  final data = doc.data() ?? {};
  final comunidad = (data['nombre_comunidad'] ?? '').toString().trim();
  if (comunidad.isEmpty) return;

  // Mismo normalizador que usamos en Functions
  String toTopic(String name) {
    final s = name
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-\.~%]'), '');
    return 'comunidad_$s';
  }

  final topic = toTopic(comunidad);
  final fcm = FirebaseMessaging.instance;

  if (activar) {
    await fcm.subscribeToTopic(topic);
  } else {
    await fcm.unsubscribeFromTopic(topic);
  }
}

}
