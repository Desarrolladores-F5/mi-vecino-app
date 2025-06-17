// ✅ Versión actualizada visualmente de register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

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

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      final direccion = _direccionController.text.trim();

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
            title: 'Límite alcanzado',
            desc: 'Solo se permiten 2 personas registradas por dirección.',
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
          title: 'Registro exitoso',
          desc: 'El usuario fue registrado correctamente.',
          btnOkOnPress: () {
            Navigator.pop(context);
          },
        ).show();
      } on FirebaseAuthException catch (e) {
        String mensaje = 'Ocurrió un error con el registro.';
        if (e.code == 'email-already-in-use') {
          mensaje = 'El correo ya está registrado';
        } else if (e.code == 'weak-password') {
          mensaje = 'Contraseña muy débil';
        } else if (e.code == 'invalid-email') {
          mensaje = 'Correo electrónico inválido';
        }

        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.bottomSlide,
          title: 'Atención',
          desc: mensaje,
          btnOkOnPress: () {},
        ).show();
      } catch (e) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.topSlide,
          title: 'Error',
          desc: 'Error inesperado: $e',
          btnOkOnPress: () {},
        ).show();
      }
    }
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        title: const Text('Registro de Vecinos'),
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
                  decoration: _buildDecoration('Nombre'),
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apellidoController,
                  decoration: _buildDecoration('Apellidos'),
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa tus apellidos' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionController,
                  decoration: _buildDecoration('Dirección'),
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa tu dirección' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreComunidadController,
                  decoration: _buildDecoration('Nombre de Comunidad'),
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa el nombre de la comunidad' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: _buildDecoration('Correo electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _buildDecoration('Contraseña'),
                  validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _buildDecoration('Confirmar contraseña'),
                  validator: (v) => v != _passwordController.text ? 'No coinciden' : null,
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
                  child: const Text('Registrarse', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
