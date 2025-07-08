import 'package:flutter/material.dart'; // 🧱 UI
import 'package:firebase_auth/firebase_auth.dart'; // 🔐 Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // ☁️ Firestore
import 'package:awesome_dialog/awesome_dialog.dart'; // 💬 Diálogos bonitos
import 'package:mi_vecino/l10n/app_localizations.dart'; // 🌐 Traducciones

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _nombreComunidadController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 📝 Registro de usuario con validación de dirección
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      final direccion = _direccionController.text.trim();
      final localizations = AppLocalizations.of(context);

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('direccion', isEqualTo: direccion)
            .get();

        if (snapshot.docs.length >= 2) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            animType: AnimType.rightSlide,
            title: localizations.limiteAlcanzado,
            desc: localizations.maximoDosPorDireccion,
            btnOkOnPress: () {},
          ).show();
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'direccion': direccion,
          'nombre_comunidad': _nombreComunidadController.text.trim(),
          'email': _emailController.text.trim(),
          'uid': userCredential.user!.uid,
          'fecha_registro': Timestamp.now(),
        });

        AwesomeDialog(
          context: context,
          dialogType: DialogType.success,
          animType: AnimType.scale,
          title: localizations.registroExitoso,
          desc: localizations.usuarioRegistrado,
          btnOkOnPress: () {
            Navigator.pop(context);
          },
        ).show();
      } on FirebaseAuthException catch (e) {
        String mensaje = localizations.errorGenerico;

        if (e.code == 'email-already-in-use') {
          mensaje = localizations.correoYaRegistrado;
        } else if (e.code == 'weak-password') {
          mensaje = localizations.contrasenaDebil;
        } else if (e.code == 'invalid-email') {
          mensaje = localizations.correoInvalido;
        }

        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.bottomSlide,
          title: localizations.atencion,
          desc: mensaje,
          btnOkOnPress: () {},
        ).show();
      } catch (e) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.topSlide,
          title: localizations.error,
          desc: '${localizations.errorInesperado}: $e',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

  // 🎨 Estilo de los campos
  InputDecoration _buildDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: Text(localizations.registroVecinos),
        centerTitle: true,
        backgroundColor: const Color(0xFF3EC6A8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: _buildDecoration(localizations.nombre),
                  validator: (v) =>
                      v == null || v.isEmpty ? localizations.ingresaNombre : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apellidoController,
                  decoration: _buildDecoration(localizations.apellidos),
                  validator: (v) =>
                      v == null || v.isEmpty ? localizations.ingresaApellidos : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionController,
                  decoration: _buildDecoration(localizations.direccion),
                  validator: (v) =>
                      v == null || v.isEmpty ? localizations.ingresaDireccion : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreComunidadController,
                  decoration: _buildDecoration(localizations.nombreComunidad),
                  validator: (v) => v == null || v.isEmpty
                      ? localizations.ingresaNombreComunidad
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: _buildDecoration(localizations.correo),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@')
                      ? localizations.correoInvalido
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _buildDecoration(localizations.contrasena),
                  validator: (v) => v == null || v.length < 6
                      ? localizations.contrasenaCorta
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _buildDecoration(localizations.confirmarContrasena),
                  validator: (v) => v != _passwordController.text
                      ? localizations.contrasenasNoCoinciden
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3EC6A8),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _registerUser,
                  child: Text(localizations.registrarse,
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(localizations.yaTienesCuenta),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
