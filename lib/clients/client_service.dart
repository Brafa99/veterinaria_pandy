import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veterinaria_pandy/clients/client_model.dart';

class ClienteService {
  final _db = FirebaseFirestore.instance.collection('clientes');

  // CREATE
  Future<void> crearCliente(Cliente cliente) async {
    await _db.doc(cliente.idCliente).set(cliente.toMap());
  }

  // READ
  Stream<List<Cliente>> getClientes() {
    return _db.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Cliente.fromMap(doc.data(), doc.id)).toList());
  }

  // UPDATE
  Future<void> actualizarCliente(Cliente cliente) async {
    await _db.doc(cliente.idCliente).update(cliente.toMap());
  }

  // DELETE
  Future<void> eliminarCliente(String id) async {
    await _db.doc(id).delete();
  }
}