import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_page.dart';

class DatabaseEmptyPage extends StatefulWidget {
  const DatabaseEmptyPage({super.key});

  @override
  State<DatabaseEmptyPage> createState() =>
      _DatabaseEmptyPageState();
}

class _DatabaseEmptyPageState
    extends State<DatabaseEmptyPage> {

  bool loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(showConfirm);
  }

  /// ================= CONFIRM =================
  Future<void> showConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("⚠ Vaciar base de datos"),
        content: const Text(
          "Esta acción eliminará TODOS los registros del sistema.\n\n"
          "No se puede deshacer.\n\n"
          "Puede tardar dependiendo de la cantidad de datos.",
        ),
        actions: [
          TextButton(
            onPressed: _goBack,
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí, vaciar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await clearDatabase();
    } else {
      _goBack();
    }
  }

  /// ================= DELETE =================
  Future<void> clearDatabase() async {
    setState(() => loading = true);

    final collections = [
      "usuarios",
      "clientes",
      "productos",
      "ventas",
      "historial_v2",
      "pedidos",
      // ⚠ puedes excluir:
      // "configuracion",
      // "empresa",
    ];

    final db = FirebaseFirestore.instance;

    for (var col in collections) {
      final snapshot = await db.collection(col).get();

      final docs = snapshot.docs;

      for (var i = 0; i < docs.length; i += 500) {
        final batch = db.batch();

        final chunk = docs.skip(i).take(500);

        for (var doc in chunk) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    }

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Base de datos vaciada correctamente")),
    );

    _goBack();
  }

  /// ================= NAV =================
  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardPage(),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : const Text("Procesando..."),
      ),
    );
  }
}