const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

async function initDetallesVentasServicios() {
  console.log("🚀 Creando colección detalles_ventas_servicios (sin datos)");

  // 🔥 Opcional: crear un documento plantilla (recomendado)
  const ref = db.collection("detalles_ventas_servicios").doc("template");

  await ref.set({
    id_detalles: "",
    id_pedido: "",
    descripcion: "",
    monto: 0,

    // metadata útil
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    note: "Documento plantilla (estructura base)"
  });

  console.log("✅ Colección inicializada correctamente");
}

initDetallesVentasServicios().catch(console.error);