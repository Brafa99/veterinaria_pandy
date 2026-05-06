const admin = require("firebase-admin");
const fs = require("fs");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

// 🔍 extraer solo data real
function extractData(fileContent) {
  const table = fileContent.find(e => e.type === "table");
  return table?.data || [];
}

// limpiar nulls
function cleanData(item) {
  return Object.fromEntries(
    Object.entries(item).map(([k, v]) => [k, v ?? ""])
  );
}

async function migrateUsuarios() {
  console.log("\n🚀 Migrando usuarios...");

  const fileContent = JSON.parse(fs.readFileSync("usuarios.json", "utf8"));
  const usuarios = extractData(fileContent);

  console.log(`📊 Total usuarios: ${usuarios.length}`);

  let batch = db.batch();
  let count = 0;

  for (const u of usuarios) {
    const clean = cleanData(u);

    const user = {
      id: clean.id?.toString() || "",
      usuario: clean.usuario || "",
      password: "migrado", // 🔴 importante
      imagen: clean.imagen || "",
      tipo: clean.tipo || "",
      nombre: clean.nombre || "",
      apellido: clean.apellido || "",
      telefono: clean.telefono || "",
      correo: clean.correo || "",
    };

    const ref = db.collection("usuarios").doc();
    batch.set(ref, user);

    count++;

    // 🔥 commit cada 200 (usuarios suelen ser pocos)
    if (count % 200 === 0) {
      await batch.commit();
      console.log(`✔ Subidos: ${count}`);
      batch = db.batch();
    }
  }

  await batch.commit();

  console.log(`✅ USUARIOS COMPLETADO (${count})`);
}

migrateUsuarios();