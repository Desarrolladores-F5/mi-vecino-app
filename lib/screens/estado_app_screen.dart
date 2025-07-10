import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';

class EstadoAppScreen extends StatefulWidget {
  const EstadoAppScreen({super.key});

  @override
  _EstadoAppScreenState createState() => _EstadoAppScreenState();
}

class _EstadoAppScreenState extends State<EstadoAppScreen> {
  String _version = '';
  String _conexion = '';
  String _nombre = '';
  String _correo = '';

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    // Versión
    final info = await PackageInfo.fromPlatform();
    final version = info.version;

    // Estado de conexión
    final connectivityResult = await Connectivity().checkConnectivity();
    final conectado = connectivityResult != ConnectivityResult.none;

    // Usuario actual
    final user = FirebaseAuth.instance.currentUser;
    String nombre = '';
    String correo = '';

    if (user != null) {
      correo = user.email ?? '';

      // Buscar el nombre desde Firestore
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()!.containsKey('nombre')) {
        nombre = doc['nombre'];
      } else {
        nombre = AppLocalizations.of(context).desconocido;
      }
    }

    setState(() {
      _version = version;
      _conexion = conectado
          ? AppLocalizations.of(context).conectado
          : AppLocalizations.of(context).desconectado;
      _nombre = nombre;
      _correo = correo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.estadoApp),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizations.versionApp}: $_version'),
            SizedBox(height: 8),
            Text('${localizations.estadoConexion}: $_conexion'),
            SizedBox(height: 8),
            Text('${localizations.usuarioLogueado}: $_nombre'),
            SizedBox(height: 8),
            Text('${localizations.correoElectronico}: $_correo'),
          ],
        ),
      ),
    );
  }
}
