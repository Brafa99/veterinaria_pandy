import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/comprobante_view_ventas.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class VentasReportesRangePage extends StatefulWidget {
  const VentasReportesRangePage({super.key});

  @override
  State<VentasReportesRangePage> createState() =>
      _VentasReportesRangePageState();
}

class _VentasReportesRangePageState
    extends State<VentasReportesRangePage> {

  List<Map<String, dynamic>> data = [];

  bool loading = false;
  bool loadingPdf = false;
  bool loadingPrint = false;
  
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  String search = "";

  DateTime? startDate;
  DateTime? endDate;

  bool hasSearched = false;

  String title = "";

  // =========================================================
  // LOAD RANGE (VENTAS)
  // =========================================================
  Future<void> _loadRange() async {
    if (startDate == null || endDate == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Selecciona ambas fechas")),
  );
  return;
}

    setState(() {
      loading = true;
      hasSearched = true;
    });

    try {
      final start = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
      );

      final end = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        23, 59, 59,
      );

      final snap = await FirebaseFirestore.instance
          .collection("ventas")
          .where(
            "fecha",
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            "fecha",
            isLessThanOrEqualTo: Timestamp.fromDate(end),
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

      setState(() {
        data = result;
        loading = false;
        title =
            "(${DateFormat("dd/MM/yyyy").format(start)} - ${DateFormat("dd/MM/yyyy").format(end)})";
      });

    } catch (e) {
      debugPrint("ERROR RANGE VENTAS: $e");

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
      final producto = (e["producto"] ?? "").toString().toLowerCase();

      return cliente.contains(search.toLowerCase()) ||
          mascota.contains(search.toLowerCase()) ||
          producto.contains(search.toLowerCase());
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
  spacing: 10,
  runSpacing: 10,
  children: [

    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.date_range),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title.isEmpty
                ? "REPORTE DE VENTAS POR FECHAS"
                : "REPORTE: ${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),

    Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed:_descargarPdf,
          icon: const Icon(Icons.download),
          label: const Text("Descargar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0054A6),
            foregroundColor: Colors.white,
          ),
        ),

        ElevatedButton.icon(
          onPressed: _imprimirPdf,
          icon: const Icon(Icons.print),
          label: const Text("Imprimir"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
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
                    : "Selecciona un rango de fechas",
              ),
            ),
          ),

          const SizedBox(height: 20),

          Wrap(
  alignment: WrapAlignment.center,
  spacing: 10,
  runSpacing: 10,
  children: [

    SizedBox(
      width: 160,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.calendar_today),
        label: Text(
          startDate == null
              ? "Inicio"
              : DateFormat("dd/MM/yyyy").format(startDate!),
        ),
        onPressed: () async {
          startDate = await showDatePicker(
            locale: const Locale("es", "ES"),
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          setState(() {});
        },
      ),
    ),

    SizedBox(
      width: 160,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.calendar_today),
        label: Text(
          endDate == null
              ? "Fin"
              : DateFormat("dd/MM/yyyy").format(endDate!),
        ),
        onPressed: () async {
          endDate = await showDatePicker(
            locale: const Locale("es", "ES"),
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          setState(() {});
        },
      ),
    ),
  ],
),

          const SizedBox(height: 12),

          SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF0054A6),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    onPressed: _loadRange,
    child: const Text("Buscar Reportes"),
  ),
),

          const SizedBox(height: 10),

//           TextField(
//   decoration: InputDecoration(
//     hintText: "Buscar...",
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
        ? "No hay ventas en ese rango"
        : "Selecciona un rango de fechas",
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
        child: const Text("Ver Comprobante",style: TextStyle(fontSize: 12),),
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

    final sub = (startDate != null && endDate != null)
        ? "Desde: ${DateFormat('dd/MM/yyyy').format(startDate!)}  "
          "Hasta: ${DateFormat('dd/MM/yyyy').format(endDate!)}"
        : "";

    final bytes = await PdfService().buildVentasReportesPdf(
      filteredData,
      "REPORTE DE VENTAS POR FECHAS $title",
      sub,
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
      "REPORTE DE VENTAS POR FECHAS $title",
      "Desde: ${DateFormat('dd/MM/yyyy').format(startDate!)}  Hasta: ${DateFormat('dd/MM/yyyy').format(endDate!)}",
    );

    await Printing.layoutPdf(onLayout: (_) async => bytes);

    setState(() => loadingPrint = false);
  }
}