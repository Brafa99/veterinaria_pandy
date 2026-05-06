import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GaleriaView extends StatefulWidget {
  const GaleriaView({super.key});

  @override
  State<GaleriaView> createState() => _GaleriaViewState();
}

class _GaleriaViewState extends State<GaleriaView> {
  String? image1;
  String? image2;

  bool loading = true;
  bool saving = false;

  final picker = ImagePicker();

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
      image1 = d["imagen_galeria1"];
      image2 = d["imagen_galeria2"];
    }

    setState(() => loading = false);
  }

  /// ================= SAVE =================
  Future<void> save() async {
    setState(() => saving = true);

    await FirebaseFirestore.instance
        .collection("configuracion")
        .doc("1")
        .update({
      "imagen_galeria1": image1,
      "imagen_galeria2": image2,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Galería actualizada")),
    );
  }

  /// ================= PICK IMAGE =================
  Future<void> pickImage(int index) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Cámara"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Galería"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final file = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (file == null) return;

    final bytes = await file.readAsBytes();
    final base64 = base64Encode(bytes);

    setState(() {
      if (index == 1) {
        image1 = base64;
      } else {
        image2 = base64;
      }
    });
  }

  /// ================= IMAGE BUILDER =================
  Widget buildImage(String? data) {
    if (data == null || data.isEmpty) {
      return Image.asset("assets/img/pet1.jpeg.jpg", fit: BoxFit.cover);
    }

    // Detectar base64
    if (data.length > 100) {
      try {
        Uint8List bytes = base64Decode(data);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Image.asset("assets/img/pet1.jpg");
      }
    }

    // Asset antiguo
    return Image.asset("assets/img/$data", fit: BoxFit.cover);
  }

  Widget imageCard(String title, String? data, int index) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          GestureDetector(
            onTap: () => pickImage(index),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: buildImage(data),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: const Text(
              "Tap para cambiar imagen",
              style: TextStyle(fontSize: 14, color: Colors.black,),
            ),
          ),
        ],
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
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Configuración de Galería",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        imageCard("Galería 1", image1, 1),
                        const SizedBox(width: 15),
                        imageCard("Galería 2", image2, 2),
                      ],
                    ),

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
    );
  }
}