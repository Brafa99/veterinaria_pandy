const admin = require("firebase-admin");
const fs = require("fs");

// 🔐 Inicializar Firebase Admin (NUEVO proyecto)
admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccount.json"))
});

const db = admin.firestore();

// 🔧 Función para limpiar datos
function cleanData(item) {
  return Object.fromEntries(
    Object.entries(item).map(([key, value]) => {
      if (value === null || value === undefined) return [key, ""];
      return [key, value];
    })
  );
}

// 🔄 Migrador genérico
async function migrateCollection(fileName, collectionName) {
  console.log(`\n🚀 Migrando colección: ${collectionName}`);

  const rawData = JSON.parse(fs.readFileSync(fileName, "utf8"));

  for (const item of rawData) {
    try {
      const cleanItem = cleanData(item);

      // 🔴 Normalización de IDs
      if (cleanItem.id) cleanItem.id = cleanItem.id.toString();
      if (cleanItem.id_cliente) cleanItem.id_cliente = cleanItem.id_cliente.toString();
      if (cleanItem.id_pro) cleanItem.id_pro = cleanItem.id_pro.toString();

      // 🔵 Campos numéricos (productos)
      if (cleanItem.precio_venta)
        cleanItem.precio_venta = Number(cleanItem.precio_venta);

      if (cleanItem.precio_compra)
        cleanItem.precio_compra = Number(cleanItem.precio_compra);

      if (cleanItem.stock)
        cleanItem.stock = Number(cleanItem.stock);

      await db.collection(collectionName).add(cleanItem);

    } catch (error) {
      console.error("❌ Error en item:", item);
      console.error(error);
    }
  }

  console.log(`✅ ${collectionName} migrado correctamente`);
}

// ▶️ Ejecutar migración
async function runMigration() {
  await migrateCollection("usuarios.json", "usuarios");
  await migrateCollection("clientes.json", "clientes");
  await migrateCollection("productos.json", "productos");

  console.log("\n🔥 MIGRACIÓN COMPLETA");
}

runMigration();