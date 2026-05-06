const fs = require("fs");
const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

const HISTORIAL_FILE = "historial.json";
const CLIENTES_FILE = "clientes.json";

const BATCH_SIZE = 200;
const DELAY = 800;

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// ================= LOAD JSON (ROBUSTO PHPADMIN + NORMAL) =================
function loadJSON(file) {
  const raw = JSON.parse(fs.readFileSync(file, "utf8"));

  // 🔥 CASO PHPMyAdmin EXPORT
  if (Array.isArray(raw)) {
    const table = raw.find(x => x.type === "table");
    if (table?.data) return table.data;
  }

  // 🔥 CASO FIREBASE / ARRAY DIRECTO
  if (Array.isArray(raw)) return raw;

  // 🔥 CASO { data: [...] }
  if (raw?.data && Array.isArray(raw.data)) return raw.data;

  // 🔥 CASO OBJETO MAP
  return Object.values(raw || {});
}

const historial = loadJSON(HISTORIAL_FILE);
const clientes = loadJSON(CLIENTES_FILE);

// ================= DEBUG REAL =================
console.log("🚀 MIGRACIÓN HISTORIAL FINAL");
console.log("📦 HISTORIAL:", historial.length);
console.log("👥 CLIENTES:", clientes.length);

// ================= INDEX CLIENTES =================
const clientesMap = {};
for (const c of clientes) {
  if (!c || !c.id_cliente) continue;
  clientesMap[String(c.id_cliente).trim()] = c;
}

// ================= SAFE =================
function safe(v) {
  if (v === undefined || v === null) return "";
  return String(v);
}

// ================= MAIN =================
async function run() {
  let batch = db.batch();
  let ops = 0;
  let saved = 0;
  let skipped = 0;
  let notFound = 0;

  for (let i = 0; i < historial.length; i++) {
    const h = historial[i];
    if (!h) {
      skipped++;
      continue;
    }

    const idCliente = String(h.id_cliente || "").trim();
    const cliente = clientesMap[idCliente];

    if (!cliente) notFound++;

    const ref = db.collection("historial_v2").doc();

    batch.set(ref, {
      // ===== HISTORIAL =====
      descripcion: safe(h.descripcion),
      tipo_historial: safe(h.tipo_historial),
      precioh: Number(h.precioh) || 0,
      fecha_registro: h.fecha_registro || null,

      // ===== CLIENTE =====
      nombre_mascota: safe(cliente?.nombre_mascota),
      raza: safe(cliente?.raza),
      color: safe(cliente?.color),
      especie: safe(cliente?.especie),
      sexo: safe(cliente?.sexo),
      fechanac: safe(cliente?.fechanac),

      nombre_dueno: safe(cliente?.nombre),
      telefono: safe(cliente?.telefono),
      direccion: safe(cliente?.direccion),
      ci: safe(cliente?.dni),
      correo: safe(cliente?.correo),

      id_cliente: idCliente,

      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    ops++;
    saved++;

    if (ops >= BATCH_SIZE) {
      await batch.commit();

      console.log(`✔ progres: ${saved}/${historial.length}`);

      batch = db.batch();
      ops = 0;

      await sleep(DELAY);
    }
  }

  if (ops > 0) await batch.commit();

  console.log("================================");
  console.log("✅ MIGRACIÓN TERMINADA");
  console.log("✔ guardados:", saved);
  console.log("⚠ sin cliente:", notFound);
  console.log("⛔ nulos:", skipped);
}

run().catch(console.error);