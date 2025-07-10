import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _nombreController = TextEditingController();
  bool notificacionesActivadas = false;
  File? _imagen;
  String? _urlFotoPerfil;
  bool _cargando = false; // ✅ Booleano para mostrar loading

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        _nombreController.text = data['nombre'] ?? '';
        _urlFotoPerfil = data['fotoPerfil'];
        notificacionesActivadas = data['notificaciones'] ?? false;
        setState(() {});
      }
    }
  }

  Future<void> _guardarCambios() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      setState(() {
        _cargando = true; // ✅ Activamos loading
      });

      String? urlImagenSubida = _urlFotoPerfil;

      if (_imagen != null) {
        final ref = FirebaseStorage.instance.ref().child('fotos_perfil/$uid.jpg');
        await ref.putFile(_imagen!);
        urlImagenSubida = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'nombre': _nombreController.text.trim(),
        'fotoPerfil': urlImagenSubida,
        'notificaciones': notificacionesActivadas,
      });

      setState(() {
        _urlFotoPerfil = urlImagenSubida; // ✅ Actualizamos la URL para mostrar la nueva imagen
        _cargando = false; // ✅ Desactivamos loading
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cambiosGuardados)),
      );
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _imagen = File(imagen.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.ajustes),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator()) // ✅ Loading visual
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _seleccionarImagen,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _imagen != null
                              ? FileImage(_imagen!)
                              : (_urlFotoPerfil != null
                                  ? NetworkImage(_urlFotoPerfil!)
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
                    onChanged: (valor) {
                      setState(() {
                        notificacionesActivadas = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _guardarCambios,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3EC6A8),
                    ),
                    child: Text(localizations.guardarCambios),
                  ),
                ],
              ),
            ),
    );
  }
}
