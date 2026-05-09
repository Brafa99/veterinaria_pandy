const fs = require("fs");
const admin = require("firebase-admin");

admin.initializeApp({
    credential: admin.credential.cert(require("./serviceAccountKey.json"))
});

const db = admin.firestore();

// Mismo límite para actuar solo sobre los registros que acabas de subir
const ULTIMO_ID_MIGRADO = 25791;

const normalizarFecha = (f) => {
    if (!f || f === "0000-00-00") return admin.firestore.Timestamp.now();
    const d = new Date(f);
    return isNaN(d.getTime()) ? admin.firestore.Timestamp.now() : admin.firestore.Timestamp.fromDate(d);
};

async function repararRegistros() {
    console.log("📖 Leyendo archivos para reparación...");
    
    const rawHistorial = JSON.parse(fs.readFileSync("historial_faltante.json", "utf8"));
    const rawClientes = JSON.parse(fs.readFileSync("clientes_total.json", "utf8"));

    // 1. Extraer historial (formato phpMyAdmin)
    const tablaH = rawHistorial.find(obj => obj.type === "table" && obj.data);
    const historialTodo = tablaH ? tablaH.data : (Array.isArray(rawHistorial) ? rawHistorial : []);

    // 2. Extraer clientes (formato phpMyAdmin o Array directo)
    // BUSCAMOS 'data' TAMBIÉN EN CLIENTES
    const tablaC = rawClientes.find(obj => obj.type === "table" && obj.data);
    const clientesTodo = tablaC ? tablaC.data : (Array.isArray(rawClientes) ? rawClientes : []);

    // 3. Crear mapa de clientes (Indexación)
    const cMap = {};
    clientesTodo.forEach(c => { 
        if(c.id_cliente) cMap[String(c.id_cliente).trim()] = c; 
    });

    // 4. Filtrar solo los que acabamos de subir (del 25792 en adelante)
    const historialAFijar = historialTodo.filter(h => {
        const id = parseInt(h.id_historial || h.id);
        return id > ULTIMO_ID_MIGRADO;
    });

    console.log(`👥 Clientes cargados en memoria: ${Object.keys(cMap).length}`);
    console.log(`🎯 Registros a reparar: ${historialAFijar.length}`);

    if (Object.keys(cMap).length === 0) {
        console.error("❌ ERROR: El mapa de clientes está vacío. Revisa el formato de clientes.json");
        return;
    }

    let batch = db.batch();
    let count = 0;

    for (const h of historialAFijar) {
        const idC = String(h.id_cliente || "").trim();
        const c = cMap[idC]; // Buscamos el cliente

        if (!c) {
            console.log(`⚠️ No se encontró cliente para ID: ${idC} en el registro ${h.id_historial}`);
            // Si no lo encuentra, saltamos o seguimos, pero el mapa ya debería tener datos
        }

        const idH = String(h.id_historial || h.id);
        const ref = db.collection("historial_v2").doc(idH);
        
        // Sobrescribimos el documento con los campos correctos del mapa
        batch.set(ref, {
            descripcion: String(h.descripcion || ""),
            tipo_historial: h.tipo_historial || "Consulta Medica",
            precioh: Number(h.precioh) || Number(h.precio) || 0,
            fecha_registro: h.fecha_registro,
            id_cliente: idC,
            // CORRECCIÓN DE CAMPOS SEGÚN TU ESTRUCTURA
            nombre_mascota: c?.nombre_mascota || "Desconocido",
            nombre_dueno: c?.nombre || c?.nombre_dueno || "Sin nombre",
            telefono: c?.telefono || "",
            especie: c?.especie || "",
            raza: c?.raza || "",
            sexo: c?.sexo || "",
            color: c?.color || "",
            direccion: c?.direccion || "",
            ci: c?.dni || c?.ci || "",
            correo: c?.correo || "",
            fechanac: c?.fechanac || "",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        });

        count++;
        if (count % 200 === 0) {
            await batch.commit();
            console.log(`✅ ${count} reparados...`);
            batch = db.batch();
        }
    }

    if (count % 200 !== 0) await batch.commit();
    console.log(`\n🏁 REPARACIÓN TERMINADA. Se actualizaron ${count} registros.`);
}

repararRegistros().catch(console.error);