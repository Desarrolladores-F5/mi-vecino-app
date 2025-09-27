import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';

class CamarasScreen extends StatelessWidget {
  const CamarasScreen({super.key, this.nombreComunidad});

  final String? nombreComunidad;

  Future<List<Map<String, String>>> _loadCamaras() async {
    final id = (nombreComunidad ?? '').trim();
    if (id.isEmpty) return const [];

    final snap = await FirebaseFirestore.instance
        .collection('config_comunidades')
        .doc(id)
        .get();

    final data = snap.data() ?? {};
    final cams = (data['camaras'] as List?) ?? const [];
    return cams
        .whereType<Map>()
        .map((m) => {
              'nombre': (m['nombre'] ?? '').toString(),
              'url': (m['url'] ?? '').toString(),
            })
        .where((m) => m['nombre']!.isNotEmpty && m['url']!.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(local.camarasComunitarias),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _loadCamaras(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final camaras = snap.data ?? const [];

          if (camaras.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No hay cámaras configuradas para esta comunidad.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: camaras.length,
            itemBuilder: (context, i) {
              final c = camaras[i];
              return ListTile(
                leading: const Icon(Icons.videocam, color: Colors.green),
                title: Text(c['nombre']!),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _CamWebView(
                        titulo: '${local.camarasComunitarias} - ${c['nombre']}',
                        url: c['url']!,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CamWebView extends StatelessWidget {
  const _CamWebView({required this.titulo, required this.url});
  final String titulo;
  final String url;

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
