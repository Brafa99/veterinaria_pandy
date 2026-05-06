import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/services/file_service.dart';

class ComprobanteViewVentas extends StatelessWidget {
  final String idVenta;

  const ComprobanteViewVentas({super.key, required this.idVenta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Comprobante Venta"),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('ventas')
            .doc(idVenta)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text("No existe la venta: $idVenta"),
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
      children: [
        SizedBox(
          width: 90,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  // ================= UI =================
  Widget _buildComprobante(BuildContext context, Map<String, dynamic> data) {
    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final productos = (data['productos'] as List?) ?? [];

    final total = (data['total'] ?? 0).toString();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= BOTONES =================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _printPdf(data),
                    icon: const Icon(Icons.print),
                    label: const Text("Imprimir"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _downloadPdf(data),
                    icon: const Icon(Icons.download),
                    label: const Text("Descargar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ================= HEADER =================
              const Center(
                child: Text(
                  "VETERINARIA PANDY",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              Center(child: Text("3409656016",style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),)),
              
              const SizedBox(height: 20),

              // ================= CLIENTE =================
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Información del Cliente",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),

                    _infoRow("Cliente", data['cliente_nombre'] ?? '-'),
                    _infoRow("Mascota", data['mascota_nombre'] ?? '-'),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                
                  Text(
                    "Fecha: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : '-'}",
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Divider(),

              // ================= TABLA PRODUCTOS =================
              DataTable(
                columnSpacing: 10,
                columns: const [
                  DataColumn(label: Text("Producto")),
                  DataColumn(label: Text("Cant.")),
                  DataColumn(label: Text("Precio")),
                  DataColumn(label: Text("Subtotal")),
                ],
                rows: productos.map<DataRow>((p) {
                  return DataRow(cells: [
                    DataCell(Text(p["nombre"] ?? "")),
                    DataCell(Text("${p["cantidad"]}")),
                    DataCell(Text("Bs ${p["precio"]}")),
                    DataCell(Text("Bs ${p["subtotal"]}")),
                  ]);
                }).toList(),
              ),

              const SizedBox(height: 20),

              // ================= TOTAL =================
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "TOTAL: Bs $total",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(height: 30),

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
            ],
          ),
        ),
      ),
    );
  }

  // ================= PDF =================
  Future<Uint8List> _generatePdf(
      Map<String, dynamic> data) async {
    final pdf = pw.Document();

    final fecha = (data['fecha'] as Timestamp?)?.toDate();
    final productos = (data['productos'] as List?) ?? [];

    final total = (data['total'] as num?)?.toDouble() ?? 0;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(25),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              pw.Center(
                child: pw.Text(
                  "VETERINARIA PANDY",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),
              
              pw.Center(
                child: pw.Text(
                  "VETERINARIA PANDY",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(child: pw.Text("3409656016",style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),)),

              pw.SizedBox(height: 20),


              pw.Text("Cliente: ${data['cliente_nombre'] ?? '-'}"),
              pw.Text("Mascota: ${data['mascota_nombre'] ?? '-'}"),
              pw.Text(
                "Fecha: ${fecha != null ? DateFormat('dd/MM/yyyy').format(fecha) : '-'}",
              ),

              pw.SizedBox(height: 15),

              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      _cellHeader("Producto"),
                      _cellHeader("Cant."),
                      _cellHeader("Precio"),
                      _cellHeader("Subtotal"),
                    ],
                  ),

                  ...productos.map<pw.TableRow>((p) {
                    return pw.TableRow(
                      children: [
                        _cell(p["nombre"] ?? ""),
                        _cell("${p["cantidad"]}"),
                        _cell("Bs ${p["precio"]}"),
                        _cell("Bs ${p["subtotal"]}"),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL: Bs ${total.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text),
    );
  }

  pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // ================= PRINT =================
  void _printPdf(Map<String, dynamic> data) async {
    final pdfData = await _generatePdf(data);
    await Printing.layoutPdf(onLayout: (_) async => pdfData);
  }

  // ================= DOWNLOAD =================
void _downloadPdf(Map<String, dynamic> data) async {
  try {
    final pdfData = await _generatePdf(data);

    final fileName =
        'comprobante_${data["nombre_mascota"] ?? "archivo"}.pdf';

    await FileService.saveOrDownload(pdfData, fileName);
  } catch (e) {
    debugPrint("❌ ERROR DOWNLOAD: $e");
  }
}


}