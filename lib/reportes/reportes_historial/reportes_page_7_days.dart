import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/historial/comprobante_view.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';


class HistorialReportesLast7DaysPage extends StatefulWidget {
  const HistorialReportesLast7DaysPage({super.key});

  @override
  State<HistorialReportesLast7DaysPage> createState() =>
      _HistorialReportesLast7DaysPageState();
}

class _HistorialReportesLast7DaysPageState
    extends State<HistorialReportesLast7DaysPage> {
  List<Map<String, dynamic>> data = [];
  bool loading = true;
  bool loadingPdf = false;
  bool loadingPrint = false;
  String search = "";
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLast7Days();
  }

  // ================= FIRESTORE =================
  Future<void> _loadLast7Days() async {
    setState(() => loading = true);

    try {
      final now = DateTime.now();
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final start = DateTime(
  now.year,
  now.month,
  now.day,
).subtract(const Duration(days: 6));

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
    } catch (e, stack) {
  debugPrint("ERROR 7 DAYS: $e");
  debugPrint("STACK: $stack");

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
      final cliente = (e["nombre_dueno"] ?? "").toString().toLowerCase();
      final mascota = (e["nombre_mascota"] ?? "").toString().toLowerCase();
      final tipo = (e["tipo_historial"] ?? "").toString().toLowerCase();

      return cliente.contains(search.toLowerCase()) ||
          mascota.contains(search.toLowerCase()) ||
          tipo.contains(search.toLowerCase());
    }).toList();
  }

  // ================= UI =================
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

  // ================= HEADER =================
  Widget _header() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      return Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// TÍTULO
                      Row(
                        children: const [
                          Icon(Icons.history),
                          SizedBox(width: 10),
                          Text(
                            "Últimos 7 días",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// BOTONES RESPONSIVE
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _btnHeader(
                            Icons.download,
                            "Descargar",
                            Color(0xFF0054A6),
                            loadingPdf ? null : _descargarPdfReportes,
                          ),
                          _btnHeader(
                            Icons.print,
                            "Imprimir",
                            Colors.green,
                            loadingPrint ? null : _imprimirPdfReportes,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.history),
                      const SizedBox(width: 10),
                      const Text(
                        "Últimos 7 días",
                        style: TextStyle(
                          fontSize: 18,
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
                            Color(0xFF0054A6),
                            loadingPdf ? null : _descargarPdfReportes,
                          ),
                          _btnHeader(
                            Icons.print,
                            "Imprimir",
                            Colors.green,
                            loadingPrint ? null : _imprimirPdfReportes,
                          ),
                        ],
                      ),
                    ],
                  ),

            const SizedBox(height: 10),

            /// BUSCADOR (SIEMPRE FULL WIDTH)
            // TextField(
            //   decoration: const InputDecoration(
            //     hintText: "Buscar cliente / mascota",
            //     prefixIcon: Icon(Icons.search),
            //     border: OutlineInputBorder(),
            //   ),
            //   onChanged: (v) => setState(() => search = v),
            // ),
          ],
        ),
      );
    },
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

  // ================= SUMMARY =================
  Widget _summary() {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          "Total registros: ${filteredData.length}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // ================= TABLE MODERNA =================
  Widget _table() {
  if (filteredData.isEmpty) {
    return const Center(child: Text("Sin registros en los últimos 7 días"));
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
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
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
                      DataColumn(
                          label: Text("Fecha",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Mascota",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Cliente",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Tipo",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Detalle",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Precio",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(
  label: Text("Tipo Pago",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
),
                      DataColumn(
                          label: Text("Acciones",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],

                    rows: filteredData.map((e) {
                      return DataRow(cells: [
                        DataCell(Text(
                          (e["fecha_registro"] is Timestamp)
                              ? DateFormat('dd/MM/yyyy').format(
                                  (e["fecha_registro"] as Timestamp)
                                      .toDate())
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

Future<void> _descargarPdfReportes() async {
  setState(() => loadingPdf = true);

  try {
    final bytes = await PdfService().buildHistorialReportesPdf(
  filteredData,
  "REPORTE DE HISTORIAL - ÚLTIMOS 7 DÍAS","");

    await FileService.saveOrDownload(
  bytes,
  "reporte_historial.pdf",
);


  } catch (e) {
    debugPrint("ERROR PDF DOWNLOAD: $e");
  }

  setState(() => loadingPdf = false);
}

Future<void> _imprimirPdfReportes() async {
  setState(() => loadingPrint = true);

  try {
    final bytes = await PdfService().buildHistorialReportesPdf(
  filteredData,
  "REPORTE DE HISTORIAL - ÚLTIMOS 7 DÍAS",""
);

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );
  } catch (e) {
    debugPrint("ERROR PDF PRINT: $e");
  }

  setState(() => loadingPrint = false);
}
}