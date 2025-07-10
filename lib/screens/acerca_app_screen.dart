import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mi_vecino/l10n/app_localizations.dart'; // 🌐 Soporte de idiomas

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
    obtenerVersion(); // 🆙 Obtener versión de la app
  }

  // 🔍 Método para obtener la versión desde PackageInfo
  Future<void> obtenerVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.acercaDe), // 🧭 Título internacionalizado
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mi Vecino', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              localizations.descripcionApp, // 🌍 Descripción traducida
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text('${localizations.version}: $version', style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            Text(
              '© 2025 Mi Vecino\n${localizations.derechosReservados}', // 💼 Legal
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
