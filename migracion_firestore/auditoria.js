const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function diagnosticar() {
    console.log("🔍 Iniciando auditoría de historial_v2...");
    const snapshot = await db.collection("historial_v2").get();
    
    let total = 0;
    let conProblemas = [];
    let problemas = {
        nombre_dueno_invalido: 0,
        nombre_mascota_invalido: 0,
        id_cliente_vacio: 0,
        campos_faltantes: 0
    };

    snapshot.forEach(doc => {
        total++;
        const data = doc.data();
        let tieneError = false;

        // Verificar Dueño
        if (!data.nombre_dueno || data.nombre_dueno === "Desconocido" || data.nombre_dueno.trim() === "") {
            problemas.nombre_dueno_invalido++;
            tieneError = true;
        }

        // Verificar Mascota
        if (!data.nombre_mascota || data.nombre_mascota === "Sin nombre" || data.nombre_mascota.trim() === "") {
            problemas.nombre_mascota_invalido++;
            tieneError = true;
        }

        // Verificar ID Cliente
        if (!data.id_cliente || data.id_cliente === "0" || data.id_cliente === "") {
            problemas.id_cliente_vacio++;
            tieneError = true;
        }

        if (tieneError) {
            conProblemas.push({
                id_doc: doc.id,
                id_cliente: data.id_cliente,
                dueno: data.nombre_dueno
            });
        }
    });

    console.log("\n📊 --- REPORTE DE SALUD ---");
    console.log(`Total de registros analizados: ${total}`);
    console.log(`Registros con nombre de dueño inválido: ${problemas.nombre_dueno_invalido}`);
    console.log(`Registros con nombre de mascota inválido: ${problemas.nombre_mascota_invalido}`);
    console.log(`Registros con ID de cliente sospechoso (0 o vacío): ${problemas.id_cliente_vacio}`);
    console.log(`---------------------------`);
    console.log(`Total de documentos que necesitan atención: ${conProblemas.length}`);
}

diagnosticar().catch(console.error);