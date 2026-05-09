const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function repararConQuery() {
    console.log("🔍 Iniciando búsqueda por campo id_cliente (String)...");
    
    // 1. Obtenemos los historiales sin nombre de dueño
    const historialesSucios = await db.collection("historial_v2")
                                      .where("nombre_dueno", "==", "")
                                      .get();

    if (historialesSucios.empty) {
        console.log("✨ No hay nada que reparar.");
        return;
    }

    const batch = db.batch();
    let reparados = 0;

    for (const docHist of historialesSucios.docs) {
        const idBusqueda = docHist.data().id_cliente; // Ya es String "5879"

        // 2. BUSCAMOS EL CLIENTE: No por ID de doc, sino por campo interno
        const clienteQuery = await db.collection("clientes")
                                     .where("id_cliente", "==", idBusqueda)
                                     .limit(1)
                                     .get();

        if (!clienteQuery.empty) {
            const dataCliente = clienteQuery.docs[0].data();
            
            batch.update(docHist.ref, {
                nombre_dueno: dataCliente.nombre || "Sin nombre",
                nombre_mascota: dataCliente.nombre_mascota || "Sin nombre",
                ci: dataCliente.dni || dataCliente.ci || "",
                telefono: dataCliente.telefono || "",
                direccion: dataCliente.direccion || ""
            });
            
            reparados++;
            console.log(`✅ Reparado: ${dataCliente.nombre} (ID: ${idBusqueda})`);
        } else {
            console.log(`❌ No se encontró el cliente con id_cliente: "${idBusqueda}" en la colección 'clientes'`);
        }
    }

    if (reparados > 0) {
        await batch.commit();
        console.log(`\n🏁 ¡Éxito! Se repararon ${reparados} registros.`);
    }
}

repararConQuery().catch(console.error);