import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';

class HistorialCreatePage extends StatefulWidget {
  const HistorialCreatePage({super.key});

  @override
  State<HistorialCreatePage> createState() => _HistorialCreatePageState();
}

class _HistorialCreatePageState extends State<HistorialCreatePage> {
  final formKey = GlobalKey<FormState>();

  final descripcion = TextEditingController();
  final precio = TextEditingController();

  bool loading = false;

  String tipoServicio = "";
  
  String tipoPago = "";

  String previewId = ""; // 🔥 ID visual

  @override
  void initState() {
    super.initState();

    // 🔥 generar ID visual (como referencia)
    previewId =
        FirebaseFirestore.instance.collection("historial_v2").doc().id;
  }

  // ================= CHIP =================
  Widget optionChip({
    required String label,
    required String value,
    required String group,
    required Function(String) onSelected,
  }) {
    final selected = group == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: Color(0xFF0054A6),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black,
      ),
    );
  }

  // ================= GUARDAR =================
  Future<void> guardar() async {
    if (!formKey.currentState!.validate()) return;

    if (tipoServicio.isEmpty || tipoPago.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa servicio y pago")),
      );
      return;
    }

    final ctx = DashboardController.selectedHistorial ?? {};
    final idCliente = ctx["id_cliente"];

    if (idCliente == null) return;

    setState(() => loading = true);
    debugPrint("CTX COMPLETO:");
     debugPrint(ctx.toString());

    try {
      await FirebaseFirestore.instance
          .collection("historial_v2")
          .doc(previewId) // 🔥 usamos el ID generado
          .set({
  "id_cliente": idCliente,

  "nombre_mascota": ctx["nombre_mascota"] ?? "",
  "nombre_dueno": ctx["nombre_dueno"] ?? "",

  // 🔥 AGREGA ESTO
  "raza": ctx["raza"] ?? "",
  "color": ctx["color"] ?? "",
  "especie": ctx["especie"] ?? "",
  "sexo": ctx["sexo"] ?? "",
  "telefono": ctx["telefono"] ?? "",
  "direccion": ctx["direccion"] ?? "",
  "ci": ctx["ci"] ?? "",
  "marca": ctx["marca"] ?? "",

  // REGISTRO
  "descripcion": descripcion.text.trim(),
  "tipo_historial": tipoServicio,
  "precioh": double.tryParse(precio.text.trim()) ?? 0,
  "tipo_pago": tipoPago,

  "fecha_registro": FieldValue.serverTimestamp(),
  "createdAt": FieldValue.serverTimestamp(),
});

      // ================= REGISTRAR INGRESO =================
final monto = double.tryParse(precio.text.trim()) ?? 0;

if (monto > 0) {
  await FirebaseFirestore.instance
      .collection("ingresos")
      .add({
    "monto": monto,
    "fecha": FieldValue.serverTimestamp(),

    // 🔥 metadata útil (muy recomendable)
    "origen": "historial",
    "id_historial": previewId,
    "id_cliente": idCliente,
    "tipo_pago": tipoPago,
    "descripcion": descripcion.text.trim(),

    "createdAt": FieldValue.serverTimestamp(),
  });
}

      DashboardController.goTo(9); // 🔥 volver a detalle

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final ctx = DashboardController.selectedHistorial ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("AGREGAR REGISTRO"),
       

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => DashboardController.goTo(9),
        ),
      ),

      body: Center(
        child: Container(
  width: MediaQuery.of(context).size.width < 800 ? double.infinity : 750,
  padding: EdgeInsets.all(
    MediaQuery.of(context).size.width < 600 ? 12 : 20,
  ),
          child: Form(
            key: formKey,

            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ================= ID HISTORIAL =================
                  const Text(
                    "ID HISTORIAL",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  TextFormField(
                    initialValue: previewId,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ================= PACIENTE =================
                  Text(
                    "Paciente: ${ctx["nombre_mascota"] ?? ""}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Dueño: ${ctx["nombre_dueno"] ?? ""}"),

                  const SizedBox(height: 20),

                  // ================= SERVICIO =================
                  const Text(
                    "Tipo de Servicio",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10,
                    children: [
                      optionChip(
                        label: "Consulta Médica",
                        value: "Consulta Medica",
                        group: tipoServicio,
                        onSelected: (v) => setState(() => tipoServicio = v),
                      ),
                      optionChip(
                        label: "Peluquería",
                        value: "Peluqueria",
                        group: tipoServicio,
                        onSelected: (v) => setState(() => tipoServicio = v),
                      ),
                      optionChip(
                        label: "Otros",
                        value: "otro",
                        group: tipoServicio,
                        onSelected: (v) => setState(() => tipoServicio = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ================= INPUTS =================
                  _inputsResponsive(),
                  
                  const SizedBox(height: 20),

                  // ================= PAGO =================
                  const Text(
                    "Tipo de Pago",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10,
                    children: [
                      optionChip(
                        label: "Efectivo",
                        value: "Efectivo",
                        group: tipoPago,
                        onSelected: (v) => setState(() => tipoPago = v),
                      ),
                      optionChip(
                        label: "QR",
                        value: "QR",
                        group: tipoPago,
                        onSelected: (v) => setState(() => tipoPago = v),
                      ),
                      optionChip(
                        label: "Tarjeta",
                        value: "Tarjeta",
                        group: tipoPago,
                        onSelected: (v) => setState(() => tipoPago = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ================= BOTÓN =================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0054A6),
                      ),
                      child: Text("Registrar",style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _inputsResponsive() {
  final isMobile = MediaQuery.of(context).size.width < 700;

  if (isMobile) {
    return Column(
      children: [
        TextFormField(
          controller: descripcion,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Descripción",
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? "Requerido" : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: precio,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Precio",
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? "Requerido" : null,
        ),
      ],
    );
  }

  return Row(
    children: [
      Expanded(
        flex: 3,
        child: TextFormField(
          controller: descripcion,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: "Descripción",
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? "Requerido" : null,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 1,
        child: TextFormField(
          controller: precio,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Precio",
            border: OutlineInputBorder(),
          ),
          validator: (v) => v!.isEmpty ? "Requerido" : null,
        ),
      ),
    ],
  );
}
}