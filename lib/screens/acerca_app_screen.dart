import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AcercaAppScreen extends StatefulWidget {
  const AcercaAppScreen({super.key});

  @override
  State<AcercaAppScreen> createState() => _AcercaAppScreenState();
}

class _AcercaAppScreenState extends State<AcercaAppScreen> {
  String version = '...';

  @override
  void initState() {
    super.initState();
    obtenerVersion();
  }

  Future<void> obtenerVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de la App'),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi Vecino', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Una aplicación comunitaria pensada para mejorar la comunicación y colaboración entre vecinos.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text('Versión: $version', style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            const Text(
              '© 2025 Mi Vecino\nTodos los derechos reservados.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
