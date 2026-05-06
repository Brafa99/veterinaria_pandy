const mysql = require("mysql2/promise");
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const START_AT = 175; // 👈 cambia según donde se quedó

const mysqlConfig = {
  host: "localhost",
  user: "root",
  password: "",
  database: "veterinaria_sistemasenoferta",
};

// ---------------- UTIL ----------------
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

// 🔥 TIMESTAMP REAL
function toTimestamp(value) {
  if (!value || value === "0000-00-00") {
    return admin.firestore.Timestamp.now();
  }

  const d = new Date(value);

  if (isNaN(d.getTime())) {
    console.warn("⚠️ Fecha inválida:", value);
    return admin.firestore.Timestamp.now();
  }

  return admin.firestore.Timestamp.fromMillis(d.getTime());
}

// ---------------- RETRY ----------------
async function commitWithRetry(batch, retries = 5) {
  for (let i = 0; i < retries; i++) {
    try {
      await batch.commit();
      return;
    } catch (err) {
      console.log(`⚠️ Retry ${i + 1}/${retries}`);

      if (err.code === 8) {
        console.log("🔥 Quota detectada → esperando 10s...");
        await sleep(10000);
      } else {
        await sleep(2000 * (i + 1));
      }
    }
  }

  throw new Error("❌ Falló commit");
}

// ---------------- MAIN ----------------
async function migrarHistorialPro() {
  console.log("🔥 INICIANDO MIGRACIÓN HISTORIAL...");

  const conn = await mysql.createConnection(mysqlConfig);

  const [rows] = await conn.execute(`
    SELECT 
      h.*,
      c.nombre,
      c.telefono,
      c.dni,
      c.correo,
      c.direccion,
      c.nombre_mascota,
      c.raza,
      c.color,
      c.especie,
      c.sexo,
      c.fechanac
    FROM historial h
    LEFT JOIN clientes c ON c.id_cliente = h.id_cliente
  `);

  console.log("📦 Total registros:", rows.length);

  const batchSize = 25;
  let batch = db.batch();
  let ops = 0;
  let total = 0;

  let index = 0;

for (const row of rows) {

  if (index < START_AT) {
    index++;
    continue; // 🔥 salta lo ya subido
  }

  const docRef = db.collection("historial").doc();

  const data = {
    id_historial: String(row.id_historial || ""),
    id_cliente: String(row.id_cliente || ""),

    nombre_dueno: row.nombre || "",
    telefono: row.telefono || "",
    ci: row.dni || "",
    correo: row.correo || "",
    direccion: row.direccion || "",

    nombre_mascota: row.nombre_mascota || "",
    raza: row.raza || "",
    color: row.color || "",
    especie: row.especie || "",
    sexo: row.sexo || "",
    fecha_nacimiento: toTimestamp(row.fechanac),

    descripcion: row.descripcion === "." ? "" : (row.descripcion || ""),
    tipo_servicio: row.tipo_historial || "General",
    precioh: Number(row.precioh) || 0,
    archivoh: row.archivoh || "",

    fecha_registro: toTimestamp(row.fecha_registro),

    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  batch.set(docRef, data);

  ops++;
  total++;
  index++;

  if (ops >= 25) {
    await commitWithRetry(batch);

    console.log(`✔ Migrado: ${total}/${rows.length}`);

    batch = db.batch();
    ops = 0;

    await sleep(3000); // 🔥 más pausa
  }
}

  console.log("🚀 MIGRACIÓN COMPLETA:", total);
  process.exit();
}

migrarHistorialPro();