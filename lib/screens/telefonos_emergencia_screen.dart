import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mi_vecino/l10n/app_localizations.dart';

class TelefonosEmergenciaScreen extends StatelessWidget {
  const TelefonosEmergenciaScreen({super.key});

  Future<void> _llamar(String numero) async {
    final Uri launchUri = Uri(scheme: 'tel', path: numero);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'No se pudo realizar la llamada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(local.telefonosEmergencia),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTarjeta(context, local.carabineros, '133', Colors.green),
          _buildTarjeta(context, local.bomberos, '132', Colors.red),
          _buildTarjeta(context, local.samu, '131', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildTarjeta(
    BuildContext context,
    String titulo,
    String numero,    
    MaterialColor color, // ← antes era Color
  ) {
    final local = AppLocalizations.of(context);
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color[800],
          ),
        ),
        subtitle: Text(
          numero,
          style: TextStyle(
            color: color[900],
          ),
        ),
        trailing: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color[700],
            foregroundColor: Colors.white,
          ),
          onPressed: () => _llamar(numero),
          icon: const Icon(Icons.phone),
          label: Text(local.llamar),
        ),
      ),
    );
  }
}
