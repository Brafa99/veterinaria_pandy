import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  bool loading = true;
  bool generatingDownload = false;
  bool generatingPrint = false;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  Timer? _debounce;
  double pdfProgress = 0;
  List<Map<String, dynamic>> historial = [];
  Map<String, Map<String, dynamic>> clientesMap = {};
  DocumentSnapshot? lastDoc;
  bool hasMore = true;
  bool loadingMore = false;
List searchResults = [];

bool isSearching = false;
  

  String safe(dynamic v) =>
      (v == null || v.toString().trim().isEmpty) ? "" : v.toString();
  

  Future<void> _load() async {
  setState(() {
    loading = true;
    historial.clear();
    lastDoc = null;
    hasMore = true;
  });

  final snap = await FirebaseFirestore.instance
      .collection("clientes")
      .orderBy("nombre")
      .orderBy("nombre_mascota")
      .limit(50)
      .get();

  if (snap.docs.isNotEmpty) {
    lastDoc = snap.docs.last;
  }

  historial = snap.docs.map((doc) => doc.data()).toList();

  setState(() => loading = false);
}

  Future<void> loadMore() async {
  if (isSearching) return; // 🔥 CLAVE

  if (!hasMore || loadingMore || lastDoc == null) return;

  setState(() => loadingMore = true);

  final snap = await FirebaseFirestore.instance
      .collection("clientes")
      .orderBy("nombre")
      .orderBy("nombre_mascota")
      .startAfterDocument(lastDoc!)
      .limit(50)
      .get();

  if (snap.docs.isNotEmpty) {
    lastDoc = snap.docs.last;
  }

  historial.addAll(snap.docs.map((doc) => doc.data()));

  if (snap.docs.length < 50) hasMore = false;

  setState(() => loadingMore = false);
}

  @override
  void initState() {
    super.initState();
    
    _load();
    _verticalController.addListener(() {
  if (_verticalController.position.pixels >=
      _verticalController.position.maxScrollExtent - 200) {
    loadMore();
  }
});
  }

Future<void> search(String value) async {
  if (value.isEmpty) {
    setState(() {
      isSearching = false;
    });
    _load(); // vuelve al modo paginado
    return;
  }

  setState(() {
    loading = true;
    isSearching = true;
  });

  final snap = await FirebaseFirestore.instance
      .collection("clientes")
      .orderBy("nombre")
      .startAt([value])
      .endAt([value + '\uf8ff'])
      .limit(50)
      .get();

  searchResults = snap.docs.map((doc) {
    final c = doc.data();

    return {
      "id_cliente": c["id_cliente"] ?? "",
      "nombre_mascota": c["nombre_mascota"] ?? "",
      "raza": c["raza"] ?? "",
      "color": c["color"] ?? "",
      "especie": c["especie"] ?? "",
      "sexo": c["sexo"] ?? "",
      "fechanac": c["fechanac"] ?? "",
      "nombre_dueno": c["nombre"] ?? "",
      "telefono": c["telefono"] ?? "",
      "direccion": c["direccion"] ?? "",
      "ci": c["dni"] ?? "",
      "marca": c["marca_tatuaje"] ?? "",
    };
  }).toList();

  setState(() {
    loading = false;
  });
}

  // ================= PDF =================
Future<void> _descargarPdf() async {
  try {
    setState(() => generatingDownload = true);

    final data = await getAllHistorial();

    final bytes =
        await PdfService.generateHistorialPdfBytes(data);

    final fileName =
        "historial_clientes_${DateTime.now().millisecondsSinceEpoch}.pdf";

    await FileService.saveOrDownload(bytes, fileName);

  } catch (e) {
    debugPrint("❌ ERROR DOWNLOAD PDF: $e");
  } finally {
    setState(() => generatingDownload = false);
  }
}

void onSearchChanged(String value) {
  _debounce?.cancel();

  _debounce = Timer(const Duration(milliseconds: 400), () {
    search(value);
  });
}

 void _registrarHistorial() {
  DashboardController.editingClienteId = null; // 🔥 importante
  DashboardController.goTo(5);
}

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

final isMobile = width < 600;

    return Padding(
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
          _header(isMobile),
          const SizedBox(height: 15),

          Expanded(
  child: loading
      ? const Center(child: CircularProgressIndicator())
      : isMobile
          ? _mobileList()
          : _table(),
),
        ],
      ),
    );
  }

  Widget _mobileList() {
  return ListView.builder(
    controller: _verticalController,
    itemCount: historial.length,
    padding: const EdgeInsets.symmetric(vertical: 10),
    itemBuilder: (_, i) {
      final d = historial[i];

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 🔥 más separación
        child: Card(
          elevation: 4, // 🔥 sombra real
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14), // 🔥 aire interno
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ================= HEADER =================
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d["nombre_mascota"] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "#${i + 1}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                /// ================= INFO =================
                Text("Dueño: ${d["nombre_dueno"] ?? ""}"),
                const SizedBox(height: 4),
                Text("Tel: ${d["telefono"] ?? ""}"),

                const SizedBox(height: 12),

                /// ================= BOTÓN =================
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      DashboardController.selectedHistorial = d;
                      DashboardController.goTo(9);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text(
                      "Ver historial",
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4B170), // 🔥 tu dorado
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _table() {
    
  return ScrollConfiguration(
    behavior: const MaterialScrollBehavior().copyWith(
      dragDevices: {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.trackpad,
      },
    ),
    child: Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontalController,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: DataTable(
              border: TableBorder.all(
                color: Colors.grey.shade700,
                width: 1.5,
              ),

              headingRowColor: MaterialStateProperty.all(
                Colors.grey.shade200,
              ),

              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),

              dataRowMinHeight: 55,
              dataRowMaxHeight: 110,

              columnSpacing: 20,
              horizontalMargin: 10,

              columns: const [
                DataColumn(label: Text("#")),
                DataColumn(label: Text("Mascota")),
                DataColumn(label: Text("Raza")),
                DataColumn(label: Text("Color")),
                DataColumn(label: Text("Especie")),
                DataColumn(label: Text("Sexo")),
                DataColumn(label: Text("Nacimiento")),
                DataColumn(label: Text("Nombre Dueño")),
                DataColumn(label: Text("Teléfono")),
                DataColumn(label: Text("Dirección")),
                DataColumn(label: Text("Marca/Tatuaje")),
                DataColumn(label: Text("Acción")),
              ],
              


              rows: List.generate(historial.length, (i) {
                final d = historial[i];

                Widget cell(String v) {
                  return SizedBox(
                    width: 100,
                    child: Text(
                      v,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }

                return DataRow(
                  cells: [
                    DataCell(Text("${i + 1}")),
DataCell(cell(safe(d["nombre_mascota"]))),
DataCell(cell(safe(d["raza"]))),
DataCell(cell(safe(d["color"]))),
DataCell(cell(safe(d["especie"]))),
DataCell(cell(safe(d["sexo"]))),
DataCell(cell(safe(d["fechanac"]))),
DataCell(cell(safe(d["nombre_dueno"]))), // 🔥 ya corregido
DataCell(cell(safe(d["telefono"]))),
DataCell(cell(safe(d["direccion"]))),
DataCell(cell(safe(d["marca"]))), // 🔥 ya corregido
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: () {
                            //limpiarHistorialBasura();
                            DashboardController.selectedHistorial = d;
                            DashboardController.goTo(9);
                          },
                          child: const Text("Ver Historial", style: TextStyle(fontSize: 12.5),),
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
  );
}

  // ================= HEADER =================
  Widget _header(bool isMobile) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "LISTA CLIENTES",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _btnHeader(
                    Icons.download,
                    "Descargar",
                    Colors.blue,
                    generatingDownload ? null : _descargarPdf,
                  ),
                  _btnHeader(
                    Icons.print,
                    "Imprimir",
                    Colors.green,
                    generatingPrint ? null : _handlePrint,
                  ),
                  _btnHeader(
                    Icons.add,
                    "Registrar",
                    Colors.orange,
                    _registrarHistorial,
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              const Text(
                "LISTA CLIENTES",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              Wrap(
                spacing: 10,
                children: [
                  _btnHeader(
                    Icons.download,
                    "Descargar",
                    Colors.blue,
                    generatingDownload ? null : _descargarPdf,
                  ),
                  _btnHeader(
                    Icons.print,
                    "Imprimir",
                    Colors.green,
                    generatingPrint ? null : _handlePrint,
                  ),
                  _btnHeader(
                    Icons.add,
                    "Registrar",
                    Colors.orange,
                    _registrarHistorial,
                  ),
                ],
              ),
            ],
          ),
  );
}

Widget _btnHeader(
  IconData icon,
  String text,
  Color color,
  VoidCallback? onPressed,
) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(text),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

  Future<void> _handlePrint() async {
  try {
    setState(() => generatingPrint = true);

    final data = await getAllHistorial();

    final bytes =
        await PdfService.generateHistorialPdfBytes(data);

    if (kIsWeb) {
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impresión solo disponible en Web"),
        ),
      );
    }

  } finally {
    setState(() => generatingPrint = false);
  }
}

Future<List<Map<String, dynamic>>> getAllHistorial() async {
  final snapshot = await FirebaseFirestore.instance
      .collection("clientes")
      .get();

  return snapshot.docs.map((doc) {
    final c = doc.data();

    return {
      "nombre_mascota": c["nombre_mascota"] ?? "",
      "raza": c["raza"] ?? "",
      "color": c["color"] ?? "",
      "especie": c["especie"] ?? "",
      "sexo": c["sexo"] ?? "",
      "fechanac": c["fechanac"] ?? "",
      "nombre_dueno": c["nombre"] ?? "", // 🔥 clave
      "telefono": c["telefono"] ?? "",
      "direccion": c["direccion"] ?? "",
      "ci": c["dni"] ?? "",
      "marca": c["marca_tatuaje"] ?? "",
    };
  }).toList();
}

  Widget _printButton() {
  return ElevatedButton.icon(
    onPressed: generatingPrint ? null : _handlePrint,
    icon: const Icon(Icons.print),
    label: const Text("Imprimir"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
  );
}
}