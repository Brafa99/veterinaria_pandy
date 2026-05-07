import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';

class ClienteFormPage extends StatefulWidget {
  final String? clienteId;

  const ClienteFormPage({super.key, this.clienteId});

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final formKey = GlobalKey<FormState>();
  bool loading = false;

  final nombreMascota = TextEditingController();
  final raza = TextEditingController();
  final color = TextEditingController();
  final especie = TextEditingController();
  final sexo = TextEditingController();

  final nombreDueno = TextEditingController();
  final telefono = TextEditingController();
  final direccion = TextEditingController();
  final ci = TextEditingController();
  final correo = TextEditingController();
  final marcaTatuaje = TextEditingController();
  final nit = TextEditingController();

  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteId != null) {
      isEdit = true;
      _load();
    }
  }

  @override
  void dispose() {
    nombreMascota.dispose();
    raza.dispose();
    color.dispose();
    especie.dispose();
    nit.dispose();
    sexo.dispose();
    marcaTatuaje.dispose();
    nombreDueno.dispose();
    telefono.dispose();
    direccion.dispose();
    ci.dispose();
    correo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection("clientes")
        .doc(widget.clienteId)
        .get();

    if (!doc.exists) return;

    final d = doc.data()!;

    nombreMascota.text = d["nombre_mascota"] ?? "";
    raza.text = d["raza"] ?? "";
    color.text = d["color"] ?? "";
    especie.text = d["especie"] ?? "";
    sexo.text = d["sexo"] ?? "";
    nombreDueno.text = d["nombre"] ?? "";
    telefono.text = d["telefono"] ?? "";
    direccion.text = d["direccion"] ?? "";
    ci.text = d["ci"] ?? d["dni"] ?? "";
    nit.text = d["nit"] ?? "";
    correo.text = d["correo"] ?? "";

    marcaTatuaje.text =
        (d["marca_tatuaje"] == null || d["marca_tatuaje"] == "")
            ? "No tiene"
            : d["marca_tatuaje"];
  }

  List<String> _searchIndex() {
    final list = <String>{};

    void add(String v) {
      if (v.trim().isNotEmpty) {
        list.add(v.toLowerCase().trim());
      }
    }

    add(nombreMascota.text);
    add(raza.text);
    add(color.text);
    add(especie.text);
    add(sexo.text);
    add(nombreDueno.text);
    add(telefono.text);
    add(ci.text);
    add(nit.text);
    add(direccion.text);
    add(marcaTatuaje.text);

    return list.toList();
  }

  Future<void> guardar() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final data = {
      "nombre_mascota": nombreMascota.text,
      "raza": raza.text,
      "color": color.text,
      "especie": especie.text,
      "sexo": sexo.text,

      "marca_tatuaje": marcaTatuaje.text == "No tiene"
          ? ""
          : marcaTatuaje.text,

      "nombre": nombreDueno.text,
      "telefono": telefono.text,
      "direccion": direccion.text,
      
      if (ci.text.trim().isNotEmpty) "ci": ci.text.trim(),
      if (nit.text.trim().isNotEmpty) "nit": nit.text.trim(),
      if (correo.text.trim().isNotEmpty) "correo": correo.text.trim(),

      "searchIndex": _searchIndex(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    final ref = FirebaseFirestore.instance.collection("clientes");

    if (isEdit) {
      await ref.doc(widget.clienteId).update(data);
    } else {
      await ref.add({
        ...data,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    setState(() => loading = false);

    DashboardController.editingClienteId = null;
    DashboardController.goTo(4);
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
      maxWidth = 650;
      padding = const EdgeInsets.all(20);
    } else {
      maxWidth = 750;
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

void _volver() {
    DashboardController.goTo(4);
  }

  Widget _formContent() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
  Text(
              isEdit ? "Editar Cliente" : "Registrar Cliente",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 35),
            ElevatedButton.icon(
        onPressed: _volver,
        icon: const Icon(Icons.arrow_back),
        label: const Text("Regresar", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      ),

            ],),
            const SizedBox(height: 12),

            _section("Datos de la mascota"),
            _field(nombreMascota, "Nombre Mascota"),
            _field(raza, "Raza"),
            _field(color, "Color"),
            _field(especie, "Especie"),
            _field(sexo, "Sexo"),

            const SizedBox(height: 10),

            _section("Datos del dueño"),
            _field(nombreDueno, "Nombre Dueño"),
            _field(telefono, "Teléfono"),
            _field(direccion, "Dirección"),
            _field(ci, "CI (Opcional)", required: false),
            _field(nit, "NIT (Opcional)", required: false),
            _field(marcaTatuaje, "Marca / Tatuaje", required: false),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? "Actualizar Cliente" : "Guardar Cliente",
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 5),
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

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = true,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) {
          if (!required) return null;
          return v == null || v.trim().isEmpty ? "Campo requerido" : null;
        },
        decoration: InputDecoration(
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
}