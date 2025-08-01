import 'package:flutter/material.dart'; // 🧱 UI principal de Flutter
import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Autenticación
import 'package:cloud_firestore/cloud_firestore.dart'; // 📄 Firestore
import 'package:firebase_messaging/firebase_messaging.dart'; // 🔔 Notificaciones push
import 'package:mi_vecino/l10n/app_localizations.dart'; // 🌐 Traducciones

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // 🔒 Clave del formulario
  final _emailController = TextEditingController(); // 📧 Email
  final _passwordController = TextEditingController(); // 🔑 Contraseña

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 🕒 Saludo dinámico traducido según hora
  String _getSaludo() {
    final hora = DateTime.now().hour;
    final localizations = AppLocalizations.of(context);
    if (hora < 12) return localizations.buenosDias;
    if (hora < 18) return localizations.buenasTardes;
    return localizations.buenasNoches;
  }

  // 🔐 Lógica de login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final credenciales = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final uid = credenciales.user!.uid;
        final snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();

        if (snapshot.exists) {
          final datos = snapshot.data()!;
          final nombreComunidad = datos['nombre_comunidad'];

          final topicSeguro = nombreComunidad
              .toLowerCase()
              .replaceAll(' ', '_')
              .trim();

          await FirebaseMessaging.instance.subscribeToTopic(topicSeguro);
          print('Suscrito correctamente al topic: $topicSeguro');
        }

        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        String mensaje = AppLocalizations.of(context).errorGenerico;

        if (e.code == 'user-not-found') {
          mensaje = AppLocalizations.of(context).usuarioNoEncontrado;
        } else if (e.code == 'wrong-password') {
          mensaje = AppLocalizations.of(context).contrasenaIncorrecta;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/logo.png', height: 210),
                const SizedBox(height: 16),

                Text(
                  _getSaludo(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: localizations.correo,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return localizations.correoInvalido;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: localizations.contrasena,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return localizations.contrasenaCorta;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Botón iniciar sesión
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3EC6A8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            localizations.iniciarSesion,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // Enlace registro
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(localizations.noCuentaRegistrate),
                ),

                // Nueva opción: ¿Olvidaste tu contraseña?
                TextButton(
                  onPressed: () {
                    final TextEditingController emailResetController = TextEditingController();

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Recuperar contraseña'),
                          content: TextField(
                            controller: emailResetController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo registrado',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final email = emailResetController.text.trim();
                                if (email.isNotEmpty && email.contains('@')) {
                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email);

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Se ha enviado un correo para restablecer tu contraseña.',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Error al enviar el correo de recuperación: $e'),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Por favor, ingresa un correo válido')),
                                  );
                                }
                              },
                              child: const Text('Enviar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),
                
                const SizedBox(height: 20),

                // Créditos
                const Text(
                  'Desarrollado por F-5 Soluciones Tecnológicas © 2025, version 2.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
