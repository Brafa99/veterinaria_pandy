import 'dart:convert';

String fixText(dynamic text) {
  if (text == null) return "-";

  String value = text.toString().trim();

  try {
    // 🔥 CORRECCIÓN REAL DE ENCODING
    final bytes = value.codeUnits;
    value = String.fromCharCodes(bytes);
  } catch (_) {}

  // 🔥 FIXES MANUALES (casos comunes)
  value = value
      .replaceAll("Ã¡", "á")
      .replaceAll("Ã©", "é")
      .replaceAll("Ã­", "í")
      .replaceAll("Ã³", "ó")
      .replaceAll("Ãº", "ú")
      .replaceAll("Ã±", "ñ")
      .replaceAll("Ã‘", "Ñ")
      .replaceAll("Â", "")
      .replaceAll("Ã", "");

  return value;
}