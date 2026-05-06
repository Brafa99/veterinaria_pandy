import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/dashboard/dashboard_page.dart';
import 'package:veterinaria_pandy/services/file_service.dart';

class DatabaseBackupPage extends StatefulWidget {
  const DatabaseBackupPage({super.key});

  @override
  State<DatabaseBackupPage> createState() =>
      _DatabaseBackupPageState();
}

class _DatabaseBackupPageState
    extends State<DatabaseBackupPage> {

  bool isProcessing = false;
  double progress = 0;
  String currentStep = "";
  bool cancelRequested = false;

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
        title: const Text("Respaldo de base de datos"),
        content: const Text(
          "Se generará un archivo JSON con toda la información del sistema.\n\n"
          "Este proceso puede tardar dependiendo del volumen de datos.\n\n"
          "No cierre la aplicación mientras se ejecuta.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Iniciar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await backupWithProgress();
    } else {
      _goBack();
    }
  }

  /// ================= BACKUP =================
  Future<void> backupWithProgress() async {
    setState(() {
      isProcessing = true;
      progress = 0;
      cancelRequested = false;
    });

    final collections = [
      "usuarios",
      "clientes",
      "productos",
      "ventas",
      //"historial_v2", // ⚠️ cuidado: puede ser enorme
      "configuracion",
      "empresa",
      "pedidos",
    ];

    final Map<String, dynamic> data = {};

    for (int i = 0; i < collections.length; i++) {
      if (cancelRequested) break;

      final col = collections[i];

      setState(() {
        currentStep = "Procesando $col...";
        progress = i / collections.length;
      });

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection(col)
            .get();

        data[col] = snapshot.docs
            .map((d) => {
                  "id": d.id,
                  ...d.data(),
                })
            .toList();
      } catch (e) {
        data[col] = [];
      }
    }

    if (!cancelRequested) {
      setState(() {
        currentStep = "Generando archivo...";
        progress = 0.9;
      });

      final jsonString = jsonEncode(data);

      final fileName =
          "backup_${DateTime.now().millisecondsSinceEpoch}.json";

      /// 🔥 AQUÍ USAMOS TU FILE SERVICE (CLAVE)
      await FileService.saveOrDownload(
        utf8.encode(jsonString),
        fileName,
      );

      setState(() {
        progress = 1;
        currentStep = "Completado";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Backup generado: $fileName")),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      isProcessing = false;
    });

    _goBack();
  }

  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardPage(),
      ),
    );
  }

  void cancelProcess() {
    cancelRequested = true;
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isProcessing
            ? Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Generando respaldo...",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    LinearProgressIndicator(value: progress),

                    const SizedBox(height: 10),

                    Text(currentStep),

                    const SizedBox(height: 20),

                    Text("${(progress * 100).toStringAsFixed(0)}%"),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: cancelProcess,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      child: const Text("Cancelar"),
                    ),
                  ],
                ),
              )
            : const Text("Preparando respaldo..."),
      ),
    );
  }
}