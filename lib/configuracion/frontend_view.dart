import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FrontendView extends StatefulWidget {
  const FrontendView({super.key});

  @override
  State<FrontendView> createState() => _FrontendViewState();
}

class _FrontendViewState extends State<FrontendView> {
  final _formKey = GlobalKey<FormState>();

  final tituloCtrl = TextEditingController();
  final misionCtrl = TextEditingController();
  final visionCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final mapsCtrl = TextEditingController();
  final facebookCtrl = TextEditingController();
  final twitterCtrl = TextEditingController();
  final servicios1Ctrl = TextEditingController();
  final servicios2Ctrl = TextEditingController();
  final servicios3Ctrl = TextEditingController();

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  /// ================= LOAD =================
  Future<void> loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection("configuracion")
        .doc("1")
        .get();

    if (doc.exists) {
      final d = doc.data()!;

      tituloCtrl.text = d["titulo"] ?? "";
      misionCtrl.text = d["mision"] ?? "";
      visionCtrl.text = d["vision"] ?? "";
      direccionCtrl.text = d["direccion"] ?? "";
      mapsCtrl.text = d["google_maps"] ?? "";
      facebookCtrl.text = d["facebook"] ?? "";
      twitterCtrl.text = d["twitter"] ?? "";
      servicios1Ctrl.text = d["servicios1"] ?? "";
      servicios2Ctrl.text = d["servicios2"] ?? "";
      servicios3Ctrl.text = d["servicios3"] ?? "";
    }

    setState(() => loading = false);
  }

  /// ================= SAVE =================
  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    await FirebaseFirestore.instance
        .collection("configuracion")
        .doc("1")
        .update({
      "titulo": tituloCtrl.text,
      "mision": misionCtrl.text,
      "vision": visionCtrl.text,
      "direccion": direccionCtrl.text,
      "google_maps": mapsCtrl.text,
      "facebook": facebookCtrl.text,
      "twitter": twitterCtrl.text,
      "servicios1": servicios1Ctrl.text,
      "servicios2": servicios2Ctrl.text,
      "servicios3": servicios3Ctrl.text,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Contenido actualizado")),
    );
  }

  /// ================= INPUT =================
  Widget input(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: (v) => v!.isEmpty ? "Requerido" : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF0054A6), width: 2),
        ),
      ),
    );
  }

  Widget section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Contenido Frontend",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      /// 🟦 BRANDING
                      section("Branding"),
                      input("Título", tituloCtrl),

                      /// 🟩 MISIÓN / VISIÓN
                      section("Misión y Visión"),
                      input("Misión", misionCtrl, maxLines: 3),
                      const SizedBox(height: 12),
                      input("Visión", visionCtrl, maxLines: 3),

                      /// 🟨 UBICACIÓN
                      section("Ubicación"),
                      input("Dirección", direccionCtrl),
                      const SizedBox(height: 12),
                      input("Código Google Maps", mapsCtrl,
                          maxLines: 2),

                      /// 🟪 REDESt
                      section("Redes Sociales"),
                      input("Facebook", facebookCtrl),
                      const SizedBox(height: 12),
                      input("Twitter", twitterCtrl),
                      const SizedBox(height: 12),

                      /// 🟥 SERVICIOS
                      section("Servicios"),
                      const SizedBox(height: 12),
                      input("Servicio 1", servicios1Ctrl,
                          maxLines: 2),
                      const SizedBox(height: 12),
                      input("Servicio 2", servicios2Ctrl,
                          maxLines: 2),
                      const SizedBox(height: 12),
                      input("Servicio 3", servicios3Ctrl,
                          maxLines: 2),

                      const SizedBox(height: 25),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: saving ? null : save,
                          icon: const Icon(Icons.save),
                          label: saving
                              ? const Text("Guardando...")
                              : const Text("Guardar cambios"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}