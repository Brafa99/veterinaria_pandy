const fs = require("fs");
const admin = require("firebase-admin");

// Inicialización de Firebase
admin.initializeApp({
    credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

// Configuración
const ULTIMO_ID_MIGRADO = 25791; // Filtro para no sobreescribir
const BATCH_SIZE = 200;
const DELAY = 500; // Milisegundos entre lotes para estabilidad

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

const normalizarFecha = (f) => {
    if (!f || f === "0000-00-00") return admin.firestore.Timestamp.now();
    const d = new Date(f);
    return isNaN(d.getTime()) ? admin.firestore.Timestamp.now() : admin.firestore.Timestamp.fromDate(d);
};

async function ejecutarMigracionFaltante() {
    console.log("📖 Leyendo archivos locales...");
    
    const rawData = JSON.parse(fs.readFileSync("historial_faltante.json", "utf8"));
    const clientes = JSON.parse(fs.readFileSync("clientes.json", "utf8"));

    // Extraer datos del formato phpMyAdmin
    const tablaHistorial = rawData.find(obj => obj.type === "table" && obj.data);
    if (!tablaHistorial) {
        console.error("❌ No se encontró la sección 'data' en el JSON.");
        return;
    }

    const historialTodo = tablaHistorial.data;

    // Crear mapa de clientes para acceso instantáneo
    const cMap = {};
    clientes.forEach(c => { 
        if(c.id_cliente) cMap[String(c.id_cliente).trim()] = c; 
    });

    // --- FILTRADO ---
    const historialFaltante = historialTodo.filter(h => {
        const id = parseInt(h.id_historial || h.id);
        return id > ULTIMO_ID_MIGRADO;
    });

    console.log(`🚀 Total en archivo: ${historialTodo.length}`);
    console.log(`🎯 Registros nuevos a subir: ${historialFaltante.length}`);

    if (historialFaltante.length === 0) {
        console.log("✅ No hay registros nuevos que procesar.");
        return;
    }

    let batch = db.batch();
    let count = 0;
    let totalSubidos = 0;

    for (const h of historialFaltante) {
        const idC = String(h.id_cliente || "").trim();
        const c = cMap[idC] || {};
        const idH = String(h.id_historial || h.id);

        const ref = db.collection("historial_v2").doc(idH);
        
        batch.set(ref, {
            descripcion: String(h.descripcion || ""),
            tipo_historial: h.tipo_historial || "Consulta Medica",
            precioh: Number(h.precioh) || Number(h.precio) || 0,
            fecha_registro: normalizarFecha(h.fecha_registro || h.fecha),
            id_cliente: idC,
            // Datos del cliente vinculados
            nombre_mascota: c.nombre_mascota || "Desconocido",
            nombre_dueno: c.nombre || c.nombre_dueno || "Sin nombre",
            telefono: c.telefono || "",
            especie: c.especie || "",
            raza: c.raza || "",
            sexo: c.sexo || "",
            color: c.color || "",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        count++;
        totalSubidos++;

        if (count >= BATCH_SIZE) {
            await batch.commit();
            console.log(`✅ Lote completado: ${totalSubidos} registros...`);
            batch = db.batch();
            count = 0;
            await sleep(DELAY);
        }
    }

    // Subir el último lote si quedó algo
    if (count > 0) {
        await batch.commit();
    }

    console.log("\n========================================");
    console.log(`🏁 MIGRACIÓN TERMINADA EXITOSAMENTE`);
    console.log(`✔ Se añadieron: ${totalSubidos} registros nuevos.`);
    console.log("========================================");
}

ejecutarMigracionFaltante().catch(console.error);