import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CambiarPasswordView extends StatefulWidget {
  const CambiarPasswordView({super.key});

  @override
  State<CambiarPasswordView> createState() =>
      _CambiarPasswordViewState();
}

class _CambiarPasswordViewState
    extends State<CambiarPasswordView> {
  final _formKey = GlobalKey<FormState>();

  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool saving = false;

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      await user!.updatePassword(passwordCtrl.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña actualizada")),
      );

      passwordCtrl.clear();
      confirmCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? "";

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Text(
                      "Cambiar contraseña",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// USUARIO
                    TextFormField(
                      initialValue: email,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Usuario",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// PASSWORD
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      validator: (v) =>
                          v!.length < 6 ? "Mínimo 6 caracteres" : null,
                      decoration: InputDecoration(
                        labelText: "Nueva contraseña",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// CONFIRM
                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: true,
                      validator: (v) => v != passwordCtrl.text
                          ? "No coinciden"
                          : null,
                      decoration: InputDecoration(
                        labelText: "Repetir contraseña",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving ? null : changePassword,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: saving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Actualizar contraseña"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}