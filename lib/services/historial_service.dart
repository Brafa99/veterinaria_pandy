import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getComprobante(String idHistorial) async {
    // 1. Historial
    final historialDoc =
        await _db.collection('historial').doc(idHistorial).get();

    final historial = historialDoc.data()!;

    // 2. Cliente
    final clienteDoc = await _db
        .collection('clientes')
        .doc(historial['id_cliente'].toString())
        .get();

    final cliente = clienteDoc.data()!;

    // 3. Usuario (vendedor)
    final usuarioDoc = await _db
        .collection('usuario')
        .doc(historial['id_sesion'].toString())
        .get();

    final usuario = usuarioDoc.data()!;

    // 4. Empresa
    final empresaDoc = await _db.collection('empresa').doc("1").get();
    final empresa = empresaDoc.data()!;

    return {
      "historial": historial,
      "cliente": cliente,
      "usuario": usuario,
      "empresa": empresa,
    };
  }
}