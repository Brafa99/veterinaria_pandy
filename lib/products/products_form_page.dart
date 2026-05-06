import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_controller.dart';

class ProductoFormPage extends StatefulWidget {
  final String? productId;

  const ProductoFormPage({super.key, this.productId});

  @override
  State<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends State<ProductoFormPage> {

  final nombre = TextEditingController();
  final descripcion = TextEditingController();
  final unidad = TextEditingController();
  final precioCompra = TextEditingController();
  final precioVenta = TextEditingController();
  final stock = TextEditingController();

  String estado = "d";

  bool loading = false;
  bool isEdit = false;

  @override
  void initState() {
    super.initState();

    if (widget.productId != null) {
      isEdit = true;
      _loadProduct();
    }
  }

  @override
  void didUpdateWidget(covariant ProductoFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.productId != oldWidget.productId) {
      if (widget.productId != null) {
        isEdit = true;
        _loadProduct();
      } else {
        isEdit = false;
        _clearForm();
      }
    }
  }

  void _clearForm() {
    nombre.clear();
    descripcion.clear();
    unidad.clear();
    precioCompra.clear();
    precioVenta.clear();
    stock.clear();
    estado = "d";

    setState(() {});
  }

  Future<void> _loadProduct() async {
    if (widget.productId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("productos")
        .doc(widget.productId)
        .get();

    if (!doc.exists) return;

    final d = doc.data()!;

    setState(() {
      nombre.text = d["nombre_pro"] ?? "";
      descripcion.text = d["descripcion"] ?? "";
      unidad.text = d["unidad"] ?? "";
      precioCompra.text = (d["precio_compra"] ?? "").toString();
      precioVenta.text = (d["precio_venta"] ?? "").toString();
      stock.text = (d["stock"] ?? "").toString();
      estado = d["estado"] ?? "d";
    });
  }

  Future<void> guardar() async {
    setState(() => loading = true);

    try {
      final data = {
        "nombre_pro": nombre.text.trim(),
        "descripcion": descripcion.text.trim(),
        "unidad": unidad.text.trim(),
        "precio_compra": int.tryParse(precioCompra.text) ?? 0,
        "precio_venta": int.tryParse(precioVenta.text) ?? 0,
        "stock": int.tryParse(stock.text) ?? 0,
        "estado": estado,
        "imagen": "",
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (isEdit) {
        await FirebaseFirestore.instance
            .collection("productos")
            .doc(widget.productId)
            .update(data);
      } else {
        data["createdAt"] = FieldValue.serverTimestamp();

        await FirebaseFirestore.instance
            .collection("productos")
            .add(data);
      }

      if (!mounted) return;

      DashboardController.goTo(7); // 🔥 volver a lista productos

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double maxWidth;
    if (width < 600) {
      maxWidth = double.infinity; // móvil
    } else if (width < 1100) {
      maxWidth = 600; // tablet
    } else {
      maxWidth = 700; // desktop
    }

    return Container(
      color: const Color(0xFFF4F6FA),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _formContent(),
          ),
        ),
      ),
    );
  }

  Widget _formContent() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
      ),
      child: Column(
        children: [

          Row(
            children: [
              Text(
                isEdit ? "Editar Producto" : "Registrar Producto",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Divider(height: 25),

          _title("Información"),
          _field(Icons.inventory, "Nombre", nombre),
          _field(Icons.description, "Descripción", descripcion),

          const SizedBox(height: 10),

          _title("Detalles"),
          _field(Icons.category, "Unidad", unidad),

          DropdownButtonFormField(
            value: estado,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.toggle_on),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "d", child: Text("Disponible")),
              DropdownMenuItem(value: "n", child: Text("No disponible")),
            ],
            onChanged: (v) => setState(() => estado = v.toString()),
          ),

          const SizedBox(height: 10),

          _title("Precios"),
          _field(Icons.attach_money, "Precio compra", precioCompra, number: true),
          _field(Icons.money, "Precio venta", precioVenta, number: true),

          const SizedBox(height: 10),

          _title("Inventario"),
          _field(Icons.storage, "Stock", stock, number: true),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: Icon(
                isEdit ? Icons.update : Icons.save,
                color: Colors.white,
              ),
              label: Text(
                isEdit ? "Actualizar Producto" : "Guardar Producto",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEdit ? Colors.blue : Colors.green,
              ),
              onPressed: loading ? null : guardar,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    IconData icon,
    String label,
    TextEditingController controller, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10, top: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
        ),
      ),
    );
  }
}