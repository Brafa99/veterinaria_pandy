const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

async function test() {
  console.log("Probando conexión...");

  await db.collection("test").doc("1").set({
    ok: true,
    fecha: new Date()
  });

  console.log("✅ Conectado correctamente");
}

test();