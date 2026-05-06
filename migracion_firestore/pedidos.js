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
async function migrarPedidos() {
  console.log("🚀 MIGRANDO PEDIDOS...");

  const conn = await mysql.createConnection(mysqlConfig);

  const [rows] = await conn.execute(`
    SELECT * FROM pedidos
  `);

  console.log("📦 Total pedidos:", rows.length);

  const batchSize = 200;
  let batch = db.batch();
  let ops = 0;
  let total = 0;

  for (const p of rows) {

    const ref = db.collection("pedidos").doc(String(p.id_pedido));

    const data = {
      id_pedido: String(p.id_pedido),
      fecha: toTimestamp(p.fecha),
      id_sesion: String(p.id_sesion || ""),
      id_cliente: String(p.id_cliente || ""),
      monto_pagado: Number(p.monto_pagado) || 0,

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

      await sleep(800); // 🔥 pequeño descanso seguro
    }
  }

  if (ops > 0) {
    await batch.commit();
  }

  console.log("✅ PEDIDOS COMPLETADO:", total);
  process.exit();
}

migrarPedidos().catch(console.error);