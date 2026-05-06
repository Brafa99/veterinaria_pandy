import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:veterinaria_pandy/services/file_service.dart';
import 'package:veterinaria_pandy/services/pdf_service.dart';
import 'usuarios_form_page.dart';
import 'package:flutter/gestures.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
  
}

class _UsuariosPageState extends State<UsuariosPage> {
  List<QueryDocumentSnapshot> allDocs = [];
  List<QueryDocumentSnapshot> filteredDocs = [];

  bool generatingPrint = false;
  bool generatingDownload = false;

  String searchText = "";
  Timer? _debounce;
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
  onChanged: search,
  decoration: const InputDecoration(
    prefixIcon: Icon(Icons.search),
    hintText: "Buscar usuario...",
    border: OutlineInputBorder(),
  ),
),
const SizedBox(height: 10),
            _header(context),
            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("usuarios")
                    .snapshots(),

                builder: (context, snapshot) {
  if (snapshot.hasError) {
    return Center(child: Text("Error: ${snapshot.error}"));
  }

  if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  allDocs = snapshot.data?.docs ?? [];

  // 🔥 SOLO SE ASIGNA UNA VEZ SI NO HAY BÚSQUEDA
  if (searchText.isEmpty) {
    filteredDocs = allDocs;
  }

  if (filteredDocs.isEmpty) {
    return const Center(child: Text("No hay resultados"));
  }

  return isMobile
      ? ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (_, i) {
            final d =
                filteredDocs[i].data() as Map<String, dynamic>;
            return _card(context, filteredDocs[i].id, d);
          },
        )
      : _table(filteredDocs, context);
}
              ),
            ),
          ],
        ),
      ),
    );
  }

  void search(String value) {
  _debounce?.cancel();

  _debounce = Timer(const Duration(milliseconds: 300), () {
    final text = value.toLowerCase().trim();

    setState(() {
      searchText = text;

      if (text.isEmpty) {
        filteredDocs = allDocs;
      } else {
        filteredDocs = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;

          final nombre =
              "${d['nombre'] ?? ''} ${d['apellido'] ?? ''}".toLowerCase();

          final correo = (d['correo'] ?? "").toLowerCase();
          final telefono = (d['telefono'] ?? "").toLowerCase();

          return nombre.contains(text) ||
              correo.contains(text) ||
              telefono.contains(text);
        }).toList();
      }
    });
  });
}

  // ================= HEADER =================
Widget _header(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 800;

  return isMobile
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "LISTA DE USUARIOS",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _btnDownload(),
                _btnPrint(),
                _btnAdd(),
              ],
            ),
          ],
        )
      :Row(
    children: [
      const Text(
        "LISTA DE USUARIOS",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const Spacer(),

      // 🔵 DESCARGAR
      ElevatedButton.icon(
  onPressed: generatingDownload
      ? null
      : () async {
          setState(() => generatingDownload = true);

          try {
            final snapshot = await FirebaseFirestore.instance
                .collection("historial")
                .orderBy("createdAt", descending: true)
                .get();

            final data = snapshot.docs
                .map((e) => e.data() as Map<String, dynamic>)
                .toList();

            final bytes =
                await PdfService.generateHistorialPdfBytes(data);

            final fileName =
                "usuarios_${DateTime.now().millisecondsSinceEpoch}.pdf";

            await FileService.saveOrDownload(bytes, fileName);

          } catch (e) {
            debugPrint("❌ ERROR DOWNLOAD PDF: $e");
          } finally {
            setState(() => generatingDownload = false);
          }
        },
  icon: generatingDownload
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Icon(Icons.download),
  label: Text("Descargar",style: TextStyle(color: Colors.white),),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
),

      const SizedBox(width: 10),

      // 🟢 IMPRIMIR
      ElevatedButton.icon(
        onPressed: generatingPrint
    ? null
    : () async {
        setState(() => generatingPrint = true);

        try {
          final snapshot = await FirebaseFirestore.instance
              .collection("historial")
              .orderBy("createdAt", descending: true)
              .get();

          final data = snapshot.docs
              .map((e) => e.data() as Map<String, dynamic>)
              .toList();

          await PdfService.generateHistorialPdfBytes(data);

        } finally {
          setState(() => generatingPrint = false);
        }
      },
        icon: generatingPrint
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.print),
        label:
            Text("Imprimir",style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
      ),

      const SizedBox(width: 10),

      ElevatedButton.icon(
        onPressed: () {
          DashboardController.editingUserId = null;
          DashboardController.goTo(3);
        },
        icon: const Icon(Icons.add),
        label: const Text("Registrar"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
      ),
    ],
  );
}


Widget _btnDownload() {
  return ElevatedButton.icon(
    onPressed: generatingDownload
        ? null
        : () async {
            setState(() => generatingDownload = true);

            try {
              final snapshot = await FirebaseFirestore.instance
                  .collection("usuarios") // ✅ CORREGIDO
                  .get();

              final data = snapshot.docs
                  .map((e) => e.data())
                  .toList();

              final bytes = await PdfService().generateUsersPdf(data);

              final fileName =
                  "usuarios_${DateTime.now().millisecondsSinceEpoch}.pdf";

              await FileService.saveOrDownload(bytes, fileName);

            } catch (e) {
              debugPrint("❌ ERROR DOWNLOAD PDF: $e");
            } finally {
              setState(() => generatingDownload = false);
            }
          },
    icon: generatingDownload
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download),
    label: Text("Descargar",style: TextStyle(color: Colors.white),),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  );
}

Widget _btnPrint() {
  return ElevatedButton.icon(
    onPressed: generatingPrint
        ? null
        : () async {
            setState(() => generatingPrint = true);

            try {
              final snapshot = await FirebaseFirestore.instance
                  .collection("usuarios") // ✅ CORREGIDO
                  .get();

              final data = snapshot.docs
                  .map((e) => e.data() as Map<String, dynamic>)
                  .toList();

              final bytes = await PdfService().generateUsersPdf(data);

              await Printing.layoutPdf(
                onLayout: (_) async => bytes,
              );
            } catch (e) {
              debugPrint("❌ ERROR PRINT PDF: $e");
            } finally {
              setState(() => generatingPrint = false);
            }
          },
    icon: generatingPrint
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.print),
    label: Text("Imprimir",style: TextStyle(color: Colors.white),),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
  );
}

Widget _btnAdd() {
  return ElevatedButton.icon(
    onPressed: () {
      DashboardController.editingUserId = null;
      DashboardController.goTo(3);
    },
    icon: const Icon(Icons.add),
    label: const Text("Registrar"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
  );
}

  // ================= TABLE PRO (PHP STYLE) =================
  Widget _table(List<QueryDocumentSnapshot> docs, BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: true,
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Card(
                  elevation: 3,
                  child: DataTable(
                     border: TableBorder.all(
                      color: Colors.grey.shade600,
                      width: 2,
                    ),

  headingRowColor: MaterialStateProperty.all(
    const Color(0xFFF3F4F6),
  ),

  headingTextStyle: const TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ),

  dataRowHeight: 55,
  columnSpacing: 20,

                    columns: const [
                      DataColumn(label: Text("#")),
                      DataColumn(label: Text("Foto")),
                      DataColumn(label: Text("Nombre y Apellidos")),
                      DataColumn(label: Text("Teléfono")),
                      DataColumn(label: Text("Usuario")),
                      DataColumn(label: Text("Tipo Usuario")),
                      DataColumn(label: Text("Correo")),
                      DataColumn(label: Text("Acciones")),
                    ],

                    rows: List.generate(docs.length, (i) {
                      final d = docs[i].data() as Map<String, dynamic>;

                      return DataRow(
                        cells: [
                          DataCell(Text("${i + 1}")),

                          DataCell(
                            CircleAvatar(
                              backgroundImage: (d["foto"] ?? "") != ""
                                  ? NetworkImage(d["foto"])
                                  : null,
                              child: (d["foto"] ?? "") == ""
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                          ),

                          DataCell(Text(
                            "${d['nombre'] ?? ''} ${d['apellido'] ?? ''}",
                          )),

                          DataCell(Text(d['telefono'] ?? "")),

                          DataCell(Text(d['usuario'] ?? "")),

                          DataCell(_badge(d['tipo'] ?? "")),

                          DataCell(
                            SizedBox(
                              width: 220,
                              child: Text(
                                d['correo'] ?? "",
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          DataCell(_actions(context, docs[i].id)),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= MOBILE =================
  Widget _card(BuildContext context, String id, Map d) {
    return Card(
  margin: const EdgeInsets.symmetric(vertical: 6),
  child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    leading: const CircleAvatar(child: Icon(Icons.person)),
    title: Text(
      "${d['nombre']} ${d['apellido']}",
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      d['correo'] ?? "",
      overflow: TextOverflow.ellipsis,
    ),
    trailing: _actions(context, id),
  ),
);
  }

  // ================= ACTIONS =================
  Widget _actions(BuildContext context, String id) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {
  DashboardController.editingUserId = id;
  DashboardController.goTo(4); // EDITAR
},
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
  final confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Confirmar eliminación"),
      content: const Text("¿Seguro que deseas eliminar este usuario?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text("Eliminar"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await FirebaseFirestore.instance
        .collection("usuarios")
        .doc(id)
        .delete();
  }
}
        ),
      ],
    );
  }

  // ================= BADGE =================
  Widget _badge(String tipo) {
    Color c = Colors.grey;

    if (tipo == "administrador") c = Colors.red;
    if (tipo == "empleado") c = Colors.blue;
    if (tipo == "cliente") c = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tipo,
        style: TextStyle(color: c, fontSize: 12),
      ),
    );
  }
}