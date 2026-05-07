import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:veterinaria_pandy/historial/comprobante_view.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart' as PdfService;

class HistorialDetailPage extends StatefulWidget {
  final Map data;

  const HistorialDetailPage({super.key, required this.data});

  @override
  State<HistorialDetailPage> createState() => _HistorialDetailPageState();
}

class _HistorialDetailPageState extends State<HistorialDetailPage> {
  bool loadingPdf = false;
  bool loadingPrint = false;
  late ScrollController _verticalController = ScrollController();
  late ScrollController _horizontalController = ScrollController();
  bool showFullInfo = false;

  void _volver() {
    DashboardController.goTo(8);
  }

  @override
void initState() {
  super.initState();
   _verticalController = ScrollController();
   _horizontalController = ScrollController();
  debugPrint("DATA RECIBIDA EN DETAIL:");
  debugPrint(widget.data.toString());
}

  @override
void dispose() {
  _verticalController.dispose();
  _horizontalController.dispose();
  super.dispose();
}

  Future<List<Map<String, dynamic>>> _getHistorialCliente() async {
  final ctx = DashboardController.selectedHistorial;

  if (ctx == null) return [];

  final idCliente = ctx["id_cliente"];

  if (idCliente == null) return [];

  final snap = await FirebaseFirestore.instance
      .collection("historial_v2")
      .where("id_cliente", isEqualTo: idCliente.toString().trim())
      .orderBy("fecha_registro", descending: true)
      .get();

  final data = snap.docs.map((doc) => doc.data()).toList();

  // 🔥 importante: asegurar que tenga datos del cliente
  return data.map((d) {
    return {
      ...d,

      // fallback desde cliente si falta algo
      "nombre_mascota": d["nombre_mascota"] ?? ctx["nombre_mascota"],
      "nombre_dueno": d["nombre_dueno"] ?? ctx["nombre_dueno"],
      "telefono": d["telefono"] ?? ctx["telefono"],
      "direccion": d["direccion"] ?? ctx["direccion"],
      "raza": d["raza"] ?? ctx["raza"],
    };
  }).toList();


}

Future<void> _descargarPdfCliente() async {
  try {
    setState(() => loadingPdf = true);

    final data = await _getHistorialCliente();
    debugPrint("📦 DATA PDF: ${data.length}");

    final bytes =
        await PdfService.generateHistorialClientePdfBytes(data);

    final fileName =
        "historial_cliente_${DateTime.now().millisecondsSinceEpoch}.pdf";

    await FileService.saveOrDownload(bytes, fileName);

  } catch (e, stack) {
    debugPrint("❌ ERROR PDF: $e");
    debugPrint(stack.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    setState(() => loadingPdf = false);
  }
}

Future<void> _imprimirPdfCliente() async {
  try {
    setState(() => loadingPrint = true);

    final data = await _getHistorialCliente();
    debugPrint("🖨 DATA PRINT: ${data.length}");

    final bytes =
        await PdfService.generateHistorialClientePdfBytes(data);

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
    );

  } catch (e, stack) {
    debugPrint("❌ ERROR PRINT: $e");
    debugPrint(stack.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error al imprimir")),
    );
  } 
  
  finally {
    setState(() => loadingPrint = false);
  }
}

Widget _infoPaciente(Map<String, dynamic> d) {
  final isMobile = MediaQuery.of(context).size.width < 700;
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade700, width: 1.2),
    ),
    child: Padding(
      padding: EdgeInsets.all(isMobile ? 10 : 16),

      /// ================= MOBILE =================
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔥 HEADER COMPACTO
                Row(
                  children: [
                    SizedBox(
                      width: 45,
                      height: 45,
                      child: _avatar(),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d["nombre_mascota"] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Dueño: ${d["nombre"]}",
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    /// 🔥 BOTÓN EXPANDIR
                    IconButton(
                      icon: Icon(
                        showFullInfo
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onPressed: () {
                        setState(() {
                          showFullInfo = !showFullInfo;
                        });
                      },
                    )
                  ],
                ),

                /// 🔥 INFO COMPLETA (SOLO SI EXPANDE)
                if (showFullInfo) ...[
                  const SizedBox(height: 10),
                  _infoText(d),
                ]
              ],
            )

          /// ================= WEB =================
          : Row(
              children: [
                _avatar(),
                const SizedBox(width: 15),
                Expanded(child: _infoText(d)),
              ],
            ),
    ),
  );
}

Widget _avatar() {
  return Container(
    width: 55,
    height: 55,
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.pets, color: Color(0xFF0054A6), size: 30),
  );
}

Widget _infoText(Map d) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        d["nombre_mascota"] ?? "Sin nombre",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      Text(
        "${d["raza"] ?? "-"}  •  Dueño: ${d["nombre"] ?? "-"}",
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 5,
        children: [
          _infoChip("Tel", d["telefono"]),
          _infoChip("Dirección", d["direccion"]),
        ],
      ),
    ],
  );
}

Widget _headerResponsive() {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 800;

  final buttons = Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      ElevatedButton.icon(
        onPressed: loadingPdf ? null : _descargarPdfCliente,
        icon: const Icon(Icons.download,color: Colors.white,),
        label: const Text("Descargar",style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
      ),
      ElevatedButton.icon(
        onPressed: loadingPrint ? null : _imprimirPdfCliente,
        icon: const Icon(Icons.print,color: Colors.white,),
        label: const Text("Imprimir", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      ),
      ElevatedButton.icon(
        onPressed: () {
          DashboardController.selectedHistorial =
              Map<String, dynamic>.from(widget.data);
          DashboardController.goTo(10);
        },
        icon: const Icon(Icons.add,color: Colors.white,),
        label: const Text("Registrar", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
      ),
      ElevatedButton.icon(
        onPressed: _volver,
        icon: const Icon(Icons.arrow_back,color: Colors.white,),
        label: const Text("Regresar", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      ),
    ],
  );

  if (isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "HISTORIAL",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        buttons,
      ],
    );
  }

  return Row(
    children: [
      const Text(
        "HISTORIAL",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Spacer(),
      buttons,
    ],
  );
}

  
  @override
Widget build(BuildContext context) {
  final Map<String, dynamic> d =
      Map<String, dynamic>.from(widget.data);

  final idCliente = (d["id_cliente"] ?? "").toString();

  final isMobile = MediaQuery.of(context).size.width < 700;

  return Scaffold(
    body: SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 20),
        child: Column(
          children: [

            // ================= HEADER =================
            _headerResponsive(),

            const SizedBox(height: 20),

            // ================= INFO PACIENTE =================
            _infoPaciente(d),

            const SizedBox(height: 15),

            // ================= CONTENIDO =================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("historial_v2")
                    .where("id_cliente",
                        isEqualTo: idCliente.trim())
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final ta = a["fecha_registro"];
                      final tb = b["fecha_registro"];

                      if (ta is Timestamp && tb is Timestamp) {
                        return tb.compareTo(ta);
                      }
                      return 0;
                    });

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("Sin historial clínico"));
                  }

                  /// ================= MOBILE =================
                  if (isMobile) {
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final h = Map<String, dynamic>.from(
                            doc.data() as Map);

                        final id_cliente =
                            (h["id_cliente"] ?? doc.id).toString();

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Text(
                                  h["descripcion"] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text("Servicio: ${h["tipo_servicio"] ?? h["tipo_historial"] ?? ""}"),
                                Text("Precio: Bs ${h["precioh"] ?? 0}"),
                                Text("Pago: ${h["tipo_pago"] ?? ""}"),

                                const SizedBox(height: 10),

                                Wrap(
                                  
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [

                                    /// 🔴 ELIMINAR (TU LÓGICA EXACTA)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black87,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () async {
                                        final confirm =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                                "Eliminar registro"),
                                            content: const Text(
                                                "¿Seguro que deseas eliminar este historial?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, false),
                                                child:
                                                    const Text("Cancelar"),
                                              ),
                                              ElevatedButton(
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        context, true),
                                                child: const Text(
                                                  "Eliminar",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await FirebaseFirestore.instance
                                              .collection("historial_v2")
                                              .doc(doc.id)
                                              .delete();

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    "Registro eliminado")),
                                          );
                                        }
                                      },
                                      child: const Text("Eliminar"),
                                    ),

                                    /// 🟠 EDITAR
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.redAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        DashboardController
                                            .editingHistorialId = doc.id;
                                        DashboardController.goTo(11);
                                      },
                                      child: const Text("Editar"),
                                    ),

                                    /// 🔴 VER COMPROBANTE
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.redAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        print("ID enviado: " +
                                            id_cliente);

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ComprobanteView(
                                                    idHistorial:
                                                        doc.id),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                          "Ver Comprobante"),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  /// ================= WEB =================
                  return ScrollConfiguration(
  behavior: const MaterialScrollBehavior().copyWith(
    dragDevices: {
      PointerDeviceKind.mouse,
      PointerDeviceKind.touch,
      PointerDeviceKind.trackpad,
    },
  ),
  child: LayoutBuilder(
  builder: (context, constraints) {
    return Material(
      child: Container(
        color: const Color(0xFFF5F6FA), // fondo base consistente
        child: Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              notificationPredicate: (n) =>
                  n.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: Container(
  constraints: const BoxConstraints(
    minWidth: 1000,
  ),
                  child: 
                  Container(
  margin: const EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Colors.grey.shade300,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  ),
  child: DataTable(
    border: TableBorder.all(
  color: Colors.grey.shade300,
  width: 1,
  borderRadius: BorderRadius.circular(12),
),
                    columnSpacing: 20,
                    horizontalMargin: 12,
                    dividerThickness: 1,
                    dataRowMinHeight: 60,
dataRowMaxHeight: 130,

                    headingRowColor: MaterialStateProperty.all(
  const Color(0xFFF1F3F6),
),

                    dataRowColor: MaterialStateProperty.resolveWith((states) {
  return Colors.white;
}),

                    headingTextStyle: const TextStyle(
  color: Colors.black87,
  fontWeight: FontWeight.bold,
  fontSize: 13.5,
),
                    columns: const [
                      DataColumn(label: Text("Descripción")),
                      DataColumn(label: Text("Fecha")),
                      DataColumn(label: Text("Servicio")),
                      DataColumn(label: Text("Precio")),
                      DataColumn(label: Text("Pago")),
                      DataColumn(label: Text("Acciones")),
                    ],

                    rows: docs.map((doc) {
                      final h = Map<String, dynamic>.from(doc.data() as Map);

                      final fecha = h["fecha_registro"];
                      String fechaText = "-";

                      if (fecha is Timestamp) {
                        final d = fecha.toDate();
                        fechaText =
                            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                      }

                      Text cellText(String text) {
                        return Text(
                          text,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        );
                      }

                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
    (states) {
      if (docs.indexOf(doc).isEven) {
        return Colors.grey.shade50;
      }
      return Colors.white;
    },
  ),
                        cells: [

                          /// DESCRIPCIÓN
                          DataCell(
  descriptionCell(h["descripcion"] ?? ""),
),

                          /// FECHA
                          DataCell(cellText(fechaText)),

                          /// SERVICIO
                          DataCell(cellText(
                            h["tipo_servicio"] ??
                                h["tipo_historial"] ??
                                "",
                          )),

                          /// PRECIO
                          DataCell(cellText("Bs ${h["precioh"] ?? 0}")),

                          /// PAGO
                          DataCell(cellText(h["tipo_pago"] ?? "")),

                          /// ACCIONES
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection("historial_v2")
                                        .doc(doc.id)
                                        .delete();
                                  },
                                  child: const Text("Eliminar"),
                                ),

                                const SizedBox(width: 6),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0054A6),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () {
                                    DashboardController.editingHistorialId =
                                        doc.id;
                                    DashboardController.goTo(11);
                                  },
                                  child: const Text("Editar"),
                                ),

                                const SizedBox(width: 6),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4B170),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ComprobanteView(
                                          idHistorial: doc.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text("Ver Comprobante"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  },
));
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget descriptionCell(String text) {
  return SizedBox(
    width: 260, // ancho fijo real
    child: Text(
      text,
      softWrap: true,
      maxLines: 6, // 🔥 permite crecer verticalmente
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 13,
        height: 1.4, // 🔥 más legible
      ),
    ),
  );
}

  Widget _infoChip(String label, dynamic value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Text(
      "$label: ${value ?? '-'}",
      style: const TextStyle(fontSize: 12),
    ),
  );
}

}
