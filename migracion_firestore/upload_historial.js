const admin = require("firebase-admin");
const fs = require("fs");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

const db = admin.firestore();
const data = JSON.parse(fs.readFileSync("historial_firestore.json", "utf8"));

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

async function upload() {
  console.log("🚀 INICIANDO SUBIDA:", data.length);

  const BATCH = 250;

  for (let i = 0; i < data.length; i += BATCH) {

    const chunk = data.slice(i, i + BATCH);
    const batch = db.batch();

    chunk.forEach(item => {
      const ref = db.collection("historial").doc(item.id);
      batch.set(ref, item.data, { merge: true });
    });

    let success = false;
    let attempts = 0;

    while (!success && attempts < 5) {
      try {
        await batch.commit();
        success = true;
        console.log(`✔ Subidos: ${i + chunk.length}/${data.length}`);
      } catch (e) {
        attempts++;
        console.log(`⚠ Retry ${attempts}/5`);

        await sleep(2000 * attempts);
      }
    }

    if (!success) {
      console.log("❌ Batch falló definitivamente en:", i);
      break;
    }

    await sleep(600); // evita quota
  }

  console.log("🔥 MIGRACIÓN FINALIZADA");
}

upload();