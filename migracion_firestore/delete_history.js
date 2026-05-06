const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

const db = admin.firestore();

async function deleteCollection(collectionPath, batchSize = 300) {
  const collectionRef = db.collection(collectionPath);

  while (true) {
    const snapshot = await collectionRef.limit(batchSize).get();

    if (snapshot.empty) {
      console.log("✅ Colección eliminada completamente");
      break;
    }

    const batch = db.batch();

    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`🗑 Eliminados: ${snapshot.size}`);
  }
}

deleteCollection("historial");