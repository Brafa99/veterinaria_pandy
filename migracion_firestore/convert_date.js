const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

const db = admin.firestore();

const BATCH_SIZE = 200;

function parseFecha(fechaStr) {
  if (!fechaStr) return null;

  try {
    // caso "YYYY-MM-DD"
    const date = new Date(fechaStr);

    if (!isNaN(date.getTime())) {
      return admin.firestore.Timestamp.fromDate(date);
    }
  } catch (e) {}

  return null;
}

async function run() {
  console.log("🚀 Normalizando fechas...");

  const snapshot = await db.collection("historial_v2").get();

  let batch = db.batch();
  let count = 0;
  let updated = 0;
  let skipped = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const f = data.fecha_registro;

    // 🔥 SOLO convertir si es STRING
    if (typeof f === "string") {
      const parsed = parseFecha(f);

      if (parsed) {
        batch.update(doc.ref, {
          fecha_registro: parsed,
        });

        updated++;
        count++;
      } else {
        skipped++;
      }
    }

    if (count >= BATCH_SIZE) {
      await batch.commit();
      console.log(`✔ lote actualizado: ${updated}`);

      batch = db.batch();
      count = 0;
    }
  }

  if (count > 0) {
    await batch.commit();
  }

  console.log("================================");
  console.log("✅ TERMINADO");
  console.log("✔ convertidos:", updated);
  console.log("⚠ ignorados:", skipped);
}

run().catch(console.error);