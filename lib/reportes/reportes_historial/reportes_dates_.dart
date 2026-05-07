import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/historial/comprobante_view.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class HistorialReportesRangePage extends StatefulWidget {
  const HistorialReportesRangePage({super.key});

  @override
  State<HistorialReportesRangePage> createState() =>
      _HistorialReportesRangePageState();
}

class _HistorialReportesRangePageState
    extends State<HistorialReportesRangePage> {
  List<Map<String, dynamic>> data = [];
  bool loading = false;

  bool loadingPdf = false;
  bool loadingPrint = false;

  final verticalController = ScrollController();
  final horizontalController = ScrollController();

  String search = "";

  DateTime? startDate;
  DateTime? endDate;

  bool hasSearched = false;

  String title ="";

  // =========================================================
  // LOAD RANGE
  // =========================================================
  Future<void> _loadRange() async {
    if (startDate == null || endDate == null) return;

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
        23,
        59,
        59,
      );

      final snap = await FirebaseFirestore.instance
          .collection("historial_v2")
          .where(
            "fecha_registro",
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            "fecha_registro",
            isLessThanOrEqualTo: Timestamp.fromDate(end),
          )
          .orderBy("fecha_registro", descending: true)
          .get();

      final result = snap.docs.map((e) {
        return {
          "id": e.id,
          ...e.data(),
        };
      }).toList();

      setState(() {
        data = result;
        loading = false;
        title = "(${DateFormat("dd/MM/yyyy").format(start)} - ${DateFormat("dd/MM/yyyy").format(end)})";
      });

    } catch (e) {
      debugPrint("ERROR RANGE: $e");
      setState(() {
        data = [];
        loading = false;
      });
    }
  }

  // =========================================================
  // FILTER SEARCH
  // =========================================================
  List<Map<String, dynamic>> get filteredData {
    if (search.isEmpty) return data;

    return data.where((e) {
      final cliente = (e["nombre_dueno"] ?? "").toString().toLowerCase();
      final mascota = (e["nombre_mascota"] ?? "").toString().toLowerCase();
      final tipo = (e["tipo_historial"] ?? "").toString().toLowerCase();

      return cliente.contains(search.toLowerCase()) ||
          mascota.contains(search.toLowerCase()) ||
          tipo.contains(search.toLowerCase());
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
  children: [

    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.date_range),
        const SizedBox(width: 10),
        Text(
          title.isEmpty
              ? "REPORTE POR FECHAS"
              : "REPORTE ($title)",
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
          onPressed: _descargarPdf,
          icon: const Icon(Icons.download),
          label: const Text("Descargar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0054A6),
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed:  _imprimirPdf,
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



Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
          // ================= DATE PICKERS =================
          Wrap(
  spacing: 10,
  runSpacing: 10,
  alignment: WrapAlignment.center,
  children: [

    TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: Colors.orangeAccent,
      ),
      icon: const Icon(Icons.calendar_today),
      label: Text(startDate == null
          ? "Inicio"
          : DateFormat("dd/MM/yyyy").format(startDate!)),
      onPressed: () async {
        startDate = await showDatePicker(
          context: context,
          locale: const Locale("es", "ES"),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        setState(() {});
      },
    ),

    TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: Colors.orangeAccent,
      ),
      icon: const Icon(Icons.calendar_today),
      label: Text(endDate == null
          ? "Fin"
          : DateFormat("dd/MM/yyyy").format(endDate!)),
      onPressed: () async {
        endDate = await showDatePicker(
          context: context,
          locale: const Locale("es", "ES"),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        setState(() {});
      },
    ),
  ],
)
          ]
          ),)),


          const SizedBox(height: 20),

  ElevatedButton(
    style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0054A6),
        foregroundColor: Colors.white,
      ),
                onPressed: _loadRange,
                child: const Text("Buscar Reportes"),
              ),
          const SizedBox(height: 10),

          // TextField(
          //   decoration: const InputDecoration(
          //     hintText: "Buscar cliente/mascota",
          //     prefixIcon: Icon(Icons.search),
          //     border: OutlineInputBorder(),
          //   ),
          //   onChanged: (v) => setState(() => search = v),
          // ),
        ],
      ),
    );
  }


  // =========================================================
  // TABLE (FULL SCROLL + BORDERS)
  // =========================================================
  Widget _table() {
    if (filteredData.isEmpty) {
      return const Center(child: Text("Sin registros"));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: true,
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
            },
          ),
          child: Scrollbar(
            thumbVisibility: true,
            controller: verticalController,
            child: SingleChildScrollView(
              controller: verticalController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                 controller: horizontalController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),

                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 1000),

                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade500, width: 1.5),
                    ),

                    child: DataTable(
                      headingRowHeight: 45,
                    dataRowMinHeight: 45,
                    dataRowMaxHeight: double.infinity,
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey.shade200,
                      ),
                      columnSpacing: 12,

                      border: TableBorder(
                        top: BorderSide(color: Colors.grey.shade500),
                        bottom: BorderSide(color: Colors.grey.shade500),
                        left: BorderSide(color: Colors.grey.shade500),
                        right: BorderSide(color: Colors.grey.shade500),
                        horizontalInside:
                            BorderSide(color: Colors.grey.shade400),
                        verticalInside:
                            BorderSide(color: Colors.grey.shade400),
                      ),

                      columns: const [
                        DataColumn(label: Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Mascota", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Cliente", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Tipo", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Detalle", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Precio", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
  label: Text("Tipo Pago",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
),
                        DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],

                      rows: filteredData.map((e) {
                        return DataRow(cells: [
                          DataCell(Text(
                            (e["fecha_registro"] is Timestamp)
                                ? DateFormat('dd/MM/yyyy').format(
                                    (e["fecha_registro"] as Timestamp).toDate())
                                : "-",
                          )),
                          DataCell(Text(e["nombre_mascota"] ?? "")),
                          DataCell(Text(e["nombre_dueno"] ?? "")),
                          DataCell(Text(e["tipo_historial"] ?? "")),
                          DataCell(
  ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: 250, // 🔥 clave (ajusta a tu gusto)
    ),
    child: Text(
      (e["descripcion"] ?? "").toString(),
      softWrap: true,
      overflow: TextOverflow.visible,
      style: const TextStyle(fontSize: 13),
    ),
  ),
),
                          DataCell(Text("Bs ${e["precioh"] ?? 0}")),
                          DataCell(
  Text(
    (e["tipo_pago"] ?? "-").toString(),
  ),
),
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
                                    builder: (_) => ComprobanteView(
                                      idHistorial: e["id"],
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
  // PDF ACTIONS (REUTILIZA SERVICE)
  // =========================================================
  Future<void> _descargarPdf() async {
    setState(() => loadingPdf = true);

    try {
      final sub = (startDate != null && endDate != null)
    ? "Desde: ${DateFormat('dd/MM/yyyy').format(startDate!)}  "
      "Hasta: ${DateFormat('dd/MM/yyyy').format(endDate!)}"
    : "";

final bytes = await PdfService().buildHistorialReportesPdf(
  filteredData,
  "REPORTE DE HISTORIAL - POR FECHAS $title",
  sub,
);
      await FileService.saveOrDownload(
  bytes,
  "reporte_historial.pdf",
);
    } catch (e) {
      debugPrint("ERROR PDF: $e");
    }

    setState(() => loadingPdf = false);
  }

  Future<void> _imprimirPdf() async {
    setState(() => loadingPrint = true);

    try {
      final bytes =
          await PdfService().buildHistorialReportesPdf(filteredData, "REPORTE DE HISTORIAL - POR FECHAS $title"
          ,"Desde: ${DateFormat('dd/MM/yyyy').format(startDate!)}  Hasta: ${DateFormat('dd/MM/yyyy').format(endDate!)}",);

      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      debugPrint("ERROR PRINT: $e");
    }

    setState(() => loadingPrint = false);
  }
}