import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final int limit = 30;

  List<DocumentSnapshot> docs = [];

  bool loading = false;
  bool hasMore = true;
  bool generatingPdf = false;
  bool isSearching = false;
  double progress = 0;
  bool generatingDownload = false;
  bool generatingPrint = false;
  final scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchInitial();

    scrollController.addListener(() {
      if (!isSearching &&
          scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200) {
        fetchMore();
      }
    });
  }

  @override
void dispose() {
  scrollController.dispose();
  _debounce?.cancel();
  super.dispose();
}

  // ================= NORMAL LIST =================
  Future<void> fetchInitial() async {
    setState(() => loading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection("clientes")
        .orderBy(FieldPath.documentId)
        .limit(limit)
        .get();

    docs = snapshot.docs;
    hasMore = docs.length == limit;

    setState(() => loading = false);
  }

  Future<void> fetchMore() async {
    if (!hasMore || loading || isSearching) return;

    setState(() => loading = true);

    final last = docs.last;

    final snapshot = await FirebaseFirestore.instance
        .collection("clientes")
        .orderBy(FieldPath.documentId)
        .startAfterDocument(last)
        .limit(limit)
        .get();

    if (snapshot.docs.isNotEmpty) {
      docs.addAll(snapshot.docs);
    }

    hasMore = snapshot.docs.length == limit;

    setState(() => loading = false);
  }

  void search(String value) {
  _debounce?.cancel();

  _debounce = Timer(const Duration(milliseconds: 400), () async {
    final text = value.toLowerCase().trim();

    if (text.isEmpty) {
      setState(() {
        isSearching = false;
      });
      fetchInitial();
      return;
    }

    setState(() {
      loading = true;
      isSearching = true;
    });

    try {
      List<DocumentSnapshot> baseDocs;

      // 🔥 CLAVE: si texto corto → NO usar Firestore
      if (text.length < 4) {
        baseDocs = docs; // usa lo ya cargado
      } else {
        final first = text.split(" ").first;

        final snapshot = await FirebaseFirestore.instance
            .collection("clientes")
            .where("searchIndex", arrayContains: first)
            .limit(200)
            .get();

        baseDocs = snapshot.docs;
      }

      final words = text.split(" ");

      final filtered = baseDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final index = List<String>.from(data["searchIndex"] ?? []);

        return words.every((w) =>
            index.any((item) => item.contains(w)));
      }).toList();

      setState(() {
        docs = filtered;
        loading = false;
      });

    } catch (e) {
      print("ERROR SEARCH: $e");
      setState(() => loading = false);
    }
  });
}

String normalize(String text) {
  return text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll("á", "a")
      .replaceAll("é", "e")
      .replaceAll("í", "i")
      .replaceAll("ó", "o")
      .replaceAll("ú", "u");
}

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              onChanged: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Buscar cliente...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),
            _header(context),
            const SizedBox(height: 15),

            

            Expanded(
              child: loading && docs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : isMobile
                      ? ListView.builder(
                          controller: scrollController,
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d =
                                docs[i].data() as Map<String, dynamic>;
                            return _card(context, docs[i].id, d);
                          },
                        )
                      : _table(context),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 800;

  final buttons = [
    ElevatedButton.icon(
      onPressed: generatingDownload
          ? null
          : () async {
              setState(() => generatingDownload = true);

              try {
                final clientes = await getAllClientes();

                final bytes =
                    await PdfService.generateClientesPdfBytes(clientes);

                await _downloadPdf(bytes);

              } catch (e) {
                debugPrint("ERROR: $e");
              }

              setState(() => generatingDownload = false);
            },
      icon: generatingDownload
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      label: Text("Descargar",style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
    ),

    ElevatedButton.icon(
      onPressed: (generatingDownload || generatingPrint)
          ? null
          : () async {
              setState(() => generatingPrint = true);

              try {
                final clientes = await getAllClientes();
                await PdfService.generateClientesPdf(clientes);
              } catch (e) {
                debugPrint("ERROR: $e");
              }

              setState(() => generatingPrint = false);
            },
      icon: generatingPrint
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.print),
      label: Text("Imprimir", style: TextStyle(color: Colors.white),),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    ),

    ElevatedButton.icon(
      onPressed: () {
        DashboardController.editingClienteId = null;
        DashboardController.goTo(5);
      },
      icon: const Icon(Icons.add),
      label: const Text("Registrar"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
    ),
  ];

  return isMobile
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "LISTA DE CLIENTES",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: buttons,
            ),
          ],
        )
      : Row(
          children: [
            const Text(
              "LISTA DE CLIENTES",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ...buttons.map((b) => Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: b,
                )),
          ],
        );
}

 Future<void> _downloadPdf(Uint8List bytes) async {
  final fileName =
      "clientes_${DateTime.now().millisecondsSinceEpoch}.pdf";

  await FileService.saveOrDownload(bytes, fileName);
}

  Future<List<Map<String, dynamic>>> getAllClientes() async {
  List<Map<String, dynamic>> all = [];

  Query query = FirebaseFirestore.instance
      .collection("clientes")
      .orderBy(FieldPath.documentId)
      .limit(400); // 🔥 ajustable

  QuerySnapshot snapshot = await query.get();

  while (snapshot.docs.isNotEmpty) {
    all.addAll(snapshot.docs.map((e) => e.data() as Map<String, dynamic>));

    final last = snapshot.docs.last;

    snapshot = await FirebaseFirestore.instance
        .collection("clientes")
        .orderBy(FieldPath.documentId)
        .startAfterDocument(last)
        .limit(400)
        .get();

    // 🔥 CLAVE: liberar UI
    await Future.delayed(const Duration(milliseconds: 50));
  }

  return all;
}
  
 Widget _table(BuildContext context) {
  final visible = docs.take(300).toList();

  return ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      scrollbars: true,
      dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
      },
    ),
    child: SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Card(
            elevation: 3,
            child: DataTable(
              columnSpacing: 18,
              dataRowHeight: 55,
              border: TableBorder.all(
                color: Colors.grey.shade600,
                width: 1.5,
              ),

                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),

                    columns: const [
                      DataColumn(label: Text("#")),
                      DataColumn(label: Text("Mascota")),
                      DataColumn(label: Text("Raza")),
                      DataColumn(label: Text("Color")),
                      DataColumn(label: Text("Especie")),
                      DataColumn(label: Text("Sexo")),
                      DataColumn(label: Text("Dueño")),
                      DataColumn(label: Text("Teléfono")),
                      DataColumn(label: Text("Dirección")),
                      DataColumn(label: Text("CI")),
                      // DataColumn(label: Text("Correo")),
                      DataColumn(label: Text("Marca/Tatuaje")),
                      DataColumn(label: Text("Acciones")),
                    ],

                    rows: List.generate(visible.length, (i) {
                      final d = visible[i].data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(Text("${i + 1}")),
                          DataCell(Text(d["nombre_mascota"] ?? "")),
                          DataCell(Text(d["raza"] ?? "")),
                          DataCell(Text(d["color"] ?? "")),
                          DataCell(Text(d["especie"] ?? "")),
                          DataCell(Text(d["sexo"] ?? "")),
                          DataCell(Text(d["nombre"] ?? "")),
                          DataCell(Text(d["telefono"] ?? "")),
                          DataCell(Text(d["direccion"] ?? "")),
                          DataCell(Text(d["ci"] ?? "")),
                          // DataCell(Text(d["correo"] ?? "")),
                          DataCell(Text(
  (d["marca_tatuaje"] == null || d["marca_tatuaje"] == "")
      ? "No tiene"
      : d["marca_tatuaje"],
)),
                          DataCell(_actions(context, docs[i].id)),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      }
  }

  // ================= MOBILE =================
 Widget _card(BuildContext context, String id, Map d) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),

      title: Text(
        "${d["nombre"]} (${d["nombre_mascota"]})",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tel: ${d["telefono"] ?? "-"}"),
          Text("Raza: ${d["raza"] ?? "-"}"),
        ],
      ),

      trailing: _actions(context, id),
    ),
  );
}

  // ================= ACTIONS =================
  Widget _actions(BuildContext context, String id) {
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
            DashboardController.editingClienteId = id;
            DashboardController.goTo(6);
          },
        ),
        IconButton(
  icon: const Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar cliente"),
        content: const Text(
          "¿Seguro que deseas eliminar este cliente?\n\nEsta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
  try {
    await FirebaseFirestore.instance
        .collection("clientes")
        .doc(id)
        .delete();


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cliente eliminado correctamente"),
        backgroundColor: Colors.green,
      ),
    );
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error al eliminar: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}
  },
)
      ],
    );
  }


Future<Uint8List> buildClientesPdf(List<Map<String, dynamic>> clientes) async {
  final pdf = pw.Document();

  const chunkSize = 200;

  for (int i = 0; i < clientes.length; i += chunkSize) {
    final chunk = clientes.skip(i).take(chunkSize).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text("Clientes ${i + 1} - ${i + chunk.length}"),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: ["#", "Mascota", "Dueño", "Teléfono"],
            data: List.generate(chunk.length, (j) {
              final c = chunk[j];
              return [
                "${i + j + 1}",
                c["nombre_mascota"] ?? "",
                c["nombre"] ?? "",
                c["telefono"] ?? "",
              ];
            }),
          ),
        ],
      ),
    );
  }

  return pdf.save();
}
