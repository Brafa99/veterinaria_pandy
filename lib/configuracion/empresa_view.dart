import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmpresaView extends StatefulWidget {
  const EmpresaView({super.key});

  @override
  State<EmpresaView> createState() => _EmpresaViewState();
}

class _EmpresaViewState extends State<EmpresaView> {
  final _formKey = GlobalKey<FormState>();

  final empresaCtrl = TextEditingController();
  final rucCtrl = TextEditingController();
  final monedaCtrl = TextEditingController();
  final simboloCtrl = TextEditingController();
  final impuestoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final correoCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();

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

      empresaCtrl.text = d["empresa"] ?? "";
      rucCtrl.text = d["ruc"] ?? "";
      monedaCtrl.text = d["moneda"] ?? "";
      simboloCtrl.text = d["simbolo_moneda"] ?? "";
      impuestoCtrl.text =
          (d["impuesto_producto"] ?? 0).toString();
      direccionCtrl.text = d["direccion"] ?? "";
      correoCtrl.text = d["correo"] ?? "";
      telefonoCtrl.text = d["telefono"] ?? "";
      descripcionCtrl.text = d["descripcion"] ?? "";
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
      "empresa": empresaCtrl.text,
      "ruc": rucCtrl.text,
      "moneda": monedaCtrl.text,
      "simbolo_moneda": simboloCtrl.text,
      "impuesto_producto":
          double.tryParse(impuestoCtrl.text) ?? 0,
      "direccion": direccionCtrl.text,
      "correo": correoCtrl.text,
      "telefono": telefonoCtrl.text,
      "descripcion": descripcionCtrl.text,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Datos actualizados")),
    );
  }

  /// ================= INPUT =================
  Widget input(String label, TextEditingController ctrl,
      {bool number = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType:
          number ? TextInputType.number : TextInputType.text,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
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
                        "Datos de la Empresa",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// GRID RESPONSIVE
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [

                          SizedBox(
                              width: 450,
                              child: input("Empresa", empresaCtrl)),

                          SizedBox(
                              width: 450,
                              child: input("NIT / RUC", rucCtrl)),

                          SizedBox(
                              width: 200,
                              child: input("Moneda", monedaCtrl)),

                          SizedBox(
                              width: 200,
                              child: input("Símbolo", simboloCtrl)),

                          SizedBox(
                              width: 200,
                              child: input("Impuesto %", impuestoCtrl,
                                  number: true)),

                          SizedBox(
                              width: 450,
                              child: input("Correo", correoCtrl)),

                          SizedBox(
                              width: 450,
                              child: input("Teléfono", telefonoCtrl)),

                          SizedBox(
                              width: 920,
                              child: input("Dirección", direccionCtrl)),

                          SizedBox(
                              width: 920,
                              child: input("Descripción",
                                  descripcionCtrl,
                                  maxLines: 3)),
                        ],
                      ),

                      const SizedBox(height: 25),

                      /// BOTÓN
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: saving ? null : save,
                          icon: const Icon(Icons.save),
                          label: saving
                              ? const Text("Guardando...")
                              : const Text("Guardar cambios"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                          ),
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