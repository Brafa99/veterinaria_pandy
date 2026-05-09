const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const fs = require("fs");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Cargar el JSON de clientes (Asegúrate de que sea el más actualizado)
const clientesRaw = JSON.parse(fs.readFileSync("clientes.json", "utf8"));
const clientesData = clientesRaw[2].data;

// Mapa de búsqueda rápida
const clientesMap = {};
clientesData.forEach(c => {
    const idStr = String(c.id_cliente).trim();
    const idNum = String(parseInt(c.id_cliente));
    clientesMap[idStr] = c;
    clientesMap[idNum] = c;
});

async function reparar() {
    const snapshot = await db.collection("historial_v2").get();
    let batch = db.batch();
    let editados = 0;
    let count = 0;

    console.log("🛠️ Iniciando reparación en Firestore...");

    for (const doc of snapshot.docs) {
        const data = doc.data();
        const idCliente = String(data.id_cliente).trim();
        
        // Condición: Si el nombre es Desconocido o está vacío, intentamos reparar
        if (!data.nombre_dueno || data.nombre_dueno === "Desconocido" || data.nombre_dueno === "") {
            const infoReal = clientesMap[idCliente];

            if (infoReal) {
                batch.update(doc.ref, {
                    nombre_dueno: infoReal.nombre || "Sin nombre en DB",
                    nombre_mascota: infoReal.nombre_mascota || "Sin nombre",
                    ci: infoReal.dni || "",
                    telefono: infoReal.telefono || "",
                    raza: infoReal.raza || "",
                    especie: infoReal.especie || "Canina",
                    sexo: infoReal.sexo || "",
                    color: infoReal.color || ""
                });
                editados++;
            }
        }

        count++;
        // Commit cada 400 para no saturar el límite de Firebase
        if (editados > 0 && editados % 400 === 0) {
            await batch.commit();
            batch = db.batch();
            console.log(`✅ ${editados} documentos reparados hasta ahora...`);
        }
    }

    if (editados % 400 !== 0) await batch.commit();
    console.log(`\n🏁 Proceso terminado.`);
    console.log(`- Documentos revisados: ${count}`);
    console.log(`- Documentos reparados exitosamente: ${editados}`);
}

reparar().catch(console.error);