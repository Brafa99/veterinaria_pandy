const fs = require("fs");
const admin = require("firebase-admin");

admin.initializeApp({
    credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

// Función rápida para las fechas
const normalizarFecha = (f) => {
    if (!f || f === "0000-00-00") return admin.firestore.Timestamp.now();
    const d = new Date(f);
    return isNaN(d.getTime()) ? admin.firestore.Timestamp.now() : admin.firestore.Timestamp.fromDate(d);
};

async function subir() {
    const historial = JSON.parse(fs.readFileSync("historial_faltante.json", "utf8"));
    const clientes = JSON.parse(fs.readFileSync("clientes.json", "utf8"));

    // 1. Mapa de clientes para no perder tiempo buscando
    const cMap = {};
    clientes.forEach(c => { if(c.id_cliente) cMap[String(c.id_cliente).trim()] = c; });

    console.log(`🚀 Subiendo ${historial.length} registros...`);

    let batch = db.batch();
    let count = 0;

    for (const h of historial) {
        const idC = String(h.id_cliente || "").trim();
        const c = cMap[idC] || {};
        const idH = String(h.id_historial || h.id);

        const ref = db.collection("historial_v2").doc(idH);
        
        batch.set(ref, {
            descripcion: String(h.descripcion || ""),
            tipo_historial: h.tipo_historial || "Consulta Medica",
            precioh: Number(h.precio) || 0,
            fecha_registro: normalizarFecha(h.fecha || h.fecha_registro),
            id_cliente: idC,
            // Datos del cliente vinculados
            nombre_mascota: c.nombre_mascota || "Desconocido",
            nombre_dueno: c.nombre || c.nombre_dueno || "Sin nombre",
            telefono: c.telefono || "",
            especie: c.especie || "",
            raza: c.raza || "",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        count++;
        if (count % 200 === 0) { // Cada 200 registros mandamos el paquete
            await batch.commit();
            batch = db.batch();
            console.log(`✅ ${count} procesados...`);
        }
    }

    await batch.commit();
    console.log("🏁 ¡TERMINADO! Revisa tu Firebase.");
}

subir().catch(console.error);