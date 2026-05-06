const mysql = require("mysql2/promise");
const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

const mysqlConfig = {
  host: "localhost",
  user: "root",
  password: "",
  database: "veterinaria_sistemasenoferta",
};

// ---------------- UTIL ----------------
function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

function toTimestamp(value) {
  if (!value || value === "0000-00-00") {
    return admin.firestore.Timestamp.now();
  }

  const d = new Date(value);
  if (isNaN(d.getTime())) {
    return admin.firestore.Timestamp.now();
  }

  return admin.firestore.Timestamp.fromDate(d);
}

// ---------------- MIGRACIÓN ----------------
async function migrarDetalles() {
  console.log("🚀 MIGRANDO DETALLES_PEDIDO...");

  const conn = await mysql.createConnection(mysqlConfig);

  const [rows] = await conn.execute(`
    SELECT * FROM detalles_pedido
  `);

  console.log("📦 Total detalles:", rows.length);

  const batchSize = 250;
  let batch = db.batch();
  let ops = 0;
  let total = 0;

  for (const d of rows) {

    const ref = db.collection("detalles_pedido").doc(String(d.id_detalles));

    const data = {
      id_detalles: String(d.id_detalles),
      id_pedido: String(d.id_pedido || ""),
      id_producto: String(d.id_producto || ""),
      id_cliente: String(d.id_cliente || ""),
      cantidad: Number(d.cantidad) || 0,
      fecha: toTimestamp(d.fecha),

      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    batch.set(ref, data);

    ops++;
    total++;

    if (ops >= batchSize) {
      await batch.commit();

      console.log(`✔ Migrados: ${total}/${rows.length}`);

      batch = db.batch();
      ops = 0;

      await sleep(800);
    }
  }

  if (ops > 0) {
    await batch.commit();
  }

  console.log("✅ DETALLES_PEDIDO COMPLETADO:", total);
  process.exit();
}

migrarDetalles().catch(console.error);