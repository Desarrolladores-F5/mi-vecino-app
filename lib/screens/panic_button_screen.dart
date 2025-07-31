import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class PanicButtonScreen extends StatefulWidget {
  const PanicButtonScreen({super.key});

  @override
  State<PanicButtonScreen> createState() => _PanicButtonScreenState();
}

class _PanicButtonScreenState extends State<PanicButtonScreen> {
  bool _sending = false;

  Future<void> _sendPanicAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Confirmación antes de enviar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar alerta'),
        content: const Text(
            '¿Seguro que deseas enviar una alerta de pánico a tu comunidad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _sending = true);

    try {
      // 1. Verificar permisos de ubicación
      var status = await Permission.location.request();
      if (!status.isGranted) {
        throw Exception(
            "Permiso de ubicación denegado. No se puede enviar la alerta.");
      }

      // 2. Obtener datos del usuario
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();
      final nombre = userData?['nombre'] ?? 'Vecino';
      final comunidad = userData?['nombre_comunidad'] ?? 'general';

      // 3. Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high),
        );
      
      // 4. Guardar alerta en Firestore
      await FirebaseFirestore.instance.collection('panic_alerts').add({
        'userId': user.uid,
        'nombre': nombre,
        'comunidad': comunidad,
        'latitud': position.latitude,
        'longitud': position.longitude,
        'fecha': Timestamp.now(),
      });

      // 5. Suscribirse al topic (opcional)
      final topic = comunidad.toLowerCase().replaceAll(' ', '_');
      await FirebaseMessaging.instance.subscribeToTopic(topic);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta enviada a tu comunidad.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar alerta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Botón de Pánico'),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: Center(
        child: _sending
            ? const CircularProgressIndicator()
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                ),
                onPressed: _sendPanicAlert,
                child: const Text(
                  'ENVIAR ALERTA',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
      ),
    );
  }
}
