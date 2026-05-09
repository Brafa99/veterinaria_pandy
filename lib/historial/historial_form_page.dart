import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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
  bool habilitarRadiografia = false;
  final picker = ImagePicker();
  bool agregarRadiografia = false;
  final laboratorioUrl = TextEditingController();
  List<XFile> nuevasImagenes = [];
  List<String> imagenesExistentes = [];
  List<String> linksExistentes = [];

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
  habilitarRadiografia = true;

  if (d == null) return;

  final radiografiaData =
      d["radiografias_laboratorios"] ?? {};

  setState(() {

    descripcion.text =
        (d["descripcion"] ?? "").toString();

    precio.text =
        (d["precioh"] ?? "").toString();

    tipoServicio =
        (d["tipo_historial"] ??
                d["tipo_servicio"] ??
                "")
            .toString();

    tipoPago =
        (d["tipo_pago"] ?? "").toString();

    imagenesExistentes =
        List<String>.from(
      radiografiaData["imagenes"] ?? [],
    );

    linksExistentes =
        List<String>.from(
      radiografiaData["links"] ?? [],
    );

    agregarRadiografia =
        imagenesExistentes.isNotEmpty ||
            linksExistentes.isNotEmpty;
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
    final nuevasUrls =
    await subirImagenes();

final todasLasImagenes = [
  ...imagenesExistentes,
  ...nuevasUrls,
];

final todosLosLinks = [
  ...linksExistentes,
];

if (laboratorioUrl.text.trim().isNotEmpty) {

  todosLosLinks.add(
    laboratorioUrl.text.trim(),
  );
}

    try {
      await FirebaseFirestore.instance
    .collection("historial_v2")
    .doc(widget.historialId)
    .update({

  "descripcion":
      descripcion.text.trim(),

  "precioh":
      double.tryParse(
            precio.text.trim(),
          ) ??
          0,

  "tipo_historial":
      tipoServicio,

  "tipo_pago":
      tipoPago,

  "radiografias_laboratorios": {

    "imagenes":
        todasLasImagenes,

    "links":
        todosLosLinks,
  },

  "updatedAt":
      FieldValue.serverTimestamp(),
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

  Future<void> seleccionarImagenes() async {

  final totalActual =
      imagenesExistentes.length +
      nuevasImagenes.length;

  if (totalActual >= 2) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Máximo 2 imágenes",
        ),
      ),
    );

    return;
  }

  final imgs = await picker.pickMultiImage();

  if (imgs.isEmpty) return;

  final disponibles = 2 - totalActual;

  setState(() {

    nuevasImagenes.addAll(
      imgs.take(disponibles),
    );
  });
}


Future<Uint8List> compressImage(
  XFile file,
) async {

  if (kIsWeb) {

    return await file.readAsBytes();
  }

  final result =
      await FlutterImageCompress.compressWithFile(

    file.path,

    minWidth: 1200,
    quality: 70,
  );

  return Uint8List.fromList(result!);
}


Future<List<String>> subirImagenes() async {

  List<String> urls = [];

  for (final img in nuevasImagenes) {

    try {

      debugPrint("INICIANDO SUBIDA");

      final imageBytes =
          await compressImage(img);

      debugPrint(
        "BYTES OK: ${imageBytes.length}",
      );

      final fileName =
          const Uuid().v4();

      /// ✅ STORAGE NORMAL
      final ref = FirebaseStorage.instance
          .ref()
          .child(
            "historial_v2/${widget.historialId}/$fileName.jpg",
          );

      debugPrint("SUBIENDO...");

      final snapshot =
          await ref.putData(

        imageBytes,

        SettableMetadata(
          contentType: "image/jpeg",
        ),
      );

      debugPrint(
        "SUBIDA OK: ${snapshot.state}",
      );

      final url =
          await ref.getDownloadURL();

      debugPrint("URL OK: $url");

      urls.add(url);

    } catch (e) {

      debugPrint(
        "ERROR SUBIENDO IMAGEN: $e",
      );
    }
  }

  return urls;
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


                  const SizedBox(height: 20),

Container(
  decoration: BoxDecoration(
    color: const Color(0xFFF8FAFD),
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

  child: SwitchListTile(

    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),

    value: agregarRadiografia,

    activeColor: const Color(0xFF0054A6),

    secondary: Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xFF0054A6)
            .withOpacity(0.10),

        borderRadius: BorderRadius.circular(12),
      ),

      child: const Icon(
        Icons.medical_services_outlined,
        color: Color(0xFF0054A6),
      ),
    ),

    title: const Text(
      "Radiografías / Laboratorios",

      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    ),

    subtitle: Padding(
      padding: const EdgeInsets.only(top: 4),

      child: Text(
        agregarRadiografia
            ? "Puedes agregar, reemplazar o eliminar imágenes y enlaces."
            : "Adjunta radiografías, resultados o links externos.",

        style: TextStyle(
          color: Colors.grey.shade700,
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
),

if (agregarRadiografia) ...[

  AnimatedContainer(
  duration: const Duration(milliseconds: 250),

  margin: const EdgeInsets.only(top: 14),

  padding: const EdgeInsets.all(16),

  decoration: BoxDecoration(
    color: Colors.white,

    borderRadius: BorderRadius.circular(16),

    border: Border.all(
      color: Colors.grey.shade300,
    ),
  ),

  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Row(
        children: [

          Icon(
            Icons.folder_open,
            color: Color(0xFF0054A6),
          ),

          SizedBox(width: 8),

          Text(
            "Archivos adjuntos",

            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),

      const SizedBox(height: 18),

      // TODO tu contenido actual aquí
    ],
  ),
),

  const SizedBox(height: 15),

  /// ================= IMÁGENES EXISTENTES =================
  /// ================= IMÁGENES EXISTENTES =================
if (imagenesExistentes.isNotEmpty) ...[

  const Text(
    "Imágenes actuales",
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),

  const SizedBox(height: 10),

  Wrap(
    spacing: 10,
    runSpacing: 10,

    children: imagenesExistentes.map((img) {

      return Stack(
        children: [

          ClipRRect(
  borderRadius: BorderRadius.circular(12),

  child: Image.network(
    img,

    width: 110,
    height: 110,
    fit: BoxFit.cover,

    gaplessPlayback: true,

    // 🔥 CLAVE PARA WEB (esto es lo que te falta)
    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,

    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;

      return const SizedBox(
        width: 110,
        height: 110,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    },

    errorBuilder: (context, error, stackTrace) {
      debugPrint("GRID IMAGE ERROR: $error");

      return Container(
        width: 110,
        height: 110,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image),
      );
    },
  ),
),

          Positioned(
            right: 0,
            top: 0,

            child: InkWell(
              onTap: () {
                setState(() {
                  imagenesExistentes.remove(img);
                });
              },

              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),

                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList(),
  ),

  const SizedBox(height: 20),
],

  /// ================= NUEVAS =================
  ElevatedButton.icon(

    style: ElevatedButton.styleFrom(
      backgroundColor:
          const Color(0xFF0054A6),
    ),

    onPressed: seleccionarImagenes,

    icon: const Icon(
      Icons.image,
      color: Colors.white,
    ),

    label: const Text(
      "Agregar imágenes (Máximo 2)",
      style: TextStyle(
        color: Colors.white,
      ),
    ),
  ),

  const SizedBox(height: 12),

  if (nuevasImagenes.isNotEmpty)

    Wrap(
      spacing: 10,
      runSpacing: 10,

      children:
          nuevasImagenes.map((img) {

        return Container(
          width: 110,
          height: 110,

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(12),

            image: DecorationImage(

              image: kIsWeb
                  ? NetworkImage(img.path)
                  : FileImage(
                      File(img.path),
                    ) as ImageProvider,

              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    ),

  const SizedBox(height: 20),

  /// ================= LINKS =================
  if (linksExistentes.isNotEmpty) ...[

    const Text(
      "Links actuales",
      style: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 10),

    ...linksExistentes.map((link) {

      return Card(

        child: ListTile(

          leading:
              const Icon(Icons.link),

          title: Text(
            link,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
          ),

          trailing: IconButton(

            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),

            onPressed: () {

              setState(() {

                linksExistentes
                    .remove(link);
              });
            },
          ),
        ),
      );
    }),
  ],

  const SizedBox(height: 15),

  TextFormField(
    controller: laboratorioUrl,

    decoration: const InputDecoration(
      labelText:
          "Nuevo link laboratorio",
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.link),
    ),
  ),
],

    const SizedBox(height: 20),


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