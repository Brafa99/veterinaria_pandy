import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();

  bool loading = false;
  bool rememberMe = false;

  Future<void> login() async {
  setState(() => loading = true);

  try {

    await FirebaseAuth.instance
    .signInWithEmailAndPassword(
  email: email.text.trim(),
  password: pass.text.trim(),
);

final prefs =
    await SharedPreferences.getInstance();

await prefs.setBool(
  "rememberMe",
  rememberMe,
);

if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const DashboardPage(),
  ),
);

  } on FirebaseAuthException catch (e) {

    String message;

    switch (e.code) {

      case 'user-not-found':
        message = 'El usuario no existe.';
        break;

      case 'wrong-password':
        message = 'La contraseña es incorrecta.';
        break;

      case 'invalid-email':
        message = 'El correo no es válido.';
        break;

      case 'user-disabled':
        message = 'Este usuario ha sido deshabilitado.';
        break;

      case 'too-many-requests':
        message =
            'Demasiados intentos. Intenta más tarde.';
        break;

      case 'invalid-credential':
        message = 'Credenciales incorrectas.';
        break;

      case 'network-request-failed':
        message =
            'Error de conexión a internet.';
        break;

      default:
        message = 'Error al iniciar sesión.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text("Ocurrió un error inesperado."),
        backgroundColor: Colors.red,
      ),
    );

  } finally {

    if (mounted) {
      setState(() => loading = false);
    }
  }
}

  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: Stack(
    children: [
      // 🔥 FONDO (más vivo, sin oscurecerlo tanto)
      Positioned.fill(
        child: Image.asset(
          "assets/img/desarrollo.jpg",
          fit: BoxFit.cover,
        ),
      ),

      // 🔥 OVERLAY SUAVE (NO OPACA)
      Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.50), // 👈 clave: más ligero
        ),
      ),

      // 🔥 CENTRADO REAL
      Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets,
                      size: 50, color: Color(0xFF0054A6)),

                  const SizedBox(height: 10),

                  const Text(
                    "Veterinaria Pandy",
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  TextField(
                    controller: email,
                    style: const TextStyle(color: Colors.white),
                    decoration: _input("Usuario / Email"),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: pass,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _input("Contraseña"),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 CHECKBOX REAL
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (v) {
                          setState(() {
                            rememberMe = v ?? false;
                          });
                        },
                        activeColor: const Color(0xFF0054A6),
                      ),
                      const Text(
                        "Recordar sesión",
                        style: TextStyle(color: Colors.white70),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0054A6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Ingresar", style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }

  InputDecoration _input(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white54),
    filled: true,
    fillColor: Colors.white.withOpacity(0.05),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.white24),
      borderRadius: BorderRadius.circular(10),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF0054A6)),
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
}