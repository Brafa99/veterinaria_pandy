const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const fs = require("fs");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const historialRaw = JSON.parse(fs.readFileSync("historial_faltante.json", "utf8"));
const clientesRaw = JSON.parse(fs.readFileSync("clientes_final.json", "utf8"));

const historialData = historialRaw[2].data;
const clientesData = clientesRaw[2].data;

// Creamos un mapa más inteligente que guarde el ID de varias formas
const clientesMap = {};
clientesData.forEach(c => {
    if (c.id_cliente) {
        const idOriginal = String(c.id_cliente).trim();
        const idNumerico = String(parseInt(c.id_cliente));
        
        clientesMap[idOriginal] = c;
        clientesMap[idNumerico] = c; // Por si el historial viene sin ceros a la izquierda
    }
});

function corregirTexto(str) {
    if (!str) return "";
    try {
        // Intenta corregir codificación UTF-8/Latin1
        return Buffer.from(String(str), 'latin1').toString('utf8').trim();
    } catch (e) { return String(str).trim(); }
}

async function migrar() {
    console.log("🚀 Iniciando migración de rescate...");
    let batch = db.batch();
    let count = 0;
    let encontrados = 0;

    for (const item of historialData) {
        const idRaw = String(item.id_cliente).trim();
        const idNum = String(parseInt(item.id_cliente));
        
        // Intentamos buscar por ID exacto o por ID numérico
        const cliente = clientesMap[idRaw] || clientesMap[idNum];
        
        if (cliente) {
            encontrados++;
        } else {
            console.log(`❌ No se encontró: ID ${idRaw} (Historial ${item.id_historial})`);
        }

        const idHistorial = String(item.id_historial).trim();
        const fechaPartes = item.fecha_registro.split("-");
        const fechaObj = new Date(fechaPartes[0], fechaPartes[1] - 1, fechaPartes[2], 12, 0, 0);
        const timestampRegistro = admin.firestore.Timestamp.fromDate(fechaObj);

        const nuevoRegistro = {
            ci: cliente ? (cliente.dni || "") : "",
            color: cliente ? corregirTexto(cliente.color) : "",
            correo: cliente ? (cliente.correo || "") : "",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            descripcion: corregirTexto(item.descripcion),
            direccion: cliente ? corregirTexto(cliente.direccion) : "",
            especie: cliente ? (cliente.especie || "Canina") : "Canina",
            fecha_registro: timestampRegistro,
            fechanac: cliente ? (cliente.fechanac || "") : "",
            id_cliente: idRaw, // Mantenemos el ID original
            nombre_dueno: cliente ? corregirTexto(cliente.nombre) : "Desconocido",
            nombre_mascota: cliente ? corregirTexto(cliente.nombre_mascota) : "Sin nombre",
            precioh: parseInt(item.precioh) || 0,
            raza: cliente ? corregirTexto(cliente.raza) : "",
            sexo: cliente ? (cliente.sexo || "") : "",
            telefono: cliente ? (cliente.telefono || "") : "",
            tipo_historial: item.tipo_historial || "Consulta Medica"
        };

        batch.set(db.collection("historial_v2").doc(idHistorial), nuevoRegistro);
        count++;

        if (count % 400 === 0) {
            await batch.commit();
            batch = db.batch();
            console.log(`✅ ${count} procesados...`);
        }
    }

    await batch.commit();
    console.log(`\n🏁 Resultado: ${encontrados} de ${count} vinculados.`);
}

migrar().catch(console.error);