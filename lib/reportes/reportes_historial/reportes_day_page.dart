import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/historial/comprobante_view.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class HistorialReportesDayPage extends StatefulWidget {
  const HistorialReportesDayPage({super.key});

  @override
  State<HistorialReportesDayPage> createState() =>
      _HistorialReportesDayPageState();
}

class _HistorialReportesDayPageState extends State<HistorialReportesDayPage> {
  List<Map<String, dynamic>> data = [];
  final ScrollController _verticalController = ScrollController();
  bool loading = false;
  bool loadingPdf = false;
  bool loadingPrint = false;
  final ScrollController _horizontalController = ScrollController();

  String search = "";
  String titleDate = "REPORTE DE HISTORIAL - POR DÍA";
  String selected_string="";
  DateTime? selectedDay;

  bool hasSearched = false;

  // =========================================================
  // PICK DAY
  // =========================================================
  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale("es", "ES"), // 🔥 CLAVE
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedDay = picked;
      selected_string = DateFormat("dd/MM/yyyy").format(selectedDay!);
    });

    await _loadByDay();
  }

  // =========================================================
  // FIRESTORE QUERY (DAY)
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
          .collection("historial_v2")
          .where(
            "fecha_registro",
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            "fecha_registro",
            isLessThan: Timestamp.fromDate(end),
          )
          .orderBy("fecha_registro", descending: true)
          .get();

      final result = snap.docs.map((e) {
        return {
          "id": e.id,
          ...e.data(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        data = result;
        loading = false;
      });
    } catch (e) {
      debugPrint("ERROR DAY REPORT: $e");
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
          //_summary(),
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
        const Icon(Icons.calendar_today),
        const SizedBox(width: 10),
        Text(
          selected_string.isEmpty
              ? "REPORTE HISTORIAL - DÍA"
              : "REPORTE HISTORIAL ($selected_string)",
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
          label: const Text("Descargar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0054A6),
            foregroundColor: Colors.white,
          ),
        ),

        ElevatedButton.icon(
          onPressed: loadingPrint ? null : _printPdf,
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
              : "Para obtener el reporte por día, seleccione el día en el calendario",
        ),
      ),
    ),

          const SizedBox(height: 10),

               ElevatedButton.icon(
                onPressed: _pickDay,
                icon: const Icon(Icons.date_range),
                label: Text(
                  selectedDay == null
                      ? "Seleccionar día"
                      : DateFormat("dd/MM/yyyy").format(selectedDay!),
                ),
                style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0054A6),
        foregroundColor: Colors.white,
      ),
              ),

          const SizedBox(height: 20),

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
  // SUMMARY
  // =========================================================
  // Widget _summary() {
  //   return Card(
  //     margin: const EdgeInsets.all(10),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Text(
  //         "Total registros: ${filteredData.length}",
  //         style: const TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //     ),
  //   );
  // }

  // =========================================================
  // TABLE RESPONSIVE + SCROLL FULL
  // =========================================================
  Widget _table() {
    if (filteredData.isEmpty) {
      return const Center(
        child: Text("No hay registros en este día"),
      );
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
            thumbVisibility: true,
            controller: _verticalController,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
  controller: _horizontalController,
  scrollDirection: Axis.horizontal,
  physics: const AlwaysScrollableScrollPhysics(),

                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 900,
                  ),

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
                      border: TableBorder.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),

                      headingRowColor:
                          MaterialStateProperty.all(Colors.grey.shade200),

                      columns: const [
                        DataColumn(label: Text("Fecha",style: TextStyle(fontWeight: FontWeight.bold),)),
                        DataColumn(label: Text("Mascota",style: TextStyle(fontWeight: FontWeight.bold),)),
                        DataColumn(label: Text("Cliente",style: TextStyle(fontWeight: FontWeight.bold),)),
                        DataColumn(label: Text("Tipo",style: TextStyle(fontWeight: FontWeight.bold),)),
                        DataColumn(label: Text("Detalle",style: TextStyle(fontWeight: FontWeight.bold),)),
                        DataColumn(label: Text("Precio",style: TextStyle(fontWeight: FontWeight.bold),)),
                        DataColumn(
  label: Text("Tipo Pago",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
),
                        DataColumn(label: Text("Acciones")),
                      ],

                      rows: filteredData.map((e) {
                        return DataRow(cells: [
                          DataCell(Text(
                            (e["fecha_registro"] is Timestamp)
                                ? DateFormat('dd/MM/yyyy').format(
                                    (e["fecha_registro"] as Timestamp)
                                        .toDate(),
                                  )
                                : "-",
                          )),
                          DataCell(Text(e["nombre_mascota"] ?? "")),
                          DataCell(Text(e["nombre_dueno"] ?? "")),
                          DataCell(
  ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 120),
    child: Text(e["tipo_historial"] ?? ""),
  ),
),
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
  // PDF ACTIONS (REUTILIZA TU SERVICE)
  // =========================================================
  Future<void> _downloadPdf() async {
    setState(() => loadingPdf = true);

    try {
      final bytes = await PdfService().buildHistorialReportesPdf(
        filteredData,
        "REPORTE DE HISTORIAL - POR DÍA ($selected_string)",""
      );

      await FileService.saveOrDownload(
  bytes,
  "reporte_historial.pdf",
);
    } catch (e) {
      debugPrint("ERROR DOWNLOAD: $e");
    }

    setState(() => loadingPdf = false);
  }

  Future<void> _printPdf() async {
    setState(() => loadingPrint = true);

    try {
      final bytes = await PdfService().buildHistorialReportesPdf(
        filteredData,
        "REPORTE DE HISTORIAL - POR DÍA ($selected_string)",""
      );

      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      debugPrint("ERROR PRINT: $e");
    }

    setState(() => loadingPrint = false);
  }
}