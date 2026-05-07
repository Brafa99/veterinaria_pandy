import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/reportes/reportes_ventas/comprobante_view_ventas.dart';
import 'package:veterinaria_pandy/services/file_service.dart';

import 'package:veterinaria_pandy/services/pdf_service.dart';

class VentasReportesMonthPage extends StatefulWidget {
  const VentasReportesMonthPage({super.key});

  @override
  State<VentasReportesMonthPage> createState() =>
      _VentasReportesMonthPageState();
}

class _VentasReportesMonthPageState
    extends State<VentasReportesMonthPage> {

  List<Map<String, dynamic>> data = [];

  bool loading = false;
  bool loadingPdf = false;
  bool loadingPrint = false;

  String search = "";
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  bool hasSearched = false;

  String get tituloReporte =>
      "(${_nombreMes(selectedMonth)} $selectedYear)";

  String _nombreMes(int m) {
    const meses = [
      "",
      "ENERO","FEBRERO","MARZO","ABRIL","MAYO","JUNIO",
      "JULIO","AGOSTO","SEPTIEMBRE","OCTUBRE","NOVIEMBRE","DICIEMBRE"
    ];
    return meses[m];
  }

  // ================= FIRESTORE =================
  Future<void> _loadMonth() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      hasSearched = true;
    });

    try {
      final start = DateTime(selectedYear, selectedMonth, 1);
      final end = DateTime(selectedYear, selectedMonth + 1, 0, 23, 59, 59);

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
      debugPrint("ERROR VENTAS MONTH: $e");

      if (!mounted) return;

      setState(() {
        data = [];
        loading = false;
      });
    }
  }

  // ================= FILTER =================
  List<Map<String, dynamic>> get filteredData {
    if (search.isEmpty) return data;

    return data.where((e) {
      final cliente = (e["cliente"] ?? "").toString().toLowerCase();
      final mascota = (e["mascota"] ?? "").toString().toLowerCase();

      return cliente.contains(search.toLowerCase()) ||
          mascota.contains(search.toLowerCase());
    }).toList();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _table(),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
  final isMobile = MediaQuery.of(context).size.width < 600;

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
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                Text(
                  hasSearched
                      ? "REPORTE POR MES $tituloReporte"
                      : "REPORTE POR MES",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            Wrap(
              spacing: 8,
              children: [

                ElevatedButton.icon(
                  onPressed: loadingPdf ? null : _downloadPdf,
                  icon: const Icon(Icons.download),
                  label: const Text("Descargar", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0054A6),
                    minimumSize: Size(isMobile ? 140 : 160, 45),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: loadingPrint ? null : _printPdf,
                  icon: const Icon(Icons.print),
                  label: const Text("Imprimir", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(isMobile ? 140 : 160, 45),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        _summaryCard(),

        const SizedBox(height: 10),

        _filters(),

        const SizedBox(height: 10),

        //_searchInput(),
      ],
    ),
  );
}

// Widget _searchInput() {
//   return TextField(
//     decoration: InputDecoration(
//       hintText: "Buscar cliente / mascota / producto",
//       prefixIcon: const Icon(Icons.search),
//       filled: true,
//       fillColor: Colors.grey.shade100,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//     ),
//     onChanged: (v) => setState(() => search = v),
//   );
// }

Widget _filters() {
  final isMobile = MediaQuery.of(context).size.width < 600;

  return Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [

      SizedBox(
        width: isMobile ? double.infinity : 220,
        child: customDropdown(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedMonth,
              dropdownColor: const Color(0xFF2A2A3D),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: const Color(0xFFD4B170),
              items: List.generate(12, (i) {
                return DropdownMenuItem(
                  value: i + 1,
                  child: formatDateText(i + 1),
                );
              }),
              onChanged: (v) => setState(() => selectedMonth = v!),
            ),
          ),
        ),
      ),

      SizedBox(
        width: isMobile ? double.infinity : 220,
        child: customDropdown(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedYear,
              dropdownColor: const Color(0xFF2A2A3D),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: const Color(0xFFD4B170),
              items: List.generate(5, (i) {
                final y = DateTime.now().year - i;
                return DropdownMenuItem(
                  value: y,
                  child: Text("$y"),
                );
              }),
              onChanged: (v) => setState(() => selectedYear = v!),
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _summaryCard() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        hasSearched
            ? "Total registros: ${filteredData.length}"
            : "Selecciona mes y año para ver resultados",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}

  // ================= TABLE =================
 // =========================================================
// TABLE MEJORADA (VENTAS 7 DÍAS)
// =========================================================
Widget _table() {
  if (filteredData.isEmpty) {
    return const Center(child: Text("Sin ventas en los últimos 7 días"));
  }
final isMobile = MediaQuery.of(context).size.width < 600;
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
                    columnSpacing: isMobile ? 10 : 18,
                    headingRowHeight: 45,
                    dataRowMinHeight: isMobile ? 40 : 45,

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
        constraints: BoxConstraints(
  maxWidth: isMobile ? 180 : 300,
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
        child: const Text("Ver Comprobante",overflow: TextOverflow.ellipsis,),
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

Widget customDropdown({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A3D), // fondo oscuro elegante
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: const Color(0xFFD4B170), // dorado
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

Widget formatDateText(int i) {
    String text_date = ""; 
    if(i==1){
      text_date = "ENERO";
    }else if(i==2){
      text_date = "FEBRERO";
    }else if(i==3){
      text_date = "MARZO";
    }else if(i==4){
      text_date = "ABRIL";
    }else if(i==5){
      text_date = "MAYO";
    }else if(i==6){
      text_date = "JUNIO";
    }else if(i==7){
      text_date = "JULIO";
    }else if(i==8){
      text_date = "AGOSTO";
    }else if(i==9){
      text_date = "SEPTIEMBRE";
    }else if(i==10){
      text_date = "OCTUBRE";
    }else if(i==11){
      text_date = "NOVIEMBRE";
    }else if(i==12){
      text_date = "DICIEMBRE";
    }
    return Text(text_date);
  }

  // ================= PDF =================
  Future<void> _downloadPdf() async {
    setState(() => loadingPdf = true);

    try {
      final bytes = await PdfService().buildVentasReportesPdf(
        filteredData,
        "REPORTE DE VENTAS - POR MES $tituloReporte",
        "",
      );

      await FileService.saveOrDownload(
  bytes,
  "reporte_historial.pdf",
);

    } finally {
      setState(() => loadingPdf = false);
    }
  }

  Future<void> _printPdf() async {
    setState(() => loadingPrint = true);

    try {
      final bytes = await PdfService().buildVentasReportesPdf(
        filteredData,
        "REPORTE DE VENTAS - POR MES $tituloReporte",
        "",
      );

      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } finally {
      setState(() => loadingPrint = false);
    }
  }
}