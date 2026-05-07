import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/historial/comprobante_view.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/comprobante_view_ventas.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class VentasReportesLast7DaysPage extends StatefulWidget {
  const VentasReportesLast7DaysPage({super.key});

  @override
  State<VentasReportesLast7DaysPage> createState() =>
      _VentasReportesLast7DaysPageState();
}

class _VentasReportesLast7DaysPageState
    extends State<VentasReportesLast7DaysPage> {

  List<Map<String, dynamic>> data = [];
  bool loading = true;
  bool loadingPdf = false;
  bool loadingPrint = false;
  String search = "";

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLast7Days();
  }

  // =========================================================
  // 🔥 EXPAND VENTAS (CLAVE)
  // =========================================================
  List<Map<String, dynamic>> expandVentas(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> result = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final productos = data["productos"] ?? [];

      for (var p in productos) {
        result.add({
          "id": doc.id,
          "fecha": data["fecha"],
          "cliente": data["cliente_nombre"],
          "mascota": data["mascota_nombre"],
          "producto": p["nombre"],
          "cantidad": p["cantidad"],
          "precio": p["precio"],
          "subtotal": p["subtotal"],
          "total": data["total"],
        });
      }
    }

    return result;
  }

  // =========================================================
  // FIRESTORE
  // =========================================================
  Future<void> _loadLast7Days() async {
    setState(() => loading = true);

    try {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final start = end.subtract(const Duration(days: 7));

      final snap = await FirebaseFirestore.instance
          .collection("ventas")
          .where("fecha", isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where("fecha", isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy("fecha", descending: true)
          .get();

      final result = snap.docs.map((e) {
  final data = e.data();

  return {
    "id": e.id,
    "fecha": data["fecha"],
    "cliente": data["cliente_nombre"],
    "mascota": data["mascota_nombre"],
    "productos": data["productos"] ?? [],
    "total": data["total"] ?? 0,
  };
}).toList();

      if (!mounted) return;

      setState(() {
        data = result;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR VENTAS 7 DAYS: $e");
      setState(() {
        data = [];
        loading = false;
      });
    }
  }

  // =========================================================
  // FILTER
  // =========================================================
  List<Map<String, dynamic>> get filteredData {
    if (search.isEmpty) return data;

    return data.where((e) {
      final cliente = (e["cliente"] ?? "").toString().toLowerCase();
      final mascota = (e["mascota"] ?? "").toString().toLowerCase();

      return cliente.contains(search.toLowerCase()) ||
          mascota.contains(search.toLowerCase());
    }).toList();
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(),
          _summary(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _table(),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================
  Widget _header() {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 600;

  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔥 TÍTULO
        Row(
          children: const [
            Icon(Icons.point_of_sale),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Ventas - Últimos 7 días",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔥 BOTONES RESPONSIVOS
        isMobile
            ? Column(
                children: [
                  _btnDownload(),
                  const SizedBox(height: 8),
                  _btnPrint(),
                ],
              )
            : Row(
                children: [
                  _btnDownload(),
                  const SizedBox(width: 10),
                  _btnPrint(),
                ],
              ),

        const SizedBox(height: 10),

        // 🔥 BUSCADOR FULL WIDTH
        // TextField(
        //   decoration: InputDecoration(
        //     hintText: "Buscar cliente / mascota / producto",
        //     prefixIcon: const Icon(Icons.search),
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //   ),
        //   onChanged: (v) => setState(() => search = v),
        // ),
      ],
    ),
  );
}

Widget _btnDownload() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: loadingPdf ? null : _descargarPdf,
      icon: const Icon(Icons.download),
      label: const Text("Descargar"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0054A6),
        foregroundColor: Colors.white,
      ),
    ),
  );
}

Widget _btnPrint() {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: loadingPrint ? null : _imprimirPdf,
      icon: const Icon(Icons.print),
      label: const Text("Imprimir"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    ),
  );
}


  // =========================================================
  // SUMMARY
  // =========================================================
  Widget _summary() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          "Total registros: ${filteredData.length}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

Widget cell(String text, {double width = 120}) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

 // =========================================================
// TABLE MEJORADA (VENTAS 7 DÍAS)
// =========================================================
Widget _table() {
  if (filteredData.isEmpty) {
    return const Center(child: Text("Sin ventas en los últimos 7 días"));
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
          },
        ),
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              controller: _horizontalController,
              
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),

              child: ConstrainedBox(
                constraints: BoxConstraints(
  minWidth: MediaQuery.of(context).size.width,
),

                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade500,
                      width: 1.5,
                    ),
                  ),

                  child: DataTable(
                    columnSpacing: 18,
                    headingRowHeight: 45,
                    dataRowMinHeight: 45,
                    dataRowMaxHeight: double.infinity,

                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey.shade200,
                    ),

                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                      verticalInside: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                      top: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.5,
                      ),
                      bottom: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.5,
                      ),
                      left: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.5,
                      ),
                      right: BorderSide(
                        color: Colors.grey.shade500,
                        width: 1.5,
                      ),
                    ),

                    columns: const [
  DataColumn(label: Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold))),
  DataColumn(label: Text("Cliente", style: TextStyle(fontWeight: FontWeight.bold))),
  DataColumn(label: Text("Mascota", style: TextStyle(fontWeight: FontWeight.bold))),
  DataColumn(label: Text("Productos", style: TextStyle(fontWeight: FontWeight.bold))),
  DataColumn(label: Text("Total", style: TextStyle(fontWeight: FontWeight.bold))),
  DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
],

                    rows: filteredData.map((e) {

  final productos = (e["productos"] as List?) ?? [];

  // 🔥 construir texto de productos
  final productosText = productos.map((p) {
    final nombre = p["nombre"] ?? "";
    final cant = p["cantidad"] ?? 0;
    final precio = p["precio"] ?? 0;

    return "$nombre  x$cant  (Bs $precio)";
  }).join("\n");

  return DataRow(cells: [

    // FECHA
    DataCell(Text(
      (e["fecha"] is Timestamp)
          ? DateFormat('dd/MM/yyyy')
              .format((e["fecha"] as Timestamp).toDate())
          : "-",
    )),

    // CLIENTE
    DataCell(cell(e["cliente"] ?? "")),

    // MASCOTA
    DataCell(Text(e["mascota"] ?? "")),

    // PRODUCTOS (MULTILINEA 🔥)
    DataCell(
      ConstrainedBox(
        constraints: BoxConstraints(
  maxWidth: MediaQuery.of(context).size.width < 600 ? 200 : 300,
),
        child: Text(
          productosText,
          softWrap: true,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),

    // TOTAL
    DataCell(Text("Bs ${e["total"] ?? 0}")),

    // ACCIONES
    DataCell(
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0054A6),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComprobanteViewVentas(
                idVenta: e["id"],
              ),
            ),
          );
        },
        child: const Text("Ver Comprobante"),
      ),
    ),
  ]);

}).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  // =========================================================
  // PDF
  // =========================================================
  Future<void> _descargarPdf() async {
    setState(() => loadingPdf = true);

    final bytes = await PdfService().buildVentasReportesPdf(
      filteredData,
      "REPORTE DE VENTAS - ÚLTIMOS 7 DÍAS",
      null,
    );

    await FileService.saveOrDownload(
  bytes,
  "reporte_historial.pdf",
);

    setState(() => loadingPdf = false);
  }

  Future<void> _imprimirPdf() async {
    setState(() => loadingPrint = true);

    final bytes = await PdfService().buildVentasReportesPdf(
      filteredData,
      "REPORTE DE VENTAS - ÚLTIMOS 7 DÍAS",
      null,
    );

    await Printing.layoutPdf(onLayout: (_) async => bytes);

    setState(() => loadingPrint = false);
  }
}