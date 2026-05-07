import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class IngresosEgresosRangePage extends StatefulWidget {
  const IngresosEgresosRangePage({super.key});

  @override
  State<IngresosEgresosRangePage> createState() =>
      _IngresosEgresosRangePageState();
}

class _IngresosEgresosRangePageState
    extends State<IngresosEgresosRangePage> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = false;
  bool loadingPrint = false;

  double ingresos = 0;
  double egresos = 0;
  double balance = 0;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  DateTime selectedDate = DateTime.now();
  DateTime? fechaInicio;
DateTime? fechaFin;

bool calculated = false;

  List<Map<String, dynamic>> resumenPorDia = [];

  bool get canShowDashboard =>
    fechaInicio != null &&
    fechaFin != null &&
    resumenPorDia.isNotEmpty;

  @override
  void initState() {
    super.initState();
  }

  /// ================= LOAD DATA =================
  Future<void> _loadData() async {
  setState(() => loading = true);

  final start = DateTime(
    fechaInicio!.year,
    fechaInicio!.month,
    fechaInicio!.day,
  );

  final end = DateTime(
    fechaFin!.year,
    fechaFin!.month,
    fechaFin!.day,
    23,
    59,
    59,
  );

  Map<String, double> ingresosMap = {};
  Map<String, double> egresosMap = {};

  /// ================= INGRESOS =================
  final ingresosSnap = await _db
    .collection("ingresos")
    .where("fecha",
        isGreaterThanOrEqualTo: Timestamp.fromDate(start))
    .where("fecha",
        isLessThanOrEqualTo: Timestamp.fromDate(end))
    .get();

for (var doc in ingresosSnap.docs) {
  final data = doc.data();

  final timestamp = data["fecha"];
  if (timestamp == null) continue;

  final fecha = (timestamp as Timestamp).toDate();
  final key = DateFormat("yyyy-MM-dd").format(fecha);

  final montoRaw = data["monto"];
  final value = (montoRaw is num)
      ? montoRaw.toDouble()
      : double.tryParse(montoRaw?.toString() ?? "0") ?? 0;

  ingresosMap[key] = (ingresosMap[key] ?? 0) + value;
}

  /// ================= EGRESOS =================
  final egresosSnap = await _db
      .collection("egresos")
      .where("fecha",
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where("fecha",
          isLessThanOrEqualTo: Timestamp.fromDate(end))
      .get();

  for (var doc in egresosSnap.docs) {
    final fecha = (doc["fecha"] as Timestamp).toDate();

    final key = DateFormat("yyyy-MM-dd").format(fecha);

    final value = (doc["monto"] as num).toDouble();

    egresosMap[key] = (egresosMap[key] ?? 0) + value;
  }

  /// ================= RESUMEN =================
  final keys = {...ingresosMap.keys, ...egresosMap.keys}.toList()
    ..sort();

  resumenPorDia = keys.map((k) {
    final ing = ingresosMap[k] ?? 0;
    final egr = egresosMap[k] ?? 0;

    return {
      "fecha": k,
      "ingresos": ing,
      "egresos": egr,
      "balance": ing - egr,
    };
  }).toList();

  ingresos = resumenPorDia.fold(0, (a, b) => a + (b["ingresos"] as double));
  egresos = resumenPorDia.fold(0, (a, b) => a + (b["egresos"] as double));
  balance = ingresos - egresos;

  setState(() => loading = false);
}

Future<void> _pickFechaInicio() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: fechaInicio ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    locale: const Locale('es', 'ES'),
  );

  if (picked != null) {
    setState(() {
      fechaInicio = picked;
      calculated = false;
    });
  }
}

Future<void> _pickFechaFin() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: fechaFin ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    locale: const Locale('es', 'ES'),
  );

  if (picked != null) {
    setState(() {
      fechaFin = picked;
      calculated = false;
    });
  }
}

String formatDate(DateTime d) {
  return DateFormat("dd/MM/yyyy").format(d);
}

String get rangoTexto {
  if (fechaInicio == null || fechaFin == null) return "";
  return "${formatDate(fechaInicio!)} - ${formatDate(fechaFin!)}";
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

Future<void> _calcular() async {
  if (fechaInicio == null || fechaFin == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Seleccione ambas fechas")),
    );
    return;
  }

  if (fechaInicio!.isAfter(fechaFin!)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rango inválido")),
    );
    return;
  }

  setState(() => calculated = true);
  await _loadData();
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
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
  final screenWidth = MediaQuery.of(context).size.width;

   return LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 700;

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
          child: Column(
        children: [

          /// HEADER

          isMobile
    ? Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            canShowDashboard ? "Finanzas (Entre fechas)" : "Finanzas",
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
              _btn(Icons.print, "Imprimir", Colors.green, _imprimirPdfReportes),
              _btn(Icons.download, "Descargar", Color(0xFF0054A6), _descargarPdfReportes),
              _btn(Icons.add, "Registrar Egreso", Colors.redAccent, _showAddEgreso),
            ],
          )
        ],
      )
    : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            calculated ? "Finanzas (Entre fechas)" : "Finanzas",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            children: [
              _btn(Icons.print, "Imprimir", Colors.green, _imprimirPdfReportes),
              _btn(Icons.download, "Descargar", Color(0xFF0054A6), _descargarPdfReportes),
              _btn(Icons.add, "Registrar Egreso", Colors.redAccent, _showAddEgreso),
            ],
          )
        ],
      ),

          const SizedBox(height: 20),

           const SizedBox(height: 10),

/// ================= SELECTORES =================

isMobile
    ? Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFechaInicio,
              icon: const Icon(Icons.calendar_month),
              label: Text(
                fechaInicio == null
                    ? "Fecha inicio"
                    : formatDate(fechaInicio!),
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickFechaFin,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                fechaFin == null
                    ? "Fecha fin"
                    : formatDate(fechaFin!),
              ),
            ),
          ),
        ],
      )
    : 
Row(
  children: [
    Expanded(
      child: OutlinedButton.icon(
        onPressed: _pickFechaInicio,
        icon: const Icon(Icons.calendar_month),
        label: Text(
          fechaInicio == null
              ? "Fecha inicio"
              : formatDate(fechaInicio!),
        ),
      ),
    ),

    const SizedBox(width: 10),

    Expanded(
      child: OutlinedButton.icon(
        onPressed: _pickFechaFin,
        icon: const Icon(Icons.calendar_today),
        label: Text(
          fechaFin == null
              ? "Fecha fin"
              : formatDate(fechaFin!),
        ),
      ),
    ),
  ],
),
const SizedBox(height: 15),

/// ================= BOTÓN ABAJO =================
SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () async {
  if (fechaInicio == null || fechaFin == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Seleccione fecha inicio y fin"),
      ),
    );
    return;
  }

  await _calcular();
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

/// ================= BLOQUEO UI =================
if (!canShowDashboard)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(40),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: const Text(
      "Seleccione fecha inicio y fin y presione Calcular",
      style: TextStyle(fontSize: 16, color: Colors.white70),
    ),
  )
else ...[

          /// AVISO
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

          /// CARDS
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

          /// BARRAS
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: resumenPorDia.asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                        toY: (e.value["balance"] ?? 0).toDouble(),
                        color: e.value["balance"] >= 0
                            ? Colors.green
                            : Colors.red)
                  ]);
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// PIE
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
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

          // ================= TABLE (PRO STYLE FIXED) =================
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
            (states) {
              if (states.contains(MaterialState.selected)) {
                return Color(0xFF0054A6).withOpacity(0.1);
              }
              return null;
            },
          ),

          columnSpacing: isMobile ? 12 : 20,
          horizontalMargin: isMobile ? 10 : 16,

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
                    color: e["balance"] >= 0
                        ? Colors.green
                        : Colors.red,
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
      ]),
    ))))
    
    );
  });
  }

  Widget _btn(IconData icon, String text, Color color, VoidCallback? onTap) {
  return ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(text),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
    ),
  );
}

  Widget _card(String title, double value, Color color) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color, width: 1.5),
    ),
    child: Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
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
    fechaInicio!.year,
    fechaInicio!.month,
    fechaInicio!.day,
  );

  final end = DateTime(
    fechaFin!.year,
    fechaFin!.month,
    fechaFin!.day,
  ).add(const Duration(days: 1));

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

  /// ================= ORDENAR =================
  movimientos.sort((a, b) {
    final faRaw = a["fecha"];
    final fbRaw = b["fecha"];

    final fa = faRaw is Timestamp
        ? faRaw.toDate()
        : DateTime.now();

    final fb = fbRaw is Timestamp
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
    titulo: "REPORTE FINANCIERO ($rangoTexto)",
rango:
  "Desde: ${formatDate(fechaInicio!)}\n"
  "Hasta: ${formatDate(fechaFin!)}\n"
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
    titulo: "REPORTE FINANCIERO ($rangoTexto)",
rango:
  "Desde: ${formatDate(fechaInicio!)}\n"
  "Hasta: ${formatDate(fechaFin!)}\n"
  "Ingresos: Bs $ingresos | Egresos: Bs $egresos | Balance: Bs $balance",
    ingresos: ingresos,
    egresos: egresos,
    balance: balance,
    resumenPorDia: data["resumenPorDia"],
    movimientos: data["movimientos"],
  );

  final fileName =
      "reporte_financiero_${fechaSeleccionadaTexto.replaceAll('/', '-')}.pdf";

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