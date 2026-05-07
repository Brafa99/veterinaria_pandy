import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';
import 'package:flutter/gestures.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  List<QueryDocumentSnapshot> allDocs = [];
  List<QueryDocumentSnapshot> filteredDocs = [];

  String searchText = "";

  void search(String value) {
    final text = value.toLowerCase().trim();

    setState(() {
      searchText = text;

      if (text.isEmpty) {
        filteredDocs = allDocs;
      } else {
        filteredDocs = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;

          final nombre = (d["nombre"] ?? "").toLowerCase();
          final descripcion = (d["descripcion"] ?? "").toLowerCase();

          return nombre.contains(text) ||
              descripcion.contains(text);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 🔍 BUSCADOR
          TextField(
            onChanged: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: "Buscar producto...",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          _header(),

          const SizedBox(height: 15),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("productos")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                allDocs = snapshot.data?.docs ?? [];

                if (searchText.isEmpty) {
                  filteredDocs = allDocs;
                }

                if (filteredDocs.isEmpty) {
                  return const Center(
                      child: Text("No hay productos"));
                }

                return isMobile
                    ? ListView.builder(
                        itemCount: filteredDocs.length,
                        itemBuilder: (_, i) {
                          final d = filteredDocs[i].data()
                              as Map<String, dynamic>;
                          return _card(d);
                        },
                      )
                    : _table(filteredDocs);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() {
  final isMobile = MediaQuery.of(context).size.width < 800;

  final addButton = ElevatedButton.icon(
    onPressed: () {
      DashboardController.goTo(28);
    },
    icon: const Icon(Icons.add),
    label: const Text("Agregar"),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
  );

  return isMobile
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "LISTA DE PRODUCTOS",
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [addButton],
            ),
          ],
        )
      : Row(
          children: [
            const Text(
              "LISTA DE PRODUCTOS",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            addButton,
          ],
        );
}

  // ================= TABLE =================
Widget _table(List<QueryDocumentSnapshot> docs) {
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
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Card(
            elevation: 3,
            child: DataTable(
              columnSpacing: 18,
              dataRowHeight: 55,

              border: TableBorder.all(
                color: Colors.grey.shade500,
                width: 1.5, // 🔥 más elegante
              ),

              headingRowColor: MaterialStateProperty.all(
                const Color(0xFFF3F4F6),
              ),

              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),

              dataTextStyle: const TextStyle(
                fontSize: 12,
              ),


                  columns: const [
                    DataColumn(label: Text("#")),
                    DataColumn(label: Text("Nombre")),
                    DataColumn(label: Text("Descripción")),
                    DataColumn(label: Text("Unidad")),
                    DataColumn(label: Text("Compra")),
                    DataColumn(label: Text("Venta")),
                    DataColumn(label: Text("Stock")),
                  ],

                  rows: List.generate(docs.length, (i) {
                    final d = docs[i].data() as Map<String, dynamic>;

                    return DataRow(
                      cells: [
                        DataCell(Text("${i + 1}")),

                        DataCell(
                          SizedBox(
                            width: 140,
                            child: Text(
                              d["nombre_pro"] ?? "",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              d["descripcion"] ?? "",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(Text(d["unidad"] ?? "")),

                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("${d["precio_compra"] ?? 0}"),
                          ),
                        ),

                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("${d["precio_venta"] ?? 0}"),
                          ),
                        ),

                        DataCell(
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("${d["stock"] ?? 0}"),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    }
  
}
Widget _miniItem(String label, String value, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    margin: const EdgeInsets.only(right: 6),

    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
  // ================= MOBILE =================
Widget _card(Map d) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),

    child: Card(
      elevation: 4, // 🔥 más separación visual
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 NOMBRE (TÍTULO)
            Text(
              d["nombre_pro"] ?? "",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 8),

            /// 🔥 DATOS EN FILAS (MEJOR DISTRIBUCIÓN)
            Row(
              children: [
                Expanded(
                  child: _miniItem(
                    "Stock",
                    "${d["stock"] ?? 0}",
                    Color(0xFF0054A6),
                  ),
                ),
                Expanded(
                  child: _miniItem(
                    "Venta",
                    "Bs ${d["precio_venta"] ?? 0}",
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// 🔥 UNIDAD
            _miniItem(
              "Unidad",
              d["unidad"] ?? "-",
              Colors.orange,
            ),
          ],
        ),
      ),
    ),
  );
}