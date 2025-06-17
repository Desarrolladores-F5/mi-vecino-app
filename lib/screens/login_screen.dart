import 'package:flutter/material.dart'; // 🧱 UI principal de Flutter
import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Autenticación con Firebase

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 🔒 Clave del formulario
  final _formKey = GlobalKey<FormState>();

  // 📝 Controladores para los campos de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🎯 Estados internos
  bool _isLoading = false; // Cargando mientras intenta loguearse
  bool _obscurePassword = true; // Mostrar/ocultar contraseña

  // 🕒 Genera saludo personalizado según la hora
  String _getSaludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return '¡Buenos días, vecino!';
    if (hora < 18) return '¡Buenas tardes, vecino!';
    return '¡Buenas noches, vecino!';
  }

  // 🔐 Inicia sesión con Firebase Auth
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 📨 Intenta loguear con Firebase
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // ✅ Si todo va bien, redirige al Home
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        // ❌ Errores comunes de autenticación
        String mensaje = 'Error al iniciar sesión';
        if (e.code == 'user-not-found') {
          mensaje = 'Usuario no encontrado';
        } else if (e.code == 'wrong-password') {
          mensaje = 'Contraseña incorrecta';
        }

        // 📢 Muestra error
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
    return Scaffold(
      // 🎨 Fondo claro y amigable
      backgroundColor: const Color(0xFFF6F8FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 🖼️ Logo principal
                Image.asset('assets/logo.png', height: 210),
                const SizedBox(height: 16),

                // 👋 Saludo dinámico
                Text(
                  _getSaludo(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 32),

                // 📧 Campo de email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🔑 Campo de contraseña con opción de visibilidad
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
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
                      return 'Contraseña muy corta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 🔘 Botón de inicio de sesión o indicador de carga
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3EC6A8), // 🎨 Color botón
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // 📎 Enlace para registrarse
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register'); // 👉 Redirige al registro
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
