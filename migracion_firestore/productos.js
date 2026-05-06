const admin = require("firebase-admin");
const fs = require("fs");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

// extraer data real
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

async function migrateProductos() {
  console.log("\n🚀 Migrando productos...");

  const fileContent = JSON.parse(fs.readFileSync("productos.json", "utf8"));
  const productos = extractData(fileContent);

  console.log(`📊 Total productos: ${productos.length}`);

  let batch = db.batch();
  let count = 0;

  for (const p of productos) {
    const clean = cleanData(p);

    const producto = {
      id_pro: clean.id_pro?.toString() || "",
      nombre_pro: clean.nombre_pro || "",
      descripcion: clean.descripcion || "",
      unidad: clean.unidad || "",
      precio_venta: Number(clean.precio_venta) || 0,
      precio_compra: Number(clean.precio_compra) || 0,
      imagen: clean.imagen || "",
      stock: Number(clean.stock) || 0,
      estado: clean.estado || "",
    };

    const ref = db.collection("productos").doc();
    batch.set(ref, producto);

    count++;

    // 🔥 commit cada 300
    if (count % 300 === 0) {
      await batch.commit();
      console.log(`✔ Subidos: ${count}`);
      batch = db.batch();
    }
  }

  await batch.commit();

  console.log(`✅ PRODUCTOS COMPLETADO (${count})`);
}

migrateProductos();