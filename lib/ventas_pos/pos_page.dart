import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  List<Map<String, dynamic>> carrito = [];
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> clientes = [];
  bool ventaExitosa = false;
  bool ventaError = false;
  String? clienteId;
  String? clienteNombre;
  String? mascotaNombre;
  final TextEditingController clienteController = TextEditingController();
  String searchProduct = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= LOAD =================
  Future<void> loadData() async {
    try {
      setState(() => loading = true);

      final prodSnap =
          await FirebaseFirestore.instance.collection("productos").get();

      final cliSnap =
          await FirebaseFirestore.instance.collection("clientes").get();

      productos = prodSnap.docs
          .map((e) => {"id": e.id, ...e.data()})
          .toList();

      clientes =
          cliSnap.docs.map((e) => {"id": e.id, ...e.data()}).toList();
    } catch (e) {
      debugPrint("POS error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= TOTAL =================
  double get total {
    double t = 0;
    for (var p in carrito) {
      t += (p["subtotal"] as num?)?.toDouble() ?? 0;
    }
    return t;
  }

  // ================= FILTER =================
  List<Map<String, dynamic>> get productosFiltrados {
    if (searchProduct.isEmpty) return productos;

    return productos.where((p) {
      final name = (p["nombre_pro"] ?? "").toString().toLowerCase();
      return name.contains(searchProduct.toLowerCase());
    }).toList();
  }

  // ================= ADD =================
  void addProduct(Map<String, dynamic> prod, int qty) {
    setState(() {
      final index = carrito.indexWhere(
        (p) => p["id_producto"] == prod["id"],
      );

      final precio = double.parse(prod["precio_venta"].toString());

      if (index != -1) {
        carrito[index]["cantidad"] += qty;
        carrito[index]["subtotal"] =
            carrito[index]["cantidad"] * precio;
      } else {
        carrito.add({
          "id_producto": prod["id"],
          "nombre": prod["nombre_pro"],
          "precio": precio,
          "cantidad": qty,
          "subtotal": precio * qty,
        });
      }
    });
  }

  void remove(int index) {
    setState(() => carrito.removeAt(index));
  }

  // ================= SAVE =================
  Future<void> finalizarVenta() async {
  if (carrito.isEmpty || clienteId == null) return;

  try {
    final ventaRef =
        FirebaseFirestore.instance.collection("ventas").doc();

    // ================= GUARDAR VENTA =================
    await ventaRef.set({
      "cliente_id": clienteId,
      "cliente_nombre": clienteNombre,
      "mascota_nombre": mascotaNombre,
      "productos": carrito,
      "total": total,
      "fecha": FieldValue.serverTimestamp(),
      "estado": "completado",
    });

    // ================= REGISTRAR INGRESO =================
    if (total > 0) {
      await FirebaseFirestore.instance
          .collection("ingresos")
          .add({
        "monto": total,
        "fecha": FieldValue.serverTimestamp(),

        // 🔥 metadata PRO
        "origen": "venta",
        "id_venta": ventaRef.id,
        "id_cliente": clienteId,
        "descripcion": "Venta POS",

        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    // ================= UI =================
    setState(() {
      carrito.clear();
      clienteId = null;
      clienteNombre = null;
      mascotaNombre = null;
      clienteController.clear();

      ventaExitosa = true;
      ventaError = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✔ Venta registrada correctamente"),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        ventaExitosa = false;
      });
    });

    resetPOS();

  } catch (e) {
    setState(() {
      ventaError = true;
      ventaExitosa = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error en venta: $e"),
        backgroundColor: Colors.red,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        ventaError = false;
      });
    });
  }
}

void resetPOS() {
  setState(() {
    carrito.clear();
    clienteId = null;
    clienteNombre = null;
    mascotaNombre = null;
    clienteController.clear();
    searchProduct = "";
  });
}

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= LEFT (CARRITO) =================
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "VENTA EN PROCESO",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: carrito.length,
                      itemBuilder: (context, index) {
                        final p = carrito[index];

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(p["nombre"]),
                            subtitle: Text(
                                "Bs ${p["precio"]} x ${p["cantidad"]}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Bs ${p["subtotal"]}"),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => remove(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // PREVIEW
                  if (carrito.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "PREVIEW VENTA",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text("Cliente: $clienteNombre"),
                            Text("Mascota: ${mascotaNombre ?? '-'}"),
                            const Divider(),
                            ...carrito.map((p) => Text(
                                "${p["nombre"]} x${p["cantidad"]}")),
                            const Divider(),
                            Text(
                              "TOTAL: Bs ${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Color(0xFF0054A6),
                      ),
                      onPressed: finalizarVenta,
                      child: const Text("TERMINAR VENTA", style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ),

            const VerticalDivider(),

            // ================= RIGHT (PRODUCTOS) =================
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
  controller: clienteController,
  readOnly: true,
  decoration: InputDecoration(
    hintText: "Buscar mascota",
    prefixIcon: const Icon(Icons.search),
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onTap: _openClienteSearch,
),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Buscar producto",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (v) {
                        setState(() => searchProduct = v);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width < 600
                                ? 2
                                : 3,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: productosFiltrados.length,
                      itemBuilder: (context, i) {
                        final p = productosFiltrados[i];

                        return Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.2),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(p["nombre_pro"] ?? ""),
                              Text("Bs ${p["precio_venta"]}"),
                              ElevatedButton(
                                onPressed: () => addProduct(p, 1),
                                child: const Text("Agregar"),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CLIENT SEARCH =================
  void _openClienteSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        List<Map<String, dynamic>> filtered = clientes;

        return StatefulBuilder(
          builder: (context, setModal) {
            return Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Buscar...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    setModal(() {
                      filtered = clientes.where((c) {
                        final m = (c["nombre_mascota"] ?? "")
                            .toLowerCase();
                        final d = (c["nombre_dueno"] ?? "")
                            .toLowerCase();

                        return m.contains(v.toLowerCase()) ||
                            d.contains(v.toLowerCase());
                      }).toList();
                    });
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];

                      return ListTile(
                        title: Text(c["nombre_mascota"] ?? ""),
                        subtitle:
                            Text(c["nombre_dueno"] ?? ""),
                        onTap: () {
                          setState(() {
  clienteId = c["id"];
  clienteNombre = c["nombre"];
  mascotaNombre = c["nombre_mascota"];

  //  clienteController.text =
  //     "${mascotaNombre ?? ''} - ${clienteNombre ?? ''}";
   clienteController.text =
      mascotaNombre ?? '';

});
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }
}