const fs = require("fs");

const raw = JSON.parse(fs.readFileSync("historial.json"));

const table = raw.find(e => e.type === "table");
const data = table.data;

const result = { historial: {} };

data.forEach((h, index) => {
  result.historial[index] = {
    id_historial: String(h.id_historial || ""),
    descripcion: h.descripcion === "." ? "" : (h.descripcion || ""),
    fecha_registro: h.fecha_registro || "",
    tipo_servicio: h.tipo_historial || "General",
    id_cliente: String(h.id_cliente || ""),
    id_sesion: String(h.id_sesion || ""),
    precioh: Number(h.precioh) || 0
  };
});

fs.writeFileSync("historial_firestore.json", JSON.stringify(result, null, 2));

console.log("✅ JSON listo para importar");