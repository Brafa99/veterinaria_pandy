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

async function migrate() {
  console.log("🚀 MIGRANDO ventas_servicios...");

  const conn = await mysql.createConnection(mysqlConfig);

  const [rows] = await conn.execute(`SELECT * FROM ventas_servicios`);

  console.log("📦 Total:", rows.length);

  for (const v of rows) {
    const ref = db.collection("ventas_servicios").doc(String(v.id_pedido));

    await ref.set({
      id_pedido: String(v.id_pedido),
      fecha: v.fecha || "",
      id_sesion: String(v.id_sesion || ""),
      id_cliente: String(v.id_cliente || "")
    });
  }

  console.log("✅ ventas_servicios COMPLETADO");
  process.exit();
}

migrate().catch(console.error);