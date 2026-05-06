import 'package:flutter/material.dart';

class DashboardController {
  static final ValueNotifier<int> selectedIndex = ValueNotifier(0);

  // navegación normal
  static void goTo(int index) {
    selectedIndex.value = index;
  }

  // ================= EDICIONES =================
  static String? editingUserId;
  static String? editingClienteId;
  static String? editingHistorialId;

  static Map<String, dynamic>? selectedHistorial;

  // ================= REPORTES (IMPORTANTE) =================
    static String reportesHistorialMode = "range";
  static String reportesVentasMode = "range";

  static void setHistorialMode(String mode) {
    reportesHistorialMode = mode;
  }

  static void setVentasMode(String mode) {
    reportesVentasMode = mode;
  }
  static DateTime? reportStartDate;
  static DateTime? reportEndDate;
  static DateTime? reportSelectedDay;

  static int reportMonth = DateTime.now().month;
  static int reportYear = DateTime.now().year;

  static int ventasMonth = DateTime.now().month;
  static int ventasYear = DateTime.now().year;

  static DateTime? ventasStartDate;
  static DateTime? ventasEndDate;
  static DateTime? ventasSelectedDay;
}