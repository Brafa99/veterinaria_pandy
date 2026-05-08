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
  final int limit = 35;

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
  List<Map<String, dynamic>> searchResults = [];
List<Map<String, dynamic>> allClientes = [];
bool searchCacheReady = false;
bool searchReady = false;
final horizontalController = ScrollController();
final verticalController = ScrollController();

List<Map<String, dynamic>> get _docsMapped =>
    docs.map((e) {
      final d = e.data() as Map<String, dynamic>;
      return {
        ...d,
        "id": e.id,
      };
    }).toList();

List<Map<String, dynamic>> get currentData =>
    isSearching ? searchResults : _docsMapped;
    

  @override
void initState() {
  super.initState();

  loadSearchCache();
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
  horizontalController.dispose();
verticalController.dispose();
  super.dispose();
}

void onSearchChanged(String value) {
  _debounce?.cancel();

  _debounce = Timer(const Duration(milliseconds: 400), () {
    search(value);
  });
}


Future<void> loadSearchCache() async {
  final snap = await FirebaseFirestore.instance
      .collection("clientes")
      .get();

  allClientes = snap.docs.map((e) {
    final d = e.data();

    return {
      "id": e.id,
      "id_cliente": d["id_cliente"],
      "nombre_mascota": d["nombre_mascota"] ?? "",
      "nombre": d["nombre"] ?? "",
      "telefono": d["telefono"] ?? "",
      "dni": d["ci"] ?? "",
      "nit": d["nit"] ?? "",
      "raza": d["raza"] ?? "",
      "color": d["color"] ?? "",
      "especie": d["especie"] ?? "",
      "sexo": d["sexo"] ?? "",
      "direccion": d["direccion"] ?? "",
    };
  }).toList();

  searchReady = true;
  setState(() {});
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

  Future<void> search(String value) async {
  _debounce?.cancel();

  _debounce = Timer(const Duration(milliseconds: 350), () async {
    // 1. Limpiamos y normalizamos la entrada del usuario
    final input = value.trim().toLowerCase();

    if (input.isEmpty) {
      setState(() {
        isSearching = false;
        searchResults = [];
      });
      return;
    }

    if (!searchReady) return;

    setState(() {
      isSearching = true;
    });

    // 2. Dividimos la búsqueda en términos individuales (ej: ["mia", "murillo"])
    final searchTerms = input.split(RegExp(r'\s+'));

    final filtered = allClientes.where((c) {
      // 3. Creamos el bloque de texto donde buscaremos
      // Usamos los campos del mapa 'c' asegurándonos de que coincidan con tu caché
      final combinedData = [
        (c["nombre"] ?? ""),
        (c["id_cliente"] ?? ""),
        (c["nombre_mascota"] ?? ""),
        (c["telefono"] ?? ""),
        (c["dni"] ?? c["ci"] ?? ""), // Soporta ambos nombres de campo por si acaso
        (c["nit"] ?? ""),
      ].join(" ").toLowerCase();

      // 4. Lógica Multi-término: ¿Están todas las palabras escritas en alguna parte del registro?
      return searchTerms.every((term) => combinedData.contains(term));
      
    }).take(200).toList();

    setState(() {
      searchResults = filtered;
    });
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
      .replaceAll("ú", "u")
      .replaceAll("ñ", "n");
}

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
final list = currentData;
    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              onChanged: onSearchChanged,
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
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final d = list[i];
                            return _card(context, d["id"] ?? "", d);
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
      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF0054A6)),
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
  final visible = currentData;

  return ScrollConfiguration(
    behavior: const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
      },
    ),

    child: Scrollbar(
      controller: verticalController,
      thumbVisibility: true,
      interactive: true,

      child: Scrollbar(
        controller: horizontalController,
        thumbVisibility: true,
        interactive: true,
        notificationPredicate: (notification) {
          return notification.metrics.axis == Axis.horizontal;
        },

        child: SingleChildScrollView(
          controller: horizontalController,
          scrollDirection: Axis.horizontal,

          child: SizedBox(
            width: 2200,

            child: SingleChildScrollView(
              controller: verticalController,
              scrollDirection: Axis.vertical,

             child: Card(
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),

  child: DataTable(

    /// 🔥 BORDES MÁS VISIBLES
    border: TableBorder.all(
      color: Colors.grey.shade300,
      width: 1,
      borderRadius: BorderRadius.circular(12),
    ),

    dividerThickness: 0.8,

    headingRowColor: MaterialStateProperty.all(
      const Color(0xFFF1F3F6),
    ),

    dataRowColor:
        MaterialStateProperty.resolveWith<Color?>(
      (states) {
        return Colors.white;
      },
    ),

    headingTextStyle: const TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.bold,
      fontSize: 13.5,
    ),

    dataTextStyle: const TextStyle(
      color: Colors.black87,
      fontSize: 13,
    ),

    columnSpacing: 20,
    horizontalMargin: 14,

    /// 🔥 MÁS ESPACIO VERTICAL
    dataRowMinHeight: 58,
    dataRowMaxHeight: 70,

    columns: const [

      DataColumn(
        label: Text("#"),
      ),

      DataColumn(
        label: Text("ID Cliente"),
      ),

      DataColumn(
        label: Text("Mascota"),
      ),

      DataColumn(
        label: Text("Raza"),
      ),

      DataColumn(
        label: Text("Color"),
      ),

      DataColumn(
        label: Text("Especie"),
      ),

      DataColumn(
        label: Text("Sexo"),
      ),

      DataColumn(
        label: Text("Propietario"),
      ),

      DataColumn(
        label: Text("Teléfono"),
      ),

      DataColumn(
        label: Text("Dirección"),
      ),

      DataColumn(
        label: Text("CI"),
      ),

      DataColumn(
        label: Text("NIT"),
      ),

      DataColumn(
        label: Text("Marca/Tatuaje"),
      ),

      DataColumn(
        label: Text("Acciones"),
      ),
    ],

    rows: List.generate(visible.length, (i) {

      final d = visible[i];

      /// 🔥 CELDAS CONTROLADAS
      Widget cell(
        String text, {
        double width = 120,
      }) {
        return SizedBox(
          width: width,
          child: SelectableText(
            text,
            maxLines: 2,
          ),
        );
      }

      return DataRow(

        color:
            MaterialStateProperty.resolveWith<Color?>(
          (states) {
            if (i.isEven) {
              return Colors.grey.shade50;
            }
            return Colors.white;
          },
        ),

        cells: [

          DataCell(
            SelectableText("${i + 1}"),
          ),

          /// 🔥 ID CLIENTE
          DataCell(
            cell(
              "${d["id_cliente"] ?? ""}",
              width: 90,
            ),
          ),

          DataCell(
            cell(
              d["nombre_mascota"] ?? "",
              width: 140,
            ),
          ),

          DataCell(
            cell(
              d["raza"] ?? "",
              width: 120,
            ),
          ),

          DataCell(
            cell(
              d["color"] ?? "",
              width: 100,
            ),
          ),

          DataCell(
            cell(
              d["especie"] ?? "",
              width: 110,
            ),
          ),

          DataCell(
            cell(
              d["sexo"] ?? "",
              width: 90,
            ),
          ),

          DataCell(
            cell(
              d["nombre"] ?? "",
              width: 180,
            ),
          ),

          DataCell(
            cell(
              d["telefono"] ?? "",
              width: 120,
            ),
          ),

          DataCell(
            cell(
              d["direccion"] ?? "",
              width: 200,
            ),
          ),

          DataCell(
            cell(
              d["dni"] ?? "",
              width: 110,
            ),
          ),

          DataCell(
            cell(
              d["nit"] ?? "",
              width: 110,
            ),
          ),

          DataCell(
            cell(
              (d["marca_tatuaje"] == null ||
                      d["marca_tatuaje"] == "")
                  ? "No tiene"
                  : d["marca_tatuaje"],
              width: 150,
            ),
          ),

          DataCell(
            SizedBox(
              width: 180,
              child: _actions(
                context,
                visible[i]["id"] ?? "",
              ),
            ),
          ),
        ],
      );
    }),
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
          icon: const Icon(Icons.edit, color: Color(0xFF0054A6)),
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
