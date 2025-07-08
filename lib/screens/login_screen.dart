import 'package:flutter/material.dart'; // 🧱 UI principal de Flutter
import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Autenticación con Firebase
import 'package:mi_vecino/l10n/app_localizations.dart'; // 🌐 Soporte de idiomas

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // 🔒 Clave del formulario
  final _emailController = TextEditingController(); // 📧 Controlador email
  final _passwordController = TextEditingController(); // 🔑 Controlador contraseña

  bool _isLoading = false;
  bool _obscurePassword = true;

  // 🕒 Genera saludo dinámico traducido según la hora
  String _getSaludo() {
    final hora = DateTime.now().hour;
    final localizations = AppLocalizations.of(context);
    if (hora < 12) return localizations.buenosDias;
    if (hora < 18) return localizations.buenasTardes;
    return localizations.buenasNoches;
  }

  // 🔐 Inicia sesión con Firebase Auth
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

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
                Image.asset('assets/logo.png', height: 210), // 🖼️ Logo
                const SizedBox(height: 16),

                Text(
                  _getSaludo(), // 👋 Saludo según la hora
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 32),

                // 📧 Campo de correo
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

                // 🔑 Campo de contraseña
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

                // 🔘 Botón iniciar sesión
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

                // 📎 Enlace registro
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(localizations.noCuentaRegistrate),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
