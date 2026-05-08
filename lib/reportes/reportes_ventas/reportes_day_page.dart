import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/comprobante_view_ventas.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class VentasReportesDayPage extends StatefulWidget {
  const VentasReportesDayPage({super.key});

  @override
  State<VentasReportesDayPage> createState() =>
      _VentasReportesDayPageState();
}

class _VentasReportesDayPageState
    extends State<VentasReportesDayPage> {

  List<Map<String, dynamic>> data = [];

  bool loading = false;
  bool loadingPdf = false;
  bool loadingPrint = false;

  String search = "";

  DateTime? selectedDay;
  String selectedString = "";

  bool hasSearched = false;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  // =========================================================
  // PICK DAY
  // =========================================================
  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale("es", "ES"),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedDay = picked;
      selectedString = DateFormat("dd/MM/yyyy").format(picked);
    });

    await _loadByDay();
  }

  // =========================================================
  // FIRESTORE QUERY
  // =========================================================
  Future<void> _loadByDay() async {
    if (selectedDay == null) return;

    setState(() {
      loading = true;
      hasSearched = true;
    });

    try {
      final start = DateTime(
        selectedDay!.year,
        selectedDay!.month,
        selectedDay!.day,
      );

      final end = start.add(const Duration(days: 1));

      final snap = await FirebaseFirestore.instance
          .collection("ventas")
          .where(
            "fecha",
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            "fecha",
            isLessThan: Timestamp.fromDate(end),
          )
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
      debugPrint("ERROR DAY VENTAS: $e");

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
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          
          Wrap(
  alignment: WrapAlignment.spaceBetween,
  runSpacing: 10,
  spacing: 10,
  children: [

    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.calendar_today),
        const SizedBox(width: 10),
        Text(
          selectedString.isEmpty
              ? "REPORTE DE VENTAS - POR DÍA"
              : "REPORTE DE VENTAS - ($selectedString)",
          style: const TextStyle(
            fontSize: 16, // 🔥 bajar un poco
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),

    Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0054A6),
            foregroundColor: Colors.white,
          ),
          onPressed: loadingPdf ? null : _downloadPdf,
          icon: const Icon(Icons.download),
          label: const Text("Descargar"),
        ),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: loadingPrint ? null : _printPdf,
          icon: const Icon(Icons.print),
          label: const Text("Imprimir"),
        ),
      ],
    ),
  ],
),

          const SizedBox(height: 10),

          Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                hasSearched
                    ? "Total registros: ${filteredData.length}"
                    : "Selecciona un día para generar el reporte",
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF0054A6),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    onPressed: _pickDay,
    icon: const Icon(Icons.date_range),
    label: Text(
      selectedDay == null
          ? "Seleccionar día"
          : DateFormat("dd/MM/yyyy").format(selectedDay!),
    ),
  ),
),

          const SizedBox(height: 10),

//           TextField(
//   decoration: InputDecoration(
//     hintText: "Buscar ",
//     prefixIcon: const Icon(Icons.search),
//     isDense: true,
//     filled: true,
//     fillColor: Colors.grey.shade100,
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//     ),
//   ),
//   onChanged: (v) => setState(() => search = v),
// )
        ],
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

 // =========================================================
// TABLE MEJORADA (VENTAS 7 DÍAS)
// =========================================================
Widget _table() {
  if (filteredData.isEmpty) {
    return Center(
  child: Text(
    hasSearched
        ? "No hay ventas en esa fecha"
        : "Selecciona un día para ver resultados",
  ),
);
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      return ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: {
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
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
                constraints: const BoxConstraints(minWidth: 800),

                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade500,
                      width: 1.5,
                    ),
                  ),

                  child: DataTable(
                    columnSpacing: 12,
headingRowHeight: 40,
dataRowMinHeight: 40,
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
    DataCell(Text(e["cliente"] ?? "")),

    // MASCOTA
    DataCell(Text(e["mascota"] ?? "")),

    // PRODUCTOS (MULTILINEA 🔥)
    DataCell(
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
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
        child: const Text("Ver Comprobante", style: TextStyle(fontSize: 12),),
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
  Future<void> _downloadPdf() async {
    setState(() => loadingPdf = true);

    final bytes = await PdfService().buildVentasReportesPdf(
      filteredData,
      "REPORTE DE VENTAS - POR DÍA ($selectedString)",
      "",
    );

    await FileService.saveOrDownload(
  bytes,
  "reporte_historial.pdf",
);

    setState(() => loadingPdf = false);
  }

  Future<void> _printPdf() async {
    setState(() => loadingPrint = true);

    final bytes = await PdfService().buildVentasReportesPdf(
      filteredData,
      "REPORTE DE VENTAS - POR DÍA ($selectedString)",
      "",
    );

    await Printing.layoutPdf(onLayout: (_) async => bytes);

    setState(() => loadingPrint = false);
  }
}