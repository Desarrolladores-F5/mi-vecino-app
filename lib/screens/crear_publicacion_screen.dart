import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_vecino/l10n/app_localizations.dart'; // 🌐 Localización

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({super.key});

  @override
  _CrearPublicacionScreenState createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final TextEditingController _mensajeController = TextEditingController();
  XFile? _archivoSeleccionado;
  bool _cargando = false;

  final Color colorPrincipal = const Color(0xFF007370);
  final Color colorSecundario = const Color(0xFFFF7A00);
  final Color colorBoton = const Color(0xFFFEEBCB);

  Future<void> _seleccionarArchivo() async {
    final tipoArchivo = const XTypeGroup(
      label: 'Documentos e Imágenes',
      extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    final archivo = await openFile(acceptedTypeGroups: [tipoArchivo]);

    if (archivo != null) {
      setState(() {
        _archivoSeleccionado = archivo;
      });
    }
  }

  Future<void> _publicar() async {
    final mensaje = _mensajeController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    final localizations = AppLocalizations.of(context)!;

    if (mensaje.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.mensajeVacio)),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.usuarioNoAutenticado)),
      );
      return;
    }

    setState(() {
      _cargando = true;
    });

    String? urlArchivo;

    try {
      if (_archivoSeleccionado != null) {
        final nombreArchivo = _archivoSeleccionado!.name;
        final referenciaStorage = FirebaseStorage.instance
            .ref()
            .child('publicaciones')
            .child('${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo');

        final bytes = await _archivoSeleccionado!.readAsBytes();
        final metadata = SettableMetadata(contentType: _getMimeType(nombreArchivo));

        await referenciaStorage.putData(bytes, metadata);
        urlArchivo = await referenciaStorage.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('publicaciones').add({
        'mensaje': mensaje,
        'fecha': DateTime.now(),
        'archivoUrl': urlArchivo ?? '',
        'archivoNombre': _archivoSeleccionado?.name ?? '',
        'autor': user.displayName ?? user.email ?? 'Desconocido',
        'uid': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.publicacionExitosa)),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.errorPublicar)),
      );
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  String _getMimeType(String filename) {
    final ext = filename.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  bool get _esImagen {
    if (_archivoSeleccionado == null) return false;
    final ext = _archivoSeleccionado!.path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png');
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: colorPrincipal,
        title: Text(localizations.crearPublicacion),
        actions: [
          TextButton.icon(
            onPressed: _cargando ? null : _publicar,
            icon: const Icon(Icons.send, color: Colors.white),
            label: Text(localizations.publicar, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _mensajeController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: localizations.placeholderMensaje,
                filled: true,
                fillColor: const Color(0xFFFFF4EA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargando ? null : _seleccionarArchivo,
              icon: const Icon(Icons.attach_file),
              label: Text(localizations.agregarArchivo),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBoton,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 12),
            if (_archivoSeleccionado != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${localizations.archivo}: ${_archivoSeleccionado!.name}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 10),
                  if (_esImagen)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_archivoSeleccionado!.path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            if (_cargando) ...[
              const SizedBox(height: 30),
              const Center(child: CircularProgressIndicator()),
            ]
          ],
        ),
      ),
    );
  }
}
