import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatFecha(dynamic fecha) {
  try {
    DateTime? d;

    if (fecha is Timestamp) {
      d = fecha.toDate();
    } else if (fecha is String && fecha.isNotEmpty) {
      d = DateTime.tryParse(fecha);
    }

    if (d != null) {
      return DateFormat("dd/MM/yyyy").format(d); // 🔥 formato pro
    }
  } catch (_) {}

  return "-";
}