import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class FinanzasLast7DaysPage extends StatefulWidget {
  const FinanzasLast7DaysPage({super.key});

  @override
  State<FinanzasLast7DaysPage> createState() =>
      _FinanzasLast7DaysPageState();
}

class _FinanzasLast7DaysPageState
    extends State<FinanzasLast7DaysPage> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = true;
  bool loadingPrint = false;

  double ingresos = 0;
  double egresos = 0;
  double balance = 0;

  List<Map<String, dynamic>> resumenPorDia = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// ================= LOAD DATA =================
  Future<void> _loadData() async {
  setState(() => loading = true);

  print("🚀 INICIANDO LOAD DATA FINANZAS");

  try {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    print("📅 START: $start");
    print("📅 END: $end");

    // ================= INGRESOS =================
    print("🔵 consultando historial_v2...");

    final historial = await FirebaseFirestore.instance
        .collection("ingresos")
        .where("fecha",
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where("fecha",
            isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    print("🔵 ingresos docs: ${historial.docs.length}");

    // ================= EGRESOS =================
    print("🔴 consultando egresos...");

    final egresosSnap = await FirebaseFirestore.instance
        .collection("egresos")
        .where("fecha",
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where("fecha",
            isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    print("🔴 egresos docs: ${egresosSnap.docs.length}");

    // ================= PROCESO =================
    print("⚙️ procesando datos...");

    Map<String, double> ingresosMap = {};
    Map<String, double> egresosMap = {};

    for (var doc in historial.docs) {
      final d = doc.data();

      final fecha = (d["fecha"] as Timestamp?)?.toDate();
      if (fecha == null) continue;

      final key = DateFormat("dd/MM/yyyy").format(fecha);

      final montoRaw = d["monto"];
      final value = (montoRaw is num)
          ? montoRaw.toDouble()
          : double.tryParse(montoRaw?.toString() ?? "0") ?? 0;

      ingresosMap[key] = (ingresosMap[key] ?? 0) + value;
    }

    for (var doc in egresosSnap.docs) {
      final d = doc.data();

      final fecha = (d["fecha"] as Timestamp?)?.toDate();
      if (fecha == null) continue;

      final key = DateFormat("dd/MM/yyyy").format(fecha);

      final value = (d["monto"] as num?)?.toDouble() ?? 0;

      egresosMap[key] = (egresosMap[key] ?? 0) + value;
    }

    print("📊 ingresosMap: ${ingresosMap.length}");
    print("📊 egresosMap: ${egresosMap.length}");

    final keys = {...ingresosMap.keys, ...egresosMap.keys};

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

    ingresos = resumenPorDia.fold(0, (a, b) => a + (b["ingresos"] ?? 0));
    egresos = resumenPorDia.fold(0, (a, b) => a + (b["egresos"] ?? 0));
    balance = ingresos - egresos;

    print("✅ FINAL OK");

  } catch (e, stack) {
    print("❌ ERROR FINANZAS: $e");
    print(stack);
  }

  setState(() {
    loading = false;
  });

  print("🏁 LOAD DATA TERMINADO");
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
          Wrap(
  spacing: 10,
  runSpacing: 10,
  alignment: WrapAlignment.spaceBetween,
  children: [
              const Text(
                "Finanzas (Últimos 7 días)",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [

                  ElevatedButton.icon(
                    onPressed: (loadingPrint || resumenPorDia.isEmpty) ? null : _imprimirPdfReportes,
                    icon: const Icon(Icons.print),
                    label: const Text("Imprimir"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                          foregroundColor: Colors.white
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: (loadingPrint || resumenPorDia.isEmpty) ? null : _descargarPdfReportes,
                    icon: const Icon(Icons.download),
                    label: const Text("Descargar"),
                      style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                          foregroundColor: Colors.white
                    ),
                  ),
        

                  ElevatedButton.icon(
                    onPressed: _showAddEgreso,
                    icon: const Icon(Icons.add),
                    label: const Text("Registrar Egreso"),
                      style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white
                    ),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 20),

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
            children: [
              _card("Ingresos", ingresos, Colors.green),
              _card("Egresos", egresos, Colors.red),
              _card("Balance", balance,
                  balance >= 0 ? Colors.green : Colors.red),
            ],
          ),

          const SizedBox(height: 25),

          /// BARRAS
          Container(
  padding: const EdgeInsets.all(12),
  margin: const EdgeInsets.symmetric(vertical: 10),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.black26,
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 3),
      )
    ],
  ),
  child: SizedBox(
    height: 240,
    child: BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.black12),
        ),
        barGroups: resumenPorDia.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value["balance"] ?? 0).toDouble(),
                width: 14,
                borderRadius: BorderRadius.circular(4),
                color: e.value["balance"] >= 0
                    ? Colors.green
                    : Colors.red,
              )
            ],
          );
        }).toList(),
      ),
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
    :
                
                 [
                  PieChartSectionData(
                    titleStyle: TextStyle(color: Colors.black),
                      value: ingresos,
                      title: "Ingresos",
                      color: Colors.green),
                  PieChartSectionData(
                    titleStyle: TextStyle(color: Colors.black),
                      value: egresos,
                      title: "Egresos",
                      color: Colors.red),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// TABLA
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
                return Colors.blue.withOpacity(0.1);
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
      ),
    )))));
  }

  Widget _card(String title, double value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Text(
              "Bs ${value.toStringAsFixed(2)}",
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _buildPdfData() async {
  final now = DateTime.now();
  final last7 = now.subtract(const Duration(days: 7));

  /// 🔵 INGRESOS
 final ingresosSnap = await _db
    .collection("ingresos")
    .where("fecha",
        isGreaterThanOrEqualTo: Timestamp.fromDate(last7))
    .get();

  /// 🔴 EGRESOS
  final egresosSnap = await _db
      .collection("egresos")
      .where("fecha",
          isGreaterThanOrEqualTo: Timestamp.fromDate(last7))
      .get();

  /// 🔥 LISTA DETALLADA (para tabla)
  final List<Map<String, dynamic>> movimientos = [];

  /// INGRESOS
  /// INGRESOS
for (var doc in ingresosSnap.docs) {
  final d = doc.data();

  movimientos.add({
    "tipo": "INGRESO",
    "fecha": d["fecha"],
    "descripcion": d["descripcion"] ?? "",

    // 🔥 NORMALIZACIÓN
    "categoria": d["origen"] ?? "ingreso",
    "monto": d["monto"] ?? 0,
    "metodo_pago": d["tipo_pago"] ?? "-",

    "cliente": d["id_cliente"] ?? "-",
    "mascota": "-",
  });
}

  /// EGRESOS
  for (var doc in egresosSnap.docs) {
  final d = doc.data();

  movimientos.add({
    "tipo": "EGRESO",
    "fecha": d["fecha"],
    "descripcion": d["descripcion"] ?? "",

    // 🔥 MISMO NOMBRE FINAL
    "categoria": d["categoria"] ?? "egreso",
    "monto": d["monto"] ?? 0,
    "metodo_pago": d["metodo_pago"] ?? "-",

    "cliente": "-",
    "mascota": "-",
  });
}

  /// 🔥 ORDENAR POR FECHA DESC
  movimientos.sort((a, b) {
    final fa = (a["fecha"] as Timestamp?)?.toDate() ?? DateTime.now();
    final fb = (a["fecha"] as Timestamp?)?.toDate() ?? DateTime.now();
    return fb.compareTo(fa);
  });

  return {
    "movimientos": movimientos,
    "resumenPorDia": resumenPorDia, // 👈 ya lo tienes calculado en UI
  };
}
Future<void> _imprimirPdfReportes() async {
  setState(() => loadingPrint = true);

  final data = await _buildPdfData();

  final pdfBytes = await PdfService().buildFinanzasReportPdf(
    titulo: "REPORTE FINANCIERO (7 DÍAS)",
    rango:
        "Ingresos: Bs $ingresos | Egresos: Bs $egresos | Balance: Bs $balance",
    ingresos: ingresos,
    egresos: egresos,
    balance: balance,
    resumenPorDia: data["resumenPorDia"],
    movimientos: data["movimientos"], // 🔥 NUEVO
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
  titulo: "REPORTE FINANCIERO (7 DÍAS)",
  rango:
      "Ingresos: Bs $ingresos | Egresos: Bs $egresos | Balance: Bs $balance",
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

}