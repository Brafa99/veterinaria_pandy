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

// ---------------- MIGRACIÓN ----------------
async function migrarConfiguracion() {
  console.log("🚀 MIGRANDO CONFIGURACION...");

  const conn = await mysql.createConnection(mysqlConfig);

  const [rows] = await conn.execute(`
    SELECT * FROM configuracion
  `);

  console.log("📦 Total configuracion:", rows.length);

  for (const c of rows) {

    const ref = db.collection("configuracion").doc(String(c.id_configuracion));

    const data = {
      id_configuracion: String(c.id_configuracion),

      titulo: c.titulo || "",

      servicios1: c.servicios1 || "",
      servicios2: c.servicios2 || "",
      servicios3: c.servicios3 || "",

      mision: c.mision || "",
      vision: c.vision || "",

      imagen_galeria1: c.imagen_galeria1 || "",
      imagen_galeria2: c.imagen_galeria2 || "",

      direccion: c.direccion || "",

      google_maps: c.google_maps || "",
      facebook: c.facebook || "",
      twitter: c.twitter || "",

      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await ref.set(data, { merge: true });
  }

  console.log("✅ CONFIGURACION COMPLETADA");
  process.exit();
}

migrarConfiguracion().catch(console.error);