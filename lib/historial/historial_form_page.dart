import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';

class HistorialFormPage extends StatefulWidget {
  final String historialId;

  const HistorialFormPage({super.key, required this.historialId});

  @override
  State<HistorialFormPage> createState() => _HistorialFormPageState();
}

class _HistorialFormPageState extends State<HistorialFormPage> {
  final formKey = GlobalKey<FormState>();

  final descripcion = TextEditingController();
  final precio = TextEditingController();

  bool loading = false;

  String tipoServicio = "";
  String tipoPago = "";

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ================= LOAD =================
  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection("historial_v2")
        .doc(widget.historialId)
        .get();

    final d = doc.data();
    if (d == null) return;

    setState(() {
      descripcion.text = (d["descripcion"] ?? "").toString();
      precio.text = (d["precioh"] ?? "").toString();

      // 🔥 IMPORTANTE (compatibilidad)
      tipoServicio =
          (d["tipo_historial"] ?? d["tipo_servicio"] ?? "").toString();

      tipoPago = (d["tipo_pago"] ?? "").toString();
    });
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

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection("historial_v2")
          .doc(widget.historialId)
          .update({
        "descripcion": descripcion.text.trim(),
        "precioh": double.tryParse(precio.text.trim()) ?? 0,

        // 🔥 UNIFICAMOS NOMBRE
        "tipo_historial": tipoServicio,
        "tipo_pago": tipoPago,

        "updatedAt": FieldValue.serverTimestamp(),
      });

      DashboardController.goTo(9);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= CHIP SELECTOR =================
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MODIFICAR HISTORIAL"),
        backgroundColor: Color(0xFF0054A6),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => DashboardController.goTo(9),
        ),
      ),

      body: Center(
        child: Container(
  width: MediaQuery.of(context).size.width < 800 ? double.infinity : 750,
  padding: EdgeInsets.all(
  MediaQuery.of(context).size.width < 600 ? 10 : 20,
),

          child: Form(
            key: formKey,

            child: SingleChildScrollView( // 🔥 SOLUCION SCROLL
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ================= SERVICIO =================
                  const Text(
                    "Tipo de Servicio",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
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
                    ],
                  ),

                  const SizedBox(height: 15),

                  // ================= PAGO =================
                  const Text(
                    "Tipo de Pago",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
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

                  const SizedBox(height: 20),

                  // ================= INPUTS EN FILA =================
                  _inputsResponsive(),

                  const SizedBox(height: 25),

                  // ================= BOTÓN =================
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
    : const Text(
        "Guardar cambios",
        style: TextStyle(color: Colors.white),
      
                        
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
            labelText: "Antecedente / Diagnóstico",
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
          validator: (v) {
            if (v == null || v.isEmpty) return "Requerido";
            if (double.tryParse(v) == null) return "Número inválido";
            return null;
          },
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
            labelText: "Antecedente / Diagnóstico",
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
          validator: (v) {
            if (v == null || v.isEmpty) return "Requerido";
            if (double.tryParse(v) == null) return "Número inválido";
            return null;
          },
        ),
      ),
    ],
  );
}
}