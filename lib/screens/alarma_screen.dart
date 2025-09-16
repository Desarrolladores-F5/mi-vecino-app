import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmaScreen extends StatefulWidget {
  const AlarmaScreen({super.key});

  @override
  State<AlarmaScreen> createState() => _AlarmaScreenState();
}

class _AlarmaScreenState extends State<AlarmaScreen> {
  final _player = AudioPlayer();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _autoOffTimer;

  String? _comunidad;
  String? _activadaPor;    // usa 'direccion' como docId (tal como ya tienes)
  bool _sonando = false;

  @override
  void initState() {
    super.initState();
    _initComunidadYListener();
  }

  @override
  void dispose() {
    _autoOffTimer?.cancel();
    _sub?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _initComunidadYListener() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Lee la comunidad del usuario (tu campo actual es 'direccion')
    final u = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final data = u.data() ?? {};
    _comunidad = (data['nombre_comunidad'] ?? '').toString().trim();

    // (opcional) fallback por si alguno aún no tiene ese campo
    if (_comunidad == null || _comunidad!.isEmpty) {
      _comunidad = (data['comunidad'] ?? data['direccion'] ?? '').toString().trim();
    }
    if (_comunidad == null || _comunidad!.isEmpty) return;

    // Suscríbete al doc de alarmas_activas/{comunidad}
    final ref = FirebaseFirestore.instance.collection('alarmas_activas').doc(_comunidad);
    _sub = ref.snapshots().listen((snap) {
      final d = snap.data() ?? {};
      final activa = d['activa'] == true;
      final durationSec = (d['durationSec'] is int) ? d['durationSec'] as int : 5;

      // Prioriza 'activada_por_direccion' si lo guardas; sino 'activada_por'
      final quien = (d['activada_por_direccion'] ?? d['activada_por'] ?? '').toString();

      // (logs opcionales)
      // print('[ALARM] doc=${snap.id} activa=$activa dur=$durationSec por=$quien');

      if (activa) {
        if (mounted) setState(() => _activadaPor = quien.isNotEmpty ? quien : null);
        _startAlarm(durationSec);
      } else {
        if (mounted) setState(() => _activadaPor = null);
        _stopAlarm();
      }
    });
  }

  Future<void> _startAlarm(int durationSec) async {
    if (_sonando) return;
    setState(() => _sonando = true);

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/alarma_vecinal_chat_ready.mp3'));

    _autoOffTimer?.cancel();
    _autoOffTimer = Timer(Duration(seconds: durationSec.clamp(1, 10)), () {
      _apagarEnFirestore(); // apaga para toda la comunidad
    });
  }

  Future<void> _stopAlarm() async {
    _autoOffTimer?.cancel();
    await _player.stop();
    if (mounted) setState(() => _sonando = false);
  }

  Future<void> _activarEnFirestore({required int durationSec}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _comunidad == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    final udata = userDoc.data() ?? {};

    // 👇 Preferimos DIRECCIÓN para mostrar a la comunidad quién activó
    final direccion = (udata['direccion'] ?? '').toString().trim();
    final nombre    = (udata['nombre'] ?? '').toString().trim();
    final correo    = FirebaseAuth.instance.currentUser?.email ?? 'desconocido@correo';

  // Si no hay dirección, usamos nombre → si tampoco, usamos correo
    final activador = direccion.isNotEmpty ? direccion : (nombre.isNotEmpty ? nombre : correo);

    final ref = FirebaseFirestore.instance.collection('alarmas_activas').doc(_comunidad);
    await ref.set({
      'activa'      : true,
      'durationSec' : durationSec.clamp(1, 10),
      'hora'        : FieldValue.serverTimestamp(),
      'activada_por': activador,             // 👈 ahora es la DIRECCIÓN (o nombre/correo fallback)
      'activada_por_uid'         : uid,                   // (opcional) auditoría
      'activada_por_direccion'   : direccion,             // (opcional) explícito
      'activada_por_nombre'      : nombre,                // (opcional)
    }, SetOptions(merge: true));

    // Feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🚨 Alarma activada en $_comunidad (${durationSec}s)')),
      );
    }
  }

  Future<void> _apagarEnFirestore() async {
    if (_comunidad == null) return;
    final ref = FirebaseFirestore.instance.collection('alarmas_activas').doc(_comunidad);
    await ref.set({'activa': false}, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🛑 Alarma apagada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeControlar = _comunidad != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Alarma Vecinal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.home),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _comunidad == null ? 'Sin comunidad asociada' : 'Comunidad: $_comunidad',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(_sonando ? 'Sonando' : 'Apagada'),
                  backgroundColor: _sonando ? Colors.red.shade100 : Colors.green.shade100,
                  avatar: Icon(_sonando ? Icons.volume_up : Icons.volume_off),
                ),
              ],
            ),

            const SizedBox(height: 12),
            if (_activadaPor != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alarma activada desde: $_activadaPor',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

          // ===================== BOTONES =====================
          const Spacer(),          
          Column(
            children: [
              // 🔴 Botón grande para activar la alarma (10s)
              StatefulBuilder(
                builder: (context, setState) {
                  bool isPressed = false;
                  return GestureDetector(
                    onTapDown: (_) => setState(() => isPressed = true),
                    onTapUp: (_) => setState(() => isPressed = false),
                    onTapCancel: () => setState(() => isPressed = false),
                    child: AnimatedScale(
                      scale: isPressed ? 0.95 : 1.0, // 👈 mini-zoom
                      duration: const Duration(milliseconds: 100),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: puedeControlar ? () => _activarEnFirestore(durationSec: 10) : null,
                          icon: const Icon(Icons.campaign, size: 28, color: Colors.white),
                          label: const Text(
                            'ACTIVAR',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ButtonStyle(
                            backgroundColor: const WidgetStatePropertyAll<Color>(Colors.red),
                            foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
                            padding: const WidgetStatePropertyAll<EdgeInsets>(
                              EdgeInsets.symmetric(vertical: 20),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            elevation: WidgetStateProperty.resolveWith<double>(
                              (states) => states.contains(WidgetState.pressed) ? 2 : 8,
                            ),
                            animationDuration: const Duration(milliseconds: 90),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30), // separación entre botones

              // 🟢 Botón para apagar la alarma
              StatefulBuilder(
                builder: (context, setState) {
                  bool isPressed = false;
                  return GestureDetector(
                    onTapDown: (_) => setState(() => isPressed = true),
                    onTapUp: (_) => setState(() => isPressed = false),
                    onTapCancel: () => setState(() => isPressed = false),
                    child: AnimatedScale(
                      scale: isPressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: puedeControlar && _sonando ? _apagarEnFirestore : null,
                          icon: const Icon(Icons.stop_circle, size: 28, color: Colors.white),
                          label: const Text(
                            'APAGAR ALARMA',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                              (states) => Colors.black,
                            ),
                            foregroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
                            padding: const WidgetStatePropertyAll<EdgeInsets>(
                              EdgeInsets.symmetric(vertical: 18),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            elevation: WidgetStateProperty.resolveWith<double>(
                              (states) => states.contains(WidgetState.pressed) ? 2 : 8,
                            ),
                            animationDuration: const Duration(milliseconds: 90),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          // ==================================================          
          ],
        ),
      ),
    );
  }
}
