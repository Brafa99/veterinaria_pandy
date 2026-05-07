import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class IngresosEgresosDayPage extends StatefulWidget {
  const IngresosEgresosDayPage({super.key});

  @override
  State<IngresosEgresosDayPage> createState() =>
      _IngresosEgresosDayPageState();
}

class _IngresosEgresosDayPageState
    extends State<IngresosEgresosDayPage> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = false;
  bool loadingPrint = false;

  double ingresos = 0;
  double egresos = 0;
  double balance = 0;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  DateTime selectedDate = DateTime.now();
  bool calculated = false;

  List<Map<String, dynamic>> resumenPorDia = [];

  @override
  void initState() {
    super.initState();
  }

  /// ================= LOAD DATA =================
  Future<void> _loadData() async {
  setState(() => loading = true);

  try {
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final end = start.add(const Duration(days: 1));

    double totalIngresos = 0;
    double totalEgresos = 0;

    /// ================= INGRESOS =================
   final ingresosSnap = await _db
    .collection("ingresos")
    .where(
      "fecha",
      isGreaterThanOrEqualTo: Timestamp.fromDate(start),
    )
    .where(
      "fecha",
      isLessThan: Timestamp.fromDate(end),
    )
    .get();

for (final doc in ingresosSnap.docs) {
  final data = doc.data();

  final monto = data["monto"];

  final value = (monto is num)
      ? monto.toDouble()
      : double.tryParse(monto.toString()) ?? 0;

  totalIngresos += value;
}

    /// ================= EGRESOS =================
    final egresosSnap = await _db
        .collection("egresos")
        .where(
          "fecha",
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          "fecha",
          isLessThan: Timestamp.fromDate(end),
        )
        .get();

    for (final doc in egresosSnap.docs) {
      final data = doc.data();

      final monto = data["monto"];

      final value = (monto is num)
          ? monto.toDouble()
          : double.tryParse(monto.toString()) ?? 0;

      totalEgresos += value;
    }

    /// ================= RESULTADOS =================
    ingresos = totalIngresos;
    egresos = totalEgresos;
    balance = ingresos - egresos;

    resumenPorDia = [
      {
        "fecha": DateFormat("dd/MM/yyyy").format(start),
        "ingresos": ingresos,
        "egresos": egresos,
        "balance": balance,
      }
    ];

    setState(() => loading = false);
  } catch (e, stack) {
    debugPrint("❌ ERROR FINANZAS DIA: $e");
    debugPrint("STACK: $stack");
    setState(() => loading = false);
  }
}
  /// ================= FORM EGRESO PRO =================
  Future<void> _showAddEgreso() async {
    final formKey = GlobalKey<FormState>();
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    String categoria = "compra";
    String metodo = "EFECTIVO";

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text("Registrar Egreso",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: _input("Categoría"),
                  items: [
                    "compra",
                    "servicio",
                    "salario",
                    "otro"
                  ].map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => categoria = v!,
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: metodo,
                  decoration: _input("Método de pago"),
                  items: [
                    "EFECTIVO",
                    "QR",
                    "TARJETA"
                  ].map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => metodo = v!,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: montoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _input("Monto (Bs)"),
                  validator: (v) =>
                      v!.isEmpty ? "Ingrese monto" : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: descCtrl,
                  decoration: _input("Descripción"),
                  validator: (v) =>
                      v!.isEmpty ? "Ingrese descripción" : null,
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar")),

                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        await _db.collection("egresos").add({
                          "monto":
                              double.parse(montoCtrl.text),
                          "descripcion": descCtrl.text,
                          "categoria": categoria,
                          "metodo_pago": metodo,
                          "fecha": Timestamp.now(),
                        });

                        Navigator.pop(context);
                        _loadData();
                      },
                      child: const Text("Guardar"),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    locale: const Locale('es', 'ES'),
  );

  if (picked != null) {
    setState(() {
      selectedDate = picked;
      calculated = false; // obligar recalculo
    });
  }
}

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// ================= UI =================
  /// ================= UI =================
@override
Widget build(BuildContext context) {
  if (loading) {
    return const Center(child: CircularProgressIndicator());
  }
  final screenWidth = MediaQuery.of(context).size.width;

  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
          scrollbars: true,
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
          },
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;

                return Column(
                  children: [

                    // ================= HEADER =================
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                calculated
                                    ? "Finanzas (Día - $fechaSeleccionadaTexto)"
                                    : "Finanzas (Por Día)",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _btnPrint(),
                                  _btnDownload(),
                                  _btnAddEgreso(),
                                ],
                              ),
                            ],
                          )
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  calculated
                                      ? "Finanzas (Día - $fechaSeleccionadaTexto)"
                                      : "Finanzas (Por Día)",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Wrap(
                                spacing: 10,
                                children: [
                                  _btnPrint(),
                                  _btnDownload(),
                                  _btnAddEgreso(),
                                ],
                              )
                            ],
                          ),
                    const SizedBox(height: 12),

                          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: const Text(
              "Los Ingresos se calculan automáticamente desde el historial y ventas. "
              "Los Egresos se registran manualmente.",
              style: TextStyle(color: Colors.black),
            ),
          ),

                    const SizedBox(height: 20),

                    // ================= DATE PICKER =================
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              DateFormat("dd MMM yyyy", "es_ES")
                                  .format(selectedDate),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    // ================= BUTTON =================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          setState(() => calculated = true);
                          await _loadData();
                        },
                        icon: const Icon(Icons.calculate),
                        label: const Text("Calcular"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0054A6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= BLOCK =================
                    if (!calculated)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          "Seleccione una fecha y presione Calcular",
                        ),
                      )

                      
                    else ...[

                      const SizedBox(height: 20),

                      // ================= CARDS =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _card("Ingresos", ingresos, Colors.green),
              _card("Egresos", egresos, Colors.red),
              _card("Balance", balance,
                  balance >= 0 ? Colors.green : Colors.red),
            ],
          ),

                      const SizedBox(height: 25),

                      // ================= BAR =================
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            titlesData: FlTitlesData(show: false),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                            barGroups: resumenPorDia.asMap().entries.map((e) {
                              return BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: (e.value["balance"] ?? 0).toDouble(),
                                    width: isMobile ? 8 : 14,
                                    color: e.value["balance"] >= 0
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ================= PIE =================
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 30,
                            sectionsSpace: 2,
                            sections: ((ingresos + egresos) == 0)
                                ? [
                                    PieChartSectionData(
                                      value: 1,
                                      title: "Sin datos",
                                      color: Colors.grey,
                                    )
                                  ]
                                : [
                                    PieChartSectionData(
                                      value: ingresos,
                                      title: "Ingresos",
                                      color: Colors.green,
                                      titleStyle:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    PieChartSectionData(
                                      value: egresos,
                                      title: "Egresos",
                                      color: Colors.red,
                                      titleStyle:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // ================= TABLE =================
                      // ================= TABLE (PRO STYLE) =================
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade800, width: 1.2),
    borderRadius: BorderRadius.circular(10),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
  constraints: BoxConstraints(
    minWidth: screenWidth < 600 ? 600 : screenWidth, // 🔥 clave
  ),
  child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            const Color(0xFF2A2A3D),
          ),

          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return Color(0xFF0054A6).withOpacity(0.1);
              }
              return null;
            },
          ),

          columnSpacing: 20,
          horizontalMargin: 16,

          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),

          dataTextStyle: const TextStyle(
            color: Colors.white70,
          ),

          columns: const [
            DataColumn(label: Text("Fecha")),
            DataColumn(label: Text("Ingresos")),
            DataColumn(label: Text("Egresos")),
            DataColumn(label: Text("Balance")),
          ],

          rows: List.generate(resumenPorDia.length, (index) {
            final e = resumenPorDia[index];

            return DataRow(
              color: MaterialStateProperty.all(
                index % 2 == 0
                    ? const Color(0xFF1E1E2D)
                    : const Color(0xFF252537),
              ),
              cells: [
                DataCell(Text(e["fecha"])),

                DataCell(Text(
                  "Bs ${e["ingresos"]}",
                  style: const TextStyle(color: Colors.green),
                )),

                DataCell(Text(
                  "Bs ${e["egresos"]}",
                  style: const TextStyle(color: Colors.red),
                )),

                DataCell(Text(
                  "Bs ${e["balance"]}",
                  style: TextStyle(
                    color: e["balance"] >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            );
          }),
        ),
      ),
    ),
  ),
)
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _btnPrint() {
  return ElevatedButton.icon(
    onPressed: loadingPrint ? null : _imprimirPdfReportes,
    icon: const Icon(Icons.print),
    label: const Text("Imprimir"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
  );
}

Widget _btnDownload() {
  return ElevatedButton.icon(
    onPressed: loadingPrint ? null : _descargarPdfReportes,
    icon: const Icon(Icons.download),
    label: const Text("Descargar"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF0054A6),
      foregroundColor: Colors.white,
    ),
  );
}

Widget _btnAddEgreso() {
  return ElevatedButton.icon(
    onPressed: _showAddEgreso,
    icon: const Icon(Icons.add),
    label: const Text("Registrar Egreso"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF0054A6),
      foregroundColor: Colors.white,
    ),
  );
}

  Widget _card(String title, double value, Color color) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color, width: 1.5),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        Text(
          "Bs ${value}",
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

  Future<Map<String, dynamic>> _buildPdfData() async {

  final start = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );

  final end = start.add(const Duration(days: 1));

  /// 🔵 INGRESOS (NUEVA COLECCIÓN)
  final ingresosSnap = await _db
      .collection("ingresos")
      .where("fecha",
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where("fecha",
          isLessThan: Timestamp.fromDate(end))
      .get();

  /// 🔴 EGRESOS
  final egresosSnap = await _db
      .collection("egresos")
      .where("fecha",
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where("fecha",
          isLessThan: Timestamp.fromDate(end))
      .get();

  final List<Map<String, dynamic>> movimientos = [];

  /// ================= INGRESOS =================
  for (var doc in ingresosSnap.docs) {
    final d = doc.data();

    final montoRaw = d["monto"];
    final monto = (montoRaw is num)
        ? montoRaw.toDouble()
        : double.tryParse(montoRaw?.toString() ?? "0") ?? 0;

    movimientos.add({
      "tipo": "INGRESO",
      "fecha": d["fecha"],
      "descripcion": d["descripcion"] ?? "",

      // 🔥 NORMALIZADO
      "categoria": d["origen"] ?? "ingreso",
      "monto": monto,
      "metodo_pago": d["tipo_pago"] ?? "-",

      "cliente": d["id_cliente"] ?? "-",
      "mascota": "-",
    });
  }

  /// ================= EGRESOS =================
  for (var doc in egresosSnap.docs) {
    final d = doc.data();

    final montoRaw = d["monto"];
    final monto = (montoRaw is num)
        ? montoRaw.toDouble()
        : double.tryParse(montoRaw?.toString() ?? "0") ?? 0;

    movimientos.add({
      "tipo": "EGRESO",
      "fecha": d["fecha"],
      "descripcion": d["descripcion"] ?? "",
      "categoria": d["categoria"] ?? "egreso",
      "monto": monto,
      "metodo_pago": d["metodo_pago"] ?? "-",
      "cliente": "-",
      "mascota": "-",
    });
  }

  /// ================= ORDENAR (SAFE) =================
  movimientos.sort((a, b) {
    final faRaw = a["fecha"];
    final fbRaw = b["fecha"];

    DateTime fa = faRaw is Timestamp
        ? faRaw.toDate()
        : DateTime.now();

    DateTime fb = fbRaw is Timestamp
        ? fbRaw.toDate()
        : DateTime.now();

    return fb.compareTo(fa);
  });

  return {
    "movimientos": movimientos,
    "resumenPorDia": resumenPorDia,
  };
}

Future<void> _imprimirPdfReportes() async {
  setState(() => loadingPrint = true);

  final data = await _buildPdfData();

  final pdfBytes = await PdfService().buildFinanzasReportPdf(
    titulo: "REPORTE FINANCIERO (DÍA - $fechaSeleccionadaTexto)",
    rango:
        "Fecha: $fechaSeleccionadaTexto\n"
        "Ingresos: Bs $ingresos | Egresos: Bs $egresos | Balance: Bs $balance",
    ingresos: ingresos,
    egresos: egresos,
    balance: balance,
    resumenPorDia: data["resumenPorDia"],
    movimientos: data["movimientos"],
  );

  await Printing.layoutPdf(
    onLayout: (_) async => pdfBytes,
  );

  setState(() => loadingPrint = false);
}

Future<void> _descargarPdfReportes() async {
  setState(() => loadingPrint = true);

  final data = await _buildPdfData();

  final pdfBytes = await PdfService().buildFinanzasReportPdf(
  titulo: "REPORTE FINANCIERO (DÍA)",
  rango: DateFormat("dd/MM/yyyy").format(selectedDate),
  ingresos: ingresos,
  egresos: egresos,
  balance: balance,
  resumenPorDia: data["resumenPorDia"],
  movimientos: data["movimientos"],
);

  final fileName =
      "reporte_financiero_${DateTime.now().millisecondsSinceEpoch}.pdf";

  await FileService.saveOrDownload(pdfBytes, fileName);

  setState(() => loadingPrint = false);
}

String get fechaSeleccionadaTexto {
  return DateFormat("dd/MM/yyyy").format(selectedDate);
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