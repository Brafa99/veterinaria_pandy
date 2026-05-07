import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';

class UsuarioFormPage extends StatefulWidget {
  final String? userId;

  const UsuarioFormPage({super.key, this.userId});

  @override
  State<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends State<UsuarioFormPage> {
  final formKey = GlobalKey<FormState>();

  final nombre = TextEditingController();
  final apellido = TextEditingController();
  final usuario = TextEditingController();
  final password = TextEditingController();
  final telefono = TextEditingController();
  final correo = TextEditingController();

  String tipo = "empleado";
  bool loading = false;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      isEdit = true;
      _loadUser();
    }
  }

  @override
  void didUpdateWidget(covariant UsuarioFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.userId != oldWidget.userId) {
      if (widget.userId != null) {
        isEdit = true;
        _loadUser();
      } else {
        isEdit = false;
        _clearForm();
      }
    }
  }

  void _clearForm() {
    nombre.clear();
    apellido.clear();
    usuario.clear();
    password.clear();
    telefono.clear();
    correo.clear();
    tipo = "empleado";

    setState(() {});
  }

  Future<void> _loadUser() async {
    try {
      if (widget.userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("usuarios")
          .doc(widget.userId)
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;

      setState(() {
        nombre.text = data["nombre"] ?? "";
        apellido.text = data["apellido"] ?? "";
        usuario.text = data["usuario"] ?? "";
        telefono.text = data["telefono"] ?? "";
        correo.text = data["correo"] ?? "";
        tipo = data["tipo"] ?? "empleado";
        isEdit = true;
      });
    } catch (e) {
      debugPrint("Error cargando usuario: $e");
    }
  }

  Future<void> guardar() async {
  if (!formKey.currentState!.validate()) return;

  setState(() => loading = true);

  try {
    // ================= SECONDARY AUTH =================
    final secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp',
      options: Firebase.app().options,
    );

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    // ================= CREATE USER =================
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: correo.text.trim(),
      password: password.text.trim(),
    );

    final uid = cred.user!.uid;

    // ================= SAVE FIRESTORE =================
    await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(uid)
        .set({
      "nombre": nombre.text.trim(),
      "apellido": apellido.text.trim(),
      "usuario": usuario.text.trim(),
      "telefono": telefono.text.trim(),
      "correo": correo.text.trim(),
      "tipo": tipo,
      "imagen": "",
      "createdAt": FieldValue.serverTimestamp(),
    });

    // ================= CLEANUP =================
    await secondaryAuth.signOut();
    await secondaryApp.delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Usuario creado correctamente"),
        backgroundColor: Colors.green,
      ),
    );

    DashboardController.editingUserId = null;
    DashboardController.goTo(1);

  } on FirebaseAuthException catch (e) {
    String msg = "Error al crear usuario";

    if (e.code == "email-already-in-use") {
      msg = "El correo ya está registrado";
    } else if (e.code == "weak-password") {
      msg = "La contraseña es muy débil";
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));

  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error: $e")));
  }

  setState(() => loading = false);
}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double maxWidth;
    EdgeInsets padding;

    if (width < 600) {
      maxWidth = double.infinity;
      padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
    } else if (width < 1100) {
      maxWidth = 600;
      padding = const EdgeInsets.all(20);
    } else {
      maxWidth = 650;
      padding = const EdgeInsets.all(25);
    }

    return Container(
      color: const Color(0xFFF4F6FA),
      child: Center(
        child: SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _formContent(),
          ),
        ),
      ),
    );
  }

  Widget _formContent() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // HEADER
            Row(
              children: [
                Text(
                  isEdit ? "Editar Usuario" : "Registrar Usuario",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            _title("Datos personales"),
            _field(Icons.person, "Nombre", nombre),
            _field(Icons.person_outline, "Apellido", apellido),

            const SizedBox(height: 10),

            _title("Acceso"),
            _field(Icons.account_circle, "Usuario", usuario),
            _field(Icons.email, "Correo", correo),
            _field(Icons.phone, "Teléfono", telefono),

            if (!isEdit)
              _field(Icons.lock, "Contraseña", password, obscure: true),

            const SizedBox(height: 10),

            _title("Contacto"),

            const SizedBox(height: 10),

            _title("Tipo de usuario"),

            DropdownButtonFormField(
              value: tipo,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "administrador", child: Text("Administrador")),
                DropdownMenuItem(value: "empleado", child: Text("Empleado")),
                DropdownMenuItem(value: "cliente", child: Text("Cliente")),
              ],
              onChanged: (v) => setState(() => tipo = v.toString()),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0054A6),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? "Actualizar Usuario" : "Guardar Usuario",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    IconData icon,
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,

        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return "Campo requerido";
          }
          return null;
        },

        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: isMobile ? 20 : 24),
          labelText: label,
          isDense: isMobile,
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}
