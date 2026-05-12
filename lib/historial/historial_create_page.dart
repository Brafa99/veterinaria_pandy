import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

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

  String previewId = "";
  String clientId = "";
  bool agregarRadiografia = false;

final laboratorioUrl = TextEditingController();

List<PlatformFile> pdfsSeleccionados = [];

  @override
  void initState() {
    super.initState();
    final ctx = DashboardController.selectedHistorial ?? {};
    final idCliente = ctx["id_cliente"];
    debugPrint(idCliente);

    // 🔥 generar ID visual (como referencia)
    previewId = FirebaseFirestore.instance
    .collection("historial_v2")
    .doc()
    .id;

  clientId = idCliente;

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

  Future<void> seleccionarPDFs() async {

  final disponibles = 5 - pdfsSeleccionados.length;

  if (disponibles <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Máximo 5 PDFs"),
      ),
    );
    return;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    allowMultiple: true,
    withData: true,
  );

  if (result == null) return;

  final files = result.files.take(disponibles);

  setState(() {
    pdfsSeleccionados.addAll(files);
  });
}


Future<List<Map<String, dynamic>>> subirPDFs(
  String historialId,
) async {

  List<Map<String, dynamic>> archivos = [];

  for (final pdf in pdfsSeleccionados) {

    if (pdf.bytes == null) continue;

    final fileName =
        "${const Uuid().v4()}.pdf";

    final ref = FirebaseStorage.instance
        .ref()
        .child(
          "historial_v2/$historialId/$fileName",
        );

    await ref.putData(

      pdf.bytes!,

      SettableMetadata(
        contentType: "application/pdf",
      ),
    );

    final url =
        await ref.getDownloadURL();

    archivos.add({
      "nombre": pdf.name,
      "url": url,
    });
  }

  return archivos;
}

  Future<void> guardar() async {

  if (!formKey.currentState!.validate()) return;

  if (tipoServicio.isEmpty || tipoPago.isEmpty) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Completa servicio y pago"),
      ),
    );

    return;
  }

  final ctx =
      DashboardController.selectedHistorial ?? {};

  final idCliente =
      ctx["id_cliente"];

  if (idCliente == null) return;

  setState(() => loading = true);

  try {

    /// ================= PDFs =================
    List<Map<String, dynamic>> archivosPdf = [];

    if (agregarRadiografia &&
        pdfsSeleccionados.isNotEmpty) {

      archivosPdf =
          await subirPDFs(previewId);
    }

    /// ================= LINKS =================
    final List<String> links = [];

    if (laboratorioUrl.text
        .trim()
        .isNotEmpty) {

      links.add(
        laboratorioUrl.text.trim(),
      );
    }

    /// ================= FIRESTORE =================
    await FirebaseFirestore.instance
        .collection("historial_v2")
        .doc(previewId)
        .set({

      "id_cliente": idCliente,

      "nombre_mascota":
          ctx["nombre_mascota"] ?? "",

      "nombre_dueno":
          ctx["nombre"] ?? "",

      "raza":
          ctx["raza"] ?? "",

      "color":
          ctx["color"] ?? "",

      "especie":
          ctx["especie"] ?? "",

      "sexo":
          ctx["sexo"] ?? "",

      "telefono":
          ctx["telefono"] ?? "",

      "direccion":
          ctx["direccion"] ?? "",

      "ci":
          ctx["ci"] ?? "",

      "marca":
          ctx["marca"] ?? "",

      "descripcion":
          descripcion.text.trim(),

      "tipo_historial":
          tipoServicio,

      "precioh":
          double.tryParse(
                precio.text.trim(),
              ) ??
              0,

      "tipo_pago":
          tipoPago,

      "fecha_registro":
          FieldValue.serverTimestamp(),

      "createdAt":
          FieldValue.serverTimestamp(),

      /// ================= COMPATIBLE =================
      "radiografias_laboratorios": {

        /// NUEVO
        "archivos":
            archivosPdf,

        /// VIEJO (compatibilidad)
        "imagenes": [],

        /// VIEJO
        "links":
            links,

        /// OPCIONAL
        "updatedAt":
            FieldValue.serverTimestamp(),
      },

    }, SetOptions(merge: true));

    /// ================= INGRESOS =================
    final monto =
        double.tryParse(
          precio.text.trim(),
        ) ??
        0;

    if (monto > 0) {

      await FirebaseFirestore.instance
          .collection("ingresos")
          .add({

        "monto": monto,

        "fecha":
            FieldValue.serverTimestamp(),

        "origen":
            "historial",

        "id_historial":
            previewId,

        "id_cliente":
            idCliente,

        "tipo_pago":
            tipoPago,

        "descripcion":
            descripcion.text.trim(),

        "createdAt":
            FieldValue.serverTimestamp(),
      });
    }

    DashboardController.goTo(9);

  } catch (e) {

    debugPrint(
      "ERROR GUARDAR HISTORIAL: $e",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error al guardar"),
      ),
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
                    "ID CLIENTE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  TextFormField(
                    initialValue: clientId,
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
                  Text("Propietario: ${ctx["nombre_dueno"] ?? ctx["nombre"] ?? ""}"),

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
                  const SizedBox(height: 20),



Container(
  margin: const EdgeInsets.symmetric(vertical: 10),

  decoration: BoxDecoration(
    color: const Color(0xFFF7FAFD),
    borderRadius: BorderRadius.circular(16),

    border: Border.all(
      color: agregarRadiografia
          ? const Color(0xFF0054A6)
          : Colors.grey.shade300,
      width: 1.4,
    ),

    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  ),

  child: Column(
    children: [

      SwitchListTile(

        value: agregarRadiografia,

        activeColor: const Color(0xFF0054A6),

        secondary: Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: const Color(0xFF0054A6)
                .withOpacity(0.10),

            borderRadius:
                BorderRadius.circular(12),
          ),

          child: const Icon(
            Icons.medical_information_outlined,
            color: Color(0xFF0054A6),
          ),
        ),

        title: const Text(
          "Radiografías/Laboratorios",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),

        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            "Adjunta imágenes médicas o enlaces externos del laboratorio",
            style: TextStyle(
              height: 1.3,
            ),
          ),
        ),

        onChanged: (v) {
          setState(() {
            agregarRadiografia = v;
          });
        },
      ),

      /// CONTENIDO
      AnimatedCrossFade(

        duration:
            const Duration(milliseconds: 250),

        crossFadeState: agregarRadiografia
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,

        firstChild: Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),

          child: Column(
            children: [

              const Divider(),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF0054A6),

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 14,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: seleccionarPDFs,

                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                  ),

                  label: const Text(
                    "Seleccionar PDF",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              if (pdfsSeleccionados.isNotEmpty)
  Column(
    children: pdfsSeleccionados.map((pdf) {

      return Container(
        margin: const EdgeInsets.only(bottom: 10),

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),

        child: Row(
          children: [

            const Icon(
              Icons.picture_as_pdf,
              color: Colors.red,
              size: 34,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                pdf.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            IconButton(
              onPressed: () {

                setState(() {
                  pdfsSeleccionados.remove(pdf);
                });
              },

              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );

    }).toList(),
  ),
              
              const SizedBox(height: 16),

              TextFormField(
                controller: laboratorioUrl,

                decoration: InputDecoration(
                  labelText:
                      "Link laboratorio/radiografía",

                  prefixIcon:
                      const Icon(Icons.link),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),

        secondChild: const SizedBox.shrink(),
      ),
    ],
  ),
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