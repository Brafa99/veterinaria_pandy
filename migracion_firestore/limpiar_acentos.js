const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Función para corregir la codificación
function corregirCodificacion(str) {
    if (!str || typeof str !== 'string') return str;
    try {
        // Detecta si hay caracteres mal codificados y los re-convierte
        return Buffer.from(str, 'latin1').toString('utf8');
    } catch (e) {
        return str;
    }
}

async function limpiarColeccion() {
    console.log("🔍 Iniciando limpieza de caracteres en historial_v2...");
    
    const snapshot = await db.collection("historial_v2").get();
    let batch = db.batch();
    let count = 0;
    let totalCorregidos = 0;

    for (const doc of snapshot.docs) {
        const data = doc.data();
        let huboCambio = false;

        // Campos a revisar
        const campos = ['descripcion', 'nombre_dueno', 'nombre_mascota', 'raza', 'direccion'];
        const newData = {};

        campos.forEach(campo => {
            if (data[campo]) {
                const textoCorregido = corregirCodificacion(data[campo]);
                if (textoCorregido !== data[campo]) {
                    newData[campo] = textoCorregido;
                    huboCambio = true;
                }
            }
        });

        if (huboCambio) {
            batch.update(doc.ref, newData);
            totalCorregidos++;
            count++;
        }

        // Ejecutar lotes de 400 para no saturar
        if (count >= 400) {
            await batch.commit();
            console.log(`✅ Lote procesado: ${totalCorregidos} corregidos hasta ahora...`);
            batch = db.batch();
            count = 0;
        }
    }

    if (count > 0) await batch.commit();

    console.log("========================================");
    console.log(`🏁 LIMPIEZA TERMINADA`);
    console.log(`✔ Total de registros arreglados: ${totalCorregidos}`);
    console.log("========================================");
}

limpiarColeccion().catch(console.error);