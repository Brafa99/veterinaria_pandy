import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/services/file_service.dart';

class ComprobanteView extends StatelessWidget {
  final String idHistorial;

  const ComprobanteView({super.key, required this.idHistorial});
  
  @override
  Widget build(BuildContext context) {
    
    print("ID recibido: $idHistorial");
    return Scaffold(
      appBar: AppBar(
        
        title: const Text("Comprobante"),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
    .collection('historial_v2')
    .doc(idHistorial)
    .get()
    .then((doc) {
      print("EXISTS: ${doc.exists}");
      print("DATA RAW: ${doc.data()}");
      return doc;
    }),

  builder: (context, snapshot) {

    // 🔴 ERROR REAL
    if (snapshot.hasError) {
      return Center(
        child: Text("Error: ${snapshot.error}"),
      );
    }

    // 🟡 CARGANDO
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    // 🔴 NO EXISTE DOC
    if (!snapshot.hasData || !snapshot.data!.exists) {
      return Center(
        child: Text("No existe el documento: $idHistorial"),
      );
    }

    final data = snapshot.data!.data() as Map<String, dynamic>;

    return _buildComprobante(context, data);
  },
),
    );
  }

  Widget _infoRow(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 100,
        child: Text(
          "$label:",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

  // ================= UI =================
// ================= UI =================

Widget _buildComprobante(BuildContext context, Map<String, dynamic> data) {
  final fecha = (data['fecha_registro'] as Timestamp?)?.toDate();

  
  final precio = (data['precioh'] ?? 0).toString();

  final nitCi =
    (data['nit'] ?? '').toString().trim().isNotEmpty
        ? data['nit'].toString()
        : ((data['ci'] ?? '').toString().trim().isNotEmpty
            ? data['ci'].toString()
            : '-');

  return Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                ElevatedButton.icon(
                  onPressed: () => _printPdf(data),
                  icon: const Icon(Icons.print),
                  label: const Text("Imprimir",style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton.icon(
                  onPressed: () => _downloadPdf(data),
                  icon: const Icon(Icons.download),
                  label: const Text("Descargar", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),

                const SizedBox(width: 10),
             
              ],
            ),

            const SizedBox(height: 30),

            // ================= HEADER =================
            Center(
              child: Column(
                children: const [
                  Text(
                    "Veterinaria Pandy",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text("3409656016",style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= CLIENTE INFO =================

Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      // HEADER
      Row(
        children: const [
          Icon(Icons.person, size: 20, color: Colors.redAccent),
          SizedBox(width: 6),
          Text(
            "Información del Cliente",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),

      const Divider(height: 18),

      // CLIENTE
      _infoRow("Cliente", data['nombre_dueno'] ?? '-'),

      const SizedBox(height: 6),

     _infoRow("Teléfono", data['telefono'] ?? '-'),

const SizedBox(height: 6),

_infoRow("NIT / CI", nitCi),

const SizedBox(height: 6),

_infoRow("Mascota", data['nombre_mascota'] ?? '-'),
    ],
  ),
),

             SizedBox(height: 15),

            // ================= INFO =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ID CLIENTE°: "+data['id_cliente']),
                Text(
                  "Fecha: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : '-'}",
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(thickness: 1.5),

            const SizedBox(height: 10),

            // ================= CONCEPTO =================
            Container(
  width: double.infinity,
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Concepto de Servicio",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      /// 🔥 SCROLL CONTROLADO
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 600),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 20,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 200, // 🔥 permite crecer

              headingRowColor:
                  MaterialStateProperty.all(Colors.grey.shade200),

              border: TableBorder.all(
                color: Colors.grey.shade400,
                width: 1,
              ),

              columns: const [
                DataColumn(
                  label: Text("Descripción",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text("Tipo historial",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text("Monto",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text("Tipo Pago",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                DataColumn(
                  label: Text("Total",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],

              rows: [
                DataRow(
                  cells: [

                    /// 🔥 DESCRIPCIÓN FLEXIBLE
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 250,
                        ),
                        child: Text(
                          (data["descripcion"] ?? "").toString(),
                          softWrap: true,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),

                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          data["tipo_historial"] ?? "",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    DataCell(
                      SizedBox(
                        width: 80,
                        child: Text("Bs ${data["precioh"] ?? 0}"),
                      ),
                    ),

                    DataCell(
                      SizedBox(
                        width: 80,
                        child:
                        data["tipo_pago"]=="-" || data["tipo_pago"]==""
                        ?Text("")
                        :Text("${data["tipo_pago"] ?? ""}"),

                      ),
                    ),

                    DataCell(
                      SizedBox(
                        width: 80,
                        child: Text(" ${data["precioh"] ?? 0}"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 20),

            // ================= TOTAL =================
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "TOTAL: Bs. $precio",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // ================= FIRMAS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  children: [
                    Text("______________"),
                    SizedBox(height: 5),
                    Text("Veterinaria Pandy"),
                  ],
                ),
                Column(
                  children: [
                    Text("______________"),
                    SizedBox(height: 5),
                    Text("Recibí conforme"),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // ================= BOTONES =================
            
          ],
        ),
      ),
    ),
  ))
;
}

  // ================= PDF =================

 Future<Uint8List> _generatePdf(
  Map<String, dynamic> data,
  String idHistorial,
) async {
  final pdf = pw.Document();

  // ================= FECHA =================
  DateTime? fecha;
  final f = data['fecha_registro'];

  if (f is Timestamp) {
    fecha = f.toDate();
  } else if (f is String) {
    try {
      fecha = DateTime.parse(f);
    } catch (_) {}
  }

  final fechaStr =
      fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : "-";

      final nitCi =
    (data['nit'] ?? '').toString().trim().isNotEmpty
        ? data['nit'].toString()
        : ((data['ci'] ?? '').toString().trim().isNotEmpty
            ? data['ci'].toString()
            : '-');

  // ================= PRECIO =================
  double precio = 0;

  final raw = data['precioh'];
  if (raw is num) {
    precio = raw.toDouble();
  } else if (raw is String) {
    precio = double.tryParse(raw) ?? 0;
  }

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(25),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // ================= HEADER =================
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    "VETERINARIA PANDY",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text("3409656016"),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    "COMPROBANTE DE SERVICIO",
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Divider(),

            pw.SizedBox(height: 10),

            // ================= CLIENTE CARD =================
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Cliente: ${data['nombre_dueno'] ?? '-'}"),
                  pw.Text("Mascota: ${data['nombre_mascota'] ?? '-'}"),
                  pw.Text("Teléfono: ${data['telefono'] ?? '-'}"),
                  pw.Text("NIT / CI: $nitCi"),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // ================= INFO ROW =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("ID CLIENTE: ${data['id_cliente'] ?? "ID CLIENTE: ${data['id_historial']} "}"),
                pw.Text("Fecha: $fechaStr"),
              ],
            ),

            pw.SizedBox(height: 20),

            // ================= CONCEPTO FULL WIDTH =================
pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.all(10),
  decoration: pw.BoxDecoration(
    borderRadius: pw.BorderRadius.circular(8),
    border: pw.Border.all(color: PdfColors.grey400),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [

      pw.Text(
        "Concepto de Servicio",
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),

      pw.SizedBox(height: 10),

      /// 🔥 TABLA REAL (igual a Flutter)
      pw.Table(
        border: pw.TableBorder.all(
          color: PdfColors.grey500,
          width: 0.7,
        ),

        columnWidths: {
  0: const pw.FlexColumnWidth(3.5), // descripción ↓
  1: const pw.FlexColumnWidth(1.8),
  2: const pw.FlexColumnWidth(1.3),
  3: const pw.FlexColumnWidth(1.3),
  4: const pw.FlexColumnWidth(1.6), // 🆕 tipo pago
},

        children: [

          /// HEADER
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            children: [
              _pdfCellHeader("Descripción"),
              _pdfCellHeader("Tipo historial"),
              _pdfCellHeader("Monto"),
              _pdfCellHeader("Tipo Pago"),
              _pdfCellHeader("Total"),
            ],
          ),

          /// DATA
          pw.TableRow(
            children: [
              
              /// 🔥 DESCRIPCIÓN FLEXIBLE (CLAVE)
              _pdfCell(
                data['descripcion'] ?? '-',
                align: pw.TextAlign.justify,
              ),

              _pdfCell(data['tipo_historial'] ?? '-'),

              _pdfCell("Bs ${precio.toStringAsFixed(2)}"),

              _pdfCell(data['tipo_pago'] ?? '-'),

              _pdfCell("Bs ${precio.toStringAsFixed(2)}"),
            ],
          ),
        ],
      ),
    ],
  ),
),
            pw.SizedBox(height: 20),

            // ================= TOTAL =================
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "TOTAL: Bs. ${precio.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 40),

            // ================= FIRMAS =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
  children: [

    /// 🔥 LÍNEA DE FIRMA
    pw.Container(
      width: 120,
      height: 1,
      color: PdfColors.black,
    ),

    pw.SizedBox(height: 5),

    /// TEXTO
    pw.Text(
      "Veterinaria Pandy",
      style: const pw.TextStyle(fontSize: 10),
    ),
  ],

                ),
                pw.Column(
                  children: [
                    pw.Container(width: 120, height: 1),
                    pw.SizedBox(height: 5),
                    pw.Column(
  children: [

    /// 🔥 LÍNEA DE FIRMA
    pw.Container(
      width: 120,
      height: 1,
      color: PdfColors.black,
    ),

    pw.SizedBox(height: 5),

    /// TEXTO
    pw.Text(
      "Recibí conforme",
      style: const pw.TextStyle(fontSize: 10),
    ),
  ],
)
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _pdfCellHeader(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
    ),
  );
}

pw.Widget _pdfCell(String text,
    {pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 10),
      textAlign: align,
    ),
  );
}

  // ================= PRINT =================

void _printPdf(Map<String, dynamic> data) async {
  try {
    final pdfData = await _generatePdf(data, idHistorial);

    await Printing.layoutPdf(
      onLayout: (_) async => pdfData,
    );
  } catch (e) {
    debugPrint("❌ ERROR PRINT: $e");
  }
}

  // ================= DOWNLOAD =================

void _downloadPdf(Map<String, dynamic> data) async {
  try {
    final pdfData = await _generatePdf(data, idHistorial);

    final fileName =
        'comprobante_${data["nombre_mascota"] ?? "archivo"}.pdf';

    await FileService.saveOrDownload(pdfData, fileName);
  } catch (e) {
    debugPrint("❌ ERROR DOWNLOAD: $e");
  }
}
}