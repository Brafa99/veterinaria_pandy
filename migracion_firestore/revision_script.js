const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function verFaltantes() {
    console.log("🔍 Localizando los últimos 13 registros...");
    const snapshot = await db.collection("historial_v2").get();
    
    let faltantes = 0;
    snapshot.forEach(doc => {
        const data = doc.data();
        if (!data.nombre_dueno || data.nombre_dueno === "Desconocido" || data.nombre_dueno.trim() === "") {
            faltantes++;
            console.log(`❌ Faltante #${faltantes} | ID Doc: ${doc.id} | ID Cliente en este registro: ${data.id_cliente}`);
        }
    });
    console.log("\nBusca estos IDs de Cliente en tu SQL original para ver quiénes son.");
}

verFaltantes().catch(console.error);