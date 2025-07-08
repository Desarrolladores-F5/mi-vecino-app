// lib/screens/idioma_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Para acceder a appKey y setLocale
import '../l10n/app_localizations.dart'; // Para traducciones

class IdiomaScreen extends StatefulWidget {
  const IdiomaScreen({super.key});

  @override
  State<IdiomaScreen> createState() => _IdiomaScreenState();
}

class _IdiomaScreenState extends State<IdiomaScreen> {
  // 🌐 Idioma seleccionado
  String _idiomaSeleccionado = 'es';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.idioma), // Título traducido
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 48, color: Color(0xFF3EC6A8)),
            const SizedBox(height: 20),

            // 🔘 Selector estilo switch iOS
            CupertinoSegmentedControl<String>(
              children: const {
                'es': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Español'),
                ),
                'en': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('English'),
                ),
              },
              groupValue: _idiomaSeleccionado,
              onValueChanged: (valor) {
                setState(() {
                  _idiomaSeleccionado = valor;
                });

                // Cambiar idioma dinámicamente
                final nuevoLocale = Locale(valor);
                final state = appKey.currentState;
                state?.setLocale(nuevoLocale);
              },
              selectedColor: const Color(0xFF3EC6A8),
              unselectedColor: Colors.white,
              borderColor: const Color(0xFF3EC6A8),
              pressedColor: const Color(0xFFB2EDE3),
            ),

            const SizedBox(height: 24),
            Text(
              localizations.bienvenida,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
