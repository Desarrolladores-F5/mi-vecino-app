import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';

class CamarasScreen extends StatelessWidget {
  const CamarasScreen({super.key});

  final List<Map<String, String>> camaras = const [
    {
      'nombre': 'Viña del Mar - Playa Reñaca',
      'url': 'https://www.skylinewebcams.com/es/webcam/chile/valparaiso/vina-del-mar/vina-del-mar.html',
    },
    {
      'nombre': 'Playa El Quisco',
      'url': 'https://www.skylinewebcams.com/es/webcam/chile/valparaiso/san-antonio/el-quisco.html',
    },
    {
      'nombre': 'Valparaíso - Puerto',
      'url': 'https://www.skylinewebcams.com/es/webcam/chile/valparaiso/valparaiso/panorama.html',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.camarasComunitarias),
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: ListView.builder(
        itemCount: camaras.length,
        itemBuilder: (context, index) {
          final camara = camaras[index];
          return ListTile(
            leading: const Icon(Icons.videocam, color: Colors.green),
            title: Text(camara['nombre']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) {
                    final local = AppLocalizations.of(context)!;
                    return Scaffold(
                      appBar: AppBar(
                        title: Text(
                            '${local.camarasComunitarias} - ${camara['nombre']!}'),
                        backgroundColor: const Color(0xFF3EC6A8),
                      ),
                      body: WebViewWidget(
                        controller: WebViewController()
                          ..setJavaScriptMode(JavaScriptMode.unrestricted)
                          ..loadRequest(Uri.parse(camara['url']!)),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
