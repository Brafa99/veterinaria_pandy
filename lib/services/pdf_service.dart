import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:veterinaria_pandy/services/formatFecha.dart';
import 'package:veterinaria_pandy/services/text_helper.dart';

class PdfService {

  // ================= FECHA =================
  static String formatFecha(DateTime date) {
    return DateFormat("dd/MM/yyyy HH:mm").format(date);
  }

  // ================= USERS =================
  Future<Uint8List> generateUsersPdf(List<Map<String, dynamic>> users) async {
    final pdf = pw.Document();
    final now = formatFecha(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Text("LISTADO DE USUARIOS",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text("Fecha: $now"),
          pw.Divider(),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.7),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1),
            },
            children: [
              _tableHeader(["#", "Nombre", "Teléfono", "Correo", "Rol"]),

              ...List.generate(users.length, (i) {
                final u = users[i];
                return _tableRow([
                  "${i + 1}",
                  fixText(u["nombre"]),
                  fixText(u["telefono"]),
                  fixText(u["correo"]),
                  fixText(u["rol"]),
                ]);
              })
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ================= CLIENTES =================
  static Future<void> generateClientesPdf(List<Map<String, dynamic>> clientes) async {
    final bytes = await compute(buildClientesPdf, clientes);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> generateClientesPdfBytes(
    List<Map<String, dynamic>> clientes,
  ) async {
    return await compute(buildClientesPdf, clientes);
  }

static Future<Uint8List> generateHistorialPdfBytes(
  
  List<Map<String, dynamic>> historial,
) async {

  if (kIsWeb) {
    // 🔥 directo
    return await buildHistorialPdf(historial);
  }

  // 🔥 móvil usa isolate
  return await compute(buildHistorialPdf, historial);
}

Future<Uint8List> buildHistorialReportesPdf(
  List<Map<String, dynamic>> data,
  String tituloReporte,
  String? subTitulo,
) async {
  final pdf = pw.Document();
  final now = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

  if (data.isEmpty) return pdf.save();

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(18),
      build: (_) => [

        /// ================= HEADER =================
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "VETERINARIA PANDY",
                style: pw.TextStyle(color: PdfColors.white),
              ),
              pw.Text(
                now,
                style: pw.TextStyle(color: PdfColors.white),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        /// ================= TITLE =================
        pw.Text(
  tituloReporte,
  style: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 14,
  ),
),

        pw.SizedBox(height: 10),

        if(subTitulo!.isNotEmpty) 
        pw.Text(
  subTitulo,
  style: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 14,
  ),
),
        pw.SizedBox(height: 15),

        /// ================= TABLE =================
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey700,
            width: 0.7,
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(25), // #
            1: const pw.FlexColumnWidth(2),   // Fecha
            2: const pw.FlexColumnWidth(2),   // Mascota
            3: const pw.FlexColumnWidth(2),   // Cliente
            4: const pw.FlexColumnWidth(2),   // Tipo
            5: const pw.FlexColumnWidth(4),   // Detalle
            6: const pw.FixedColumnWidth(60), // Precio
            7: const pw.FixedColumnWidth(60), //tipo_pago
          },
          children: [

            /// ================= HEADER ROW =================
            _tableHeader([
              "#",
              "Fecha",
              "Mascota",
              "Cliente",
              "Tipo",
              "Detalle",
              "Precio",
              "Tipo Pago",
            ]),

            /// ================= DATA ROWS =================
            ...List.generate(data.length, (i) {
              final d = data[i];
              

              final fecha = (d["fecha_registro"] is Timestamp)
                  ? (d["fecha_registro"] as Timestamp).toDate()
                  : null;

              return _tableRow([
                "${i + 1}",
                fecha != null
                    ? DateFormat("dd/MM/yyyy").format(fecha)
                    : "-",
                fixText(d["nombre_mascota"] ?? ""),
                fixText(d["nombre_dueno"] ?? ""),
                fixText(d["tipo_historial"] ?? ""),
                fixText(d["descripcion"] ?? ""),
                "Bs ${d["precioh"] ?? 0}",
                fixText(d["tipo_pago"] ?? "-"),
              ]);
            }),
          ],
        ),

      ],
    ),
  );

  return pdf.save();
}

Future<Uint8List> buildFinanzasReportPdf({
  required String titulo,
  required String rango,
  required double ingresos,
  required double egresos,
  required double balance,
  required List<Map<String, dynamic>> resumenPorDia,
  required List<Map<String, dynamic>> movimientos, // 🔥 NUEVO
})async {
  final pdf = pw.Document();
  final now = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(20),
      build: (_) => [

        /// HEADER
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("VETERINARIA PANDY",
                  style: pw.TextStyle(color: PdfColors.white)),
              pw.Text(now,
                  style: pw.TextStyle(color: PdfColors.white)),
            ],
          ),
        ),

        pw.SizedBox(height: 15),

        /// TITULO
        pw.Text(titulo,
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),

        pw.Text(rango),

        pw.SizedBox(height: 20),

        /// CARDS RESUMEN
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _pdfBox("Ingresos", ingresos, PdfColors.green),
            _pdfBox("Egresos", egresos, PdfColors.red),
            _pdfBox("Balance", balance,
                balance >= 0 ? PdfColors.green : PdfColors.red),
          ],
        ),

        pw.SizedBox(height: 20),

        /// TABLA RESUMEN
        pw.Text("Resumen por día",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

        pw.SizedBox(height: 10),

        pw.Table(
          border: pw.TableBorder.all(),
          children: [

            /// HEADER
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _cell("Fecha"),
                _cell("Ingresos"),
                _cell("Egresos"),
                _cell("Balance"),
              ],
            ),

            /// DATA
            ...resumenPorDia.map((d) {
              return pw.TableRow(
                children: [
                  _cell(d["fecha"]),
                  _cell("Bs ${d["ingresos"].toStringAsFixed(2)}"),
                  _cell("Bs ${d["egresos"].toStringAsFixed(2)}"),
                  _cell("Bs ${d["balance"].toStringAsFixed(2)}"),
                ],
              );
            }).toList()
          ],
        ),

        pw.SizedBox(height: 25),

pw.Text("Detalle de Movimientos",
    style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold, fontSize: 13)),

pw.SizedBox(height: 10),

pw.Table(
  border: pw.TableBorder.all(
    color: PdfColors.grey700,
    width: 0.7,
  ),
  columnWidths: {
    0: const pw.FixedColumnWidth(60),
    1: const pw.FlexColumnWidth(2),
    2: const pw.FlexColumnWidth(2),
    3: const pw.FlexColumnWidth(2),
    4: const pw.FixedColumnWidth(60),
    5: const pw.FixedColumnWidth(60),
  },
  children: [

    /// HEADER
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _cell("Tipo"),
        _cell("Fecha"),
        _cell("Descripción"),
        _cell("Categoría"),
        _cell("Monto"),
        _cell("Pago"),
      ],
    ),

    /// DATA
    ...movimientos.map((m) {
      final rawFecha = m["fecha"];

DateTime fecha;

if (rawFecha is Timestamp) {
  fecha = rawFecha.toDate();
} else if (rawFecha is DateTime) {
  fecha = rawFecha;
} else {
  fecha = DateTime.now(); // fallback seguro
}

final monto = (m["monto"] is num)
    ? (m["monto"] as num).toDouble()
    : double.tryParse(m["monto"].toString()) ?? 0;


      return pw.TableRow(
        children: [
          _cell(m["tipo"]),
          _cell(DateFormat("dd/MM/yyyy").format(fecha)),
          _cell(m["descripcion"]),
          _cell(m["categoria"]),
          _cell("Bs ${m["monto"]}"),
          _cell("Bs ${monto.toStringAsFixed(2)}"),
        ],
      );
    }).toList(),
  ],
),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _pdfBox(String title, double value, PdfColor color) {
  return pw.Container(
    width: 150,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: color),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      children: [
        pw.Text(title),
        pw.SizedBox(height: 5),
        pw.Text("Bs ${value.toStringAsFixed(2)}",
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: color)),
      ],
    ),
  );
}

pw.Widget _cell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
  );
}

Future<Uint8List> buildVentasReportesPdf(
  List<Map<String, dynamic>> data,
  String tituloReporte,
  String? subTitulo,
) async {
  final pdf = pw.Document();
  final now = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

  if (data.isEmpty) return pdf.save();

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(18),
      build: (_) => [

        /// ================= HEADER =================
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "VETERINARIA PANDY",
                style: pw.TextStyle(color: PdfColors.white),
              ),
              pw.Text(
                now,
                style: pw.TextStyle(color: PdfColors.white),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        /// ================= TITLE =================
        pw.Text(
          tituloReporte,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 14,
          ),
        ),

        if (subTitulo != null && subTitulo.isNotEmpty) ...[
          pw.SizedBox(height: 5),
          pw.Text(
            subTitulo,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],

        pw.SizedBox(height: 15),

        /// ================= TABLE =================
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey700,
            width: 0.7,
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(20), // #
            1: const pw.FlexColumnWidth(2),   // Fecha
            2: const pw.FlexColumnWidth(2),   // Cliente
            3: const pw.FlexColumnWidth(2),   // Mascota
            4: const pw.FlexColumnWidth(4),   // Detalle productos
            5: const pw.FixedColumnWidth(60), // Total
          },
          children: [

            /// HEADER
            _tableHeader([
              "#",
              "Fecha",
              "Cliente",
              "Mascota",
              "Detalle",
              "Total",
            ]),

            /// DATA
            ...List.generate(data.length, (i) {
              final venta = data[i];

              final fecha = (venta["fecha"] is Timestamp)
                  ? (venta["fecha"] as Timestamp).toDate()
                  : null;

              final productos = (venta["productos"] as List?) ?? [];

              /// 🔥 Construimos el detalle en una sola celda
              final detalleProductos = productos.map((p) {
                final nombre = p["nombre"] ?? "";
                final cant = p["cantidad"] ?? 0;
                final precio = p["precio"] ?? 0;
                final subtotal = p["subtotal"] ?? 0;

                return "• $nombre x$cant (Bs $precio) = Bs $subtotal";
              }).join("\n");

              return _tableRow([
                "${i + 1}",
                fecha != null
                    ? DateFormat("dd/MM/yyyy").format(fecha)
                    : "-",
                fixText(venta["cliente_nombre"] ?? ""),
                fixText(venta["mascota_nombre"] ?? ""),
                detalleProductos,
                "Bs ${venta["total"] ?? 0}",
              ]);
            }),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}

}

////////////////////////////////////////////////////////
/// 🔥 HELPERS PROFESIONALES
////////////////////////////////////////////////////////

pw.TableRow _tableHeader(List<String> titles) {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
    children: titles.map((t) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          t,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      );
    }).toList(),
  );
}

pw.TableRow _tableRow(List<String> values) {
  return pw.TableRow(
    children: values.map((v) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(
          v,
          style: const pw.TextStyle(fontSize: 8),
          maxLines: 4,
        ),
      );
    }).toList(),
  );
}

////////////////////////////////////////////////////////
/// 🔥 CLIENTES PDF
////////////////////////////////////////////////////////

Future<Uint8List> buildClientesPdf(List<Map<String, dynamic>> clientes) async {
  final pdf = pw.Document();
  final now = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Text("LISTADO DE CLIENTES",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text("Fecha: $now"),
        pw.Divider(),

        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.7),
          columnWidths: {
            0: const pw.FixedColumnWidth(25),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(2),
          },
          children: [
            _tableHeader([
              "#",
              "Mascota",
              "Raza",
              "Color",
              "Especie",
              "Dueño",
            ]),

            ...List.generate(clientes.length, (i) {
              final c = clientes[i];

              return _tableRow([
                "${i + 1}",
                fixText(c["nombre_mascota"]),
                fixText(c["raza"]),
                fixText(c["color"]),
                fixText(c["especie"]),
                fixText(c["nombre"]),
              ]);
            })
          ],
        )
      ],
    ),
  );

  return pdf.save();
}

////////////////////////////////////////////////////////
/// 🔥 HISTORIAL GLOBAL
////////////////////////////////////////////////////////

Future<Uint8List> buildHistorialPdf(List<Map<String, dynamic>> data) async {
  
  final pdf = pw.Document();
  final now = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

  const chunkSize = 40; // 🔥 clave

  for (int i = 0; i < data.length; i += chunkSize) {
    final chunk = data.skip(i).take(chunkSize).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(15),

        build: (_) => [

          pw.Text("LISTADO DE CLIENTES",
              style: pw.TextStyle(
                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text("Fecha: $now"),
          pw.SizedBox(height: 10),
          pw.Divider(),

          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey700,
              width: 0.7,
            ),

            children: [

              _tableHeader([
                "#",
                "Mascota",
                "Raza",
                "Color",
                "Especie",
                "Sexo",
                "Nacimiento",
                "Dueño",
                "Teléfono",
                "Dirección",
                "CI",
                "NIT",
                "Marca",
              ]),

              ...List.generate(chunk.length, (j) {
                final d = chunk[j];

                return _tableRow([
                  "${i + j + 1}",
                  fixText(d["nombre_mascota"]),
                  fixText(d["raza"]),
                  fixText(d["color"]),
                  fixText(d["especie"]),
                  fixText(d["sexo"]),
                  fixText(d["fechanac"]),
                  fixText(d["nombre_dueno"]),
                  fixText(d["telefono"]),
                  fixText(d["direccion"]),
                  fixText(d["ci"]),
                  fixText(d["nit"]),
                  fixText(
                    (d["marca"] == null ||
                            d["marca"].toString().trim().isEmpty)
                        ? "No tiene"
                        : d["marca"],
                  ),
                ]);
              }),
            ],
          ),
        ],
      ),
    );
  }

  return pdf.save();
}

////////////////////////////////////////////////////////
/// 🔥 HISTORIAL CLIENTE (PRO + CARD + TABLA REAL)////////////////////////////////////////////////////////
Future<Uint8List> generateHistorialClientePdfBytes(
  List<Map<String, dynamic>> data,
) async {
  return await compute(buildHistorialClientePdf, data);
}


Future<Uint8List> buildHistorialClientePdf(
  List<Map<String, dynamic>> data,
) async {
  final pdf = pw.Document();
  final now = DateFormat("dd/MM/yyyy HH:mm").format(DateTime.now());

  if (data.isEmpty) return pdf.save();
  final cliente = data.first;
  final nitCi =
    (cliente["nit"] ?? "").toString().trim().isNotEmpty
        ? cliente["nit"].toString()
        : ((cliente["ci"] ?? "").toString().trim().isNotEmpty
            ? cliente["ci"].toString()
            : "-");

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.all(18),
      build: (_) => [

        /// HEADER
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("VETERINARIA PANDY",
                  style: pw.TextStyle(color: PdfColors.white)),
              pw.Text(now, style: pw.TextStyle(color: PdfColors.white)),
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        /// CARD
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey600),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Mascota: "+fixText(cliente["nombre_mascota"]),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  "Dueño: ${fixText(cliente["nombre_dueno"])}"),
              pw.Text("Tel: ${fixText(cliente["telefono"])}"),
              pw.Text("Dir: ${fixText(cliente["direccion"])}"),
              pw.Text("NIT / CI: $nitCi"),
            ],
          ),
        ),

        pw.SizedBox(height: 15),

        pw.Text("REGISTROS CLÍNICOS",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

        pw.SizedBox(height: 8),

        /// TABLA REAL (🔥 AQUÍ ESTÁ LA SOLUCIÓN)
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey700,
            width: 0.7,
          ),
          columnWidths: {
            0: const pw.FixedColumnWidth(20),
            1: const pw.FlexColumnWidth(4),
            2: const pw.FixedColumnWidth(55),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FixedColumnWidth(45),
            5: const pw.FixedColumnWidth(45),
          },
          children: [
  _tableHeader([
    "#",
    "Antecedente",
    "Fecha",
    "Servicio",
    "Precio",
    "Tipo pago"

  ]),

  ...List.generate(data.length, (i) {
    final d = data[i];

    return _tableRow([
      "${i + 1}",
      fixText(d["descripcion"]),
      formatFecha(d["fecha_registro"]), // 🔥 AQUÍ ESTÁ LA CLAVE
      fixText(d["tipo_historial"] ?? d["tipo_servicio"]),
      "Bs ${d["precioh"] ?? 0}",
      fixText(d["tipo_pago"] ?? ""),
    ]);
  })
],
        )
      ],
    ),
  );

  return pdf.save();
}