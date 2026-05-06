const fs = require("fs");

const raw = JSON.parse(fs.readFileSync("historial.json", "utf8"));

// 🔥 EXTRAER SOLO LOS DATOS REALES
const table = raw.find(e => e.type === "table");

if (!table || !table.data) {
  console.log("❌ No se encontró data");
  process.exit();
}

const data = table.data;

console.log("📊 TOTAL REAL:", data.length);

// 🔥 DIVISIÓN
const CHUNK_SIZE = 4000;

for (let i = 0; i < data.length; i += CHUNK_SIZE) {
  const chunk = data.slice(i, i + CHUNK_SIZE);

  fs.writeFileSync(
    `historial_${i}.json`,
    JSON.stringify(chunk, null, 2)
  );

  console.log(`✔ Archivo creado: historial_${i}.json`);
}