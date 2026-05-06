const admin = require("firebase-admin");
const fs = require("fs");

admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccount.json"))
});

const START_INDEX = 4000; // ajusta según donde se quedó
const db = admin.firestore();

function toTimestamp(dateStr) {
  if (!dateStr || dateStr === "0000-00-00") {
    return admin.firestore.Timestamp.now();
  }
  return admin.firestore.Timestamp.fromDate(new Date(dateStr));
}

async function subir(nombre) {
  console.log(`\n🚀 Subiendo ${nombre}`);

  const data = JSON.parse(fs.readFileSync(nombre, "utf8"));

  let count = 0;

  for (const h of data) {
    const registro = {
      id_historial: String(h.id_historial || ""),
      descripcion: h.descripcion === "." ? "" : (h.descripcion || ""),
      fecha_registro: toTimestamp(h.fecha_registro),
      tipo_servicio: h.tipo_historial || "General",
      id_cliente: String(h.id_cliente || ""),
      id_sesion: String(h.id_sesion || ""),
      precioh: Number(h.precioh) || 0,
    };

    await db.collection("historial")
      .doc(registro.id_historial)
      .set(registro);

    count++;

    if (count % 200 === 0) {
      console.log(`✔ Subidos: ${count}`);
    }
  }

  console.log(`✅ COMPLETADO: ${nombre}`);
}

// 🔁 CAMBIA AQUÍ EL ARCHIVO
subir("historial_1.json");