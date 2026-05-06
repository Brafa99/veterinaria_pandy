const admin = require("firebase-admin");
const fs = require("fs");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

// extraer data phpMyAdmin
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

// detectar si es número (telefono)
function isPhone(value) {
  return /^\d{6,}$/.test(value);
}

async function migrateClientes() {
  console.log("\n🚀 Migrando clientes...");

  const fileContent = JSON.parse(fs.readFileSync("clientes.json", "utf8"));
  const clientes = extractData(fileContent);

  console.log(`📊 Total clientes: ${clientes.length}`);

  let batch = db.batch();
  let count = 0;

  for (const c of clientes) {
    const clean = cleanData(c);

    let telefono = clean.telefono || "";
    let direccion = clean.direccion || "";

    // 🔥 corregir campos cruzados
    if (!isPhone(telefono) && isPhone(direccion)) {
      const temp = telefono;
      telefono = direccion;
      direccion = temp;
    }

    const cliente = {
      id_cliente: clean.id_cliente?.toString() || "",
      nombre: clean.nombre || "",
      telefono: telefono,
      nombre_mascota: clean.nombre_mascota || "",
      dni: clean.dni || "",
      fechanac: clean.fechanac || "",
      raza: clean.raza || "",
      correo: clean.correo === "." ? "" : clean.correo,
      color: clean.color || "",
      especie: clean.especie || "",
      sexo: clean.sexo || "",
      direccion: direccion,
    };

    const ref = db.collection("clientes").doc();
    batch.set(ref, cliente);

    count++;

    // 🔥 commit cada 300 (evita quota / timeout)
    if (count % 300 === 0) {
      await batch.commit();
      console.log(`✔ Subidos: ${count}`);
      batch = db.batch();
    }
  }

  await batch.commit();

  console.log(`✅ CLIENTES COMPLETADO (${count})`);
}

migrateClientes();