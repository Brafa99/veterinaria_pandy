import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';

class IngresosEgresosMonthPage extends StatefulWidget {
  const IngresosEgresosMonthPage({super.key});

  @override
  State<IngresosEgresosMonthPage> createState() =>
      _IngresosEgresosMonthPageState();
}

class _IngresosEgresosMonthPageState
    extends State<IngresosEgresosMonthPage> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = false;
  bool loadingPrint = false;
  

  double ingresos = 0;
  double egresos = 0;
  double balance = 0;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  final _horizontalController = ScrollController();
  bool calculated = false; // 🔥 para no cargar automático

  List<Map<String, dynamic>> resumenPorDia = [];
  
   bool get showDashboard => calculated && resumenPorDia.isNotEmpty;
  @override
  void initState() {
    super.initState();
  }

  /// ================= LOAD DATA =================
  Future<void> _loadData() async {
  setState(() => loading = true);

  try {
    /// ================= RANGO MES =================
    final start = DateTime(selectedYear, selectedMonth, 1);

    /// evita error en diciembre (mes 13)
    final end = (selectedMonth == 12)
        ? DateTime(selectedYear + 1, 1, 1)
        : DateTime(selectedYear, selectedMonth + 1, 1);

    Map<String, double> ingresosMap = {};
    Map<String, double> egresosMap = {};

    /// ================= INGRESOS =================
    final historialSnap = await _db
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

    for (final doc in historialSnap.docs) {
      final data = doc.data();

      final timestamp = data["fecha"];
      if (timestamp == null) continue;

      final fecha = (timestamp as Timestamp).toDate();
      final key = DateFormat("dd/MM/yyyy").format(fecha);

      final monto = (data["monto"] as num?)?.toDouble() ?? 0;

      ingresosMap[key] = (ingresosMap[key] ?? 0) + monto;
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

      final timestamp = data["fecha"];
      if (timestamp == null) continue;

      final fecha = (timestamp as Timestamp).toDate();
      final key = DateFormat("dd/MM/yyyy").format(fecha);

      final monto = (data["monto"] as num?)?.toDouble() ?? 0;

      egresosMap[key] = (egresosMap[key] ?? 0) + monto;
    }

    /// ================= RESUMEN =================
    final keys = {
      ...ingresosMap.keys,
      ...egresosMap.keys,
    }.toList()
      ..sort((a, b) {
        final da = DateFormat("dd/MM/yyyy").parse(a);
        final db = DateFormat("dd/MM/yyyy").parse(b);
        return da.compareTo(db);
      });

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

    /// ================= TOTALES =================
    ingresos = resumenPorDia.fold(0.0, (a, b) => a + (b["ingresos"] as double));
    egresos = resumenPorDia.fold(0.0, (a, b) => a + (b["egresos"] as double));
    balance = ingresos - egresos;

    /// ================= FIN =================
    setState(() => loading = false);
  } catch (e, stack) {
    debugPrint("❌ ERROR _loadData FINANZAS MES: $e");
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
  return SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
    
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
    
                    // ================= HEADER =================
                    _buildHeader(isMobile),
    
                    const SizedBox(height: 20),
    
                    // ================= SELECTORES =================
                    _buildSelectors(isMobile),
    
                    const SizedBox(height: 15),
    
                    // ================= BOTÓN =================
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
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
    
                    const SizedBox(height: 20),
    
                    // ================= BLOQUEO UI =================
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
                          "Seleccione mes y año, luego presione Calcular",
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      )
                    else ...[
    
                      // ================= INFO =================
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
    
                      // ================= BAR CHART =================
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
    width: double.infinity,
    height: isMobile ? 180 : 240,
    padding: const EdgeInsets.all(12),
                          child: BarChart(
                            BarChartData(
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
                      ),
    
                      const SizedBox(height: 5),
    
                      // ================= PIE =================
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
                      // ================= TABLE (PRO STYLE) =================
Container(
  width: double.infinity,
  constraints: const BoxConstraints(maxHeight: 420),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.shade800, width: 1.2),
    borderRadius: BorderRadius.circular(10),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: ScrollConfiguration(
      behavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            notificationPredicate: (n) =>
                n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth:
                      screenWidth < 600 ? 650 : screenWidth, // 🔥 leve aumento
                ),
                child: DataTable(
                  columnSpacing: 24, // 🔥 aumenta separación → fuerza overflow
                  horizontalMargin: 20,

                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFF2A2A3D),
                  ),

                  dataRowColor:
                      MaterialStateProperty.resolveWith<Color?>(
                    (states) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.blue.withOpacity(0.1);
                      }
                      return null;
                    },
                  ),

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
        ),
      ),
    ),
  ),
)
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildHeader(bool isMobile) {
  final title = calculated
      ? "Finanzas (Mes - ${formatDateText2(selectedMonth)})"
      : "Finanzas (Por Mes)";

  final buttons = Wrap(
    spacing: 10,
    runSpacing: 10,
    alignment: WrapAlignment.center,
    children: [
      _btnPrint(),
      _btnDownload(),
      _btnAddEgreso(),
    ],
  );

  return isMobile
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buttons,
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Flexible(child: buttons),
          ],
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
      backgroundColor: Colors.blue,
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
      backgroundColor: Colors.redAccent,
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

  Widget _buildSelectors(bool isMobile) {
  return isMobile
      ? Column(
          children: [_month(), const SizedBox(height: 10), _year()],
        )
      : Row(
          children: [
            Expanded(child: _month()),
            const SizedBox(width: 15),
            Expanded(child: _year()),
          ],
        );
}

Widget _month() => DropdownButtonFormField<int>(
      value: selectedMonth,
      decoration: _input("Mes"),
      items: List.generate(
        12,
        (i) => DropdownMenuItem(
          value: i + 1,
          child: formatDateText(i + 1),
        ),
      ),
      onChanged: (v) => setState(() => selectedMonth = v!),
    );

Widget _year() => DropdownButtonFormField<int>(
      value: selectedYear,
      decoration: _input("Año"),
      items: List.generate(
        10,
        (i) => DropdownMenuItem(
          value: DateTime.now().year - i,
          child: Text("${DateTime.now().year - i}"),
        ),
      ),
      onChanged: (v) => setState(() => selectedYear = v!),
    );

  Future<Map<String, dynamic>> _buildPdfData() async {

  /// ================= RANGO MES (SEGURO) =================
  final start = DateTime(selectedYear, selectedMonth, 1);

  final end = (selectedMonth == 12)
      ? DateTime(selectedYear + 1, 1, 1)
      : DateTime(selectedYear, selectedMonth + 1, 1);

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

      /// 🔥 CLASIFICACIÓN LEGIBLE
      "categoria": d["origen"] == "historial"
          ? "Servicio"
          : d["origen"] == "venta"
              ? "Venta"
              : "Ingreso",

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
      "categoria": d["categoria"] ?? "Egreso",
      "monto": monto,
      "metodo_pago": d["metodo_pago"] ?? "-",
      "cliente": "-",
      "mascota": "-",
    });
  }

  /// ================= ORDENAR (SEGURO) =================
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

final mesTexto = DateFormat.MMMM().format(DateTime(0, selectedMonth));

  final pdfBytes = await PdfService().buildFinanzasReportPdf(
    titulo: "REPORTE FINANCIERO ($mesTexto $selectedYear)",
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
  final mesTexto = DateFormat.MMMM().format(DateTime(0, selectedMonth));
  final pdfBytes = await PdfService().buildFinanzasReportPdf(
  titulo: "REPORTE FINANCIERO ($mesTexto $selectedYear)",
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

  String formatDateText2(int i) {
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
    return text_date;
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