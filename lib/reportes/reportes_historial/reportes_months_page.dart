import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/services/file_service.dart';

import 'package:veterinaria_pandy/services/pdf_service.dart';
import 'package:veterinaria_pandy/historial/comprobante_view.dart';

class HistorialReportesMonthPage extends StatefulWidget {
  const HistorialReportesMonthPage({super.key});

  @override
  State<HistorialReportesMonthPage> createState() =>
      _HistorialReportesMonthPageState();
}

class _HistorialReportesMonthPageState
    extends State<HistorialReportesMonthPage> {
  List<Map<String, dynamic>> data = [];
  bool loading = false;
  bool loadingPdf = false;
  bool loadingPrint = false;
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  String search = "";

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  bool hasSearched = false;

  String get tituloReporte =>
      "(${_nombreMes(selectedMonth)} $selectedYear)";

  String _nombreMes(int m) {
    const meses = [
      "",
      "ENERO",
      "FEBRERO",
      "MARZO",
      "ABRIL",
      "MAYO",
      "JUNIO",
      "JULIO",
      "AGOSTO",
      "SEPTIEMBRE",
      "OCTUBRE",
      "NOVIEMBRE",
      "DICIEMBRE"
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
      });
    } catch (e) {
      debugPrint("ERROR MONTH: $e");
      setState(() {
        data = [];
        loading = false;
      });
    }
  }

  // ================= FILTER LOCAL =================
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

  // ================= HEADER =================
  Widget _header() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 700;

      return Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ================= TITLE + ACTIONS =================
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasSearched
                                  ? "REPORTE POR MES $tituloReporte"
                                  : "REPORTE POR MES",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          
                          _btnHeader(
                            Icons.download,
                            "Descargar",
                            Color(0xFF0054A6),
                            loadingPdf ? null : _downloadPdf,
                          ),
                          _btnHeader(
                            Icons.print,
                            "Imprimir",
                            Colors.green,
                            loadingPrint ? null : _printPdf,
                          ),
                        ],
                      ),
                      SizedBox(height: 12,),
                      
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 10),
                      Text(
                        hasSearched
                            ? "REPORTE POR MES $tituloReporte"
                            : "REPORTE POR MES",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),

                      Wrap(
                        spacing: 10,
                        children: [
                          // _btnHeader(
                          //   Icons.search,
                          //   "Buscar",
                          //   Colors.redAccent,
                          //   _loadMonth,
                          // ),
                          _btnHeader(
                            Icons.download,
                            "Descargar",
                            Color(0xFF0054A6),
                            loadingPdf ? null : _downloadPdf,
                          ),
                          _btnHeader(
                            Icons.print,
                            "Imprimir",
                            Colors.green,
                            loadingPrint ? null : _printPdf,
                          ),
                        ],
                      ),
                    ],
                  ),

            const SizedBox(height: 10),

            /// ================= SUMMARY =================
            Center(
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    hasSearched
                        ? "Total registros: ${filteredData.length}"
                        : "Seleccione mes y año y presione Buscar",
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// ================= SELECTORES =================
            isMobile
                ? Column(
                    children: [
                      _dropdownMes(),
                      const SizedBox(height: 10),
                      _dropdownYear(),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _dropdownMes()),
                      const SizedBox(width: 10),
                      Expanded(child: _dropdownYear()),
                    ],
                  ),

            const SizedBox(height: 10),

              Center(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0054A6),
                      foregroundColor: Colors.white,
                    ),
                  onPressed: _loadMonth,
                  child: const Text("Buscar Reportes"),
                ),
            ),

            const SizedBox(height: 12),


            /// ================= SEARCH =================
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
    },
  );
}


Widget _dropdownMes() {
  return customDropdown(
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
  );
}

Widget _dropdownYear() {
  return customDropdown(
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

  // // ================= SUMMARY =================
  // Widget _summary() {
  //   return Card(
  //     margin: const EdgeInsets.all(10),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Text(
  //         hasSearched
  //             ? "Total registros: ${filteredData.length}"
  //             : "Selecciona mes y año",
  //       ),
  //     ),
  //   );
  // }

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

  Widget _table() {
  if (!hasSearched) {
    return const Center(child: Text("Selecciona filtros"));
  }

  if (filteredData.isEmpty) {
    return Center(
      child: Text(hasSearched ? "No hay resultados" : "Selecciona mes y año"),
    );
  }

  // 1. SelectionArea para permitir copiar texto sin usar SelectableText individual
  return SelectionArea(
    child: Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 12,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          // Forzamos el ancho mínimo para que la barra siempre tenga recorrido
          constraints: const BoxConstraints(minWidth: 1000), 
          child: Column(
            children: [
              // 2. El Scroll Vertical va DENTRO del Horizontal
              Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      // Espacio inferior para que la barra horizontal no tape la última fila
                      padding: const EdgeInsets.only(bottom: 25), 
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade500, width: 1.5),
                        ),
                        child: DataTable(
                          columnSpacing: 12,
                          headingRowHeight: 40,
                          dataRowMinHeight: 45, // Un poco más de aire para el lag visual
                          headingRowColor: MaterialStateProperty.all(Colors.grey.shade200),
                          // Simplifiqué el TableBorder para mejorar el rendimiento de renderizado
                          border: TableBorder.all(color: Colors.grey.shade400, width: 0.5),
                          columns: const [
                            DataColumn(label: Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Mascota", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Propietario", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Tipo", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Detalle", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Precio", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Tipo Pago", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredData.map((e) {
                            return DataRow(cells: [
                              DataCell(Text((e["fecha_registro"] is Timestamp)
                                  ? DateFormat('dd/MM/yyyy').format((e["fecha_registro"] as Timestamp).toDate())
                                  : "-")),
                              DataCell(Text(e["nombre_mascota"] ?? "")),
                              DataCell(Text(e["nombre_dueno"] ?? "")),
                              DataCell(Text(e["tipo_historial"] ?? "")),
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    (e["descripcion"] ?? "").toString(),
                                    maxLines: 2, // Limitar líneas reduce el lag de layout
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(Text("Bs ${e["precioh"] ?? 0}")),
                              DataCell(Text((e["tipo_pago"] ?? "-").toString())),
                              DataCell(
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0054A6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ComprobanteView(idHistorial: e["id"]),
                                      ),
                                    );
                                  },
                                  child: const Text("Ver Comprobante", style: TextStyle(fontSize: 11)),
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
            ],
          ),
        ),
      ),
    ),
  );
}

  // ================= PDF =================
  Future<void> _downloadPdf() async {
    setState(() => loadingPdf = true);

    try {
      final bytes = await PdfService().buildHistorialReportesPdf(
  filteredData,
  "REPORTE DE HISTORIAL - POR MES $tituloReporte",""
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
      final bytes = await PdfService().buildHistorialReportesPdf(
  filteredData,
  "REPORTE DE HISTORIAL - POR MES $tituloReporte","");

      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } finally {
      setState(() => loadingPrint = false);
    }
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
}