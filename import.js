const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const data = require("./data.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function importData() {
  try {
    for (const collectionName in data) {
      const items = data[collectionName];

      console.log(`Subiendo colección: ${collectionName}`);

      for (const item of items) {
        await db.collection(collectionName).add(item);
      }
    }

    console.log("✅ Datos importados correctamente");
    process.exit();
  } catch (error) {
    console.error("❌ Error:", error);
    process.exit(1);
  }
}

importData();