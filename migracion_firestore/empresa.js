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

// ---------------- MIGRACIÓN ----------------
async function migrarEmpresa() {
  console.log("🚀 MIGRANDO EMPRESA...");

  const conn = await mysql.createConnection(mysqlConfig);

  const [rows] = await conn.execute(`
    SELECT * FROM empresa
  `);

  console.log("📦 Total empresa registros:", rows.length);

  const batch = db.batch();
  let total = 0;

  for (const e of rows) {

    const ref = db.collection("empresa").doc(String(e.id_empresa));

    const data = {
      id_empresa: String(e.id_empresa),

      empresa: e.empresa || "",
      ruc: e.ruc || "",
      direccion: e.direccion || "",
      telefono: e.telefono || "",
      descripcion: e.descripcion || "",
      imagen: e.imagen || "",
      correo: e.correo || "",
      moneda: e.moneda || "",
      simbolo_moneda: e.simbolo_moneda || "",
      impuesto_producto: Number(e.impuesto_producto) || 0,

      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    batch.set(ref, data, { merge: true });

    total++;
  }

  await batch.commit();

  console.log("✅ EMPRESA COMPLETADO:", total);
  process.exit();
}

migrarEmpresa().catch(console.error);