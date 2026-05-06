const mysql = require("mysql2/promise");
const fs = require("fs");

async function exportHistorial() {
  const conn = await mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "veterinaria_sistemasenoferta",
  });

  const [rows] = await conn.execute(`
    SELECT * FROM historial
  `);

  const data = rows.map(r => ({
    id: String(r.id_historial),
    data: {
      id_historial: r.id_historial,
      descripcion: r.descripcion || "",
      diagnostico: r.diagnostico || "",
      tratamiento: r.tratamiento || "",
      tipo_servicio: r.tipo_historial || "",
      precioh: r.precioh || 0,
      archivoh: r.archivoh || "",

      id_cliente: r.id_cliente,

      fecha_registro: safeDate(r.fecha_registro),
    }
  }));

  fs.writeFileSync("historial_firestore.json", JSON.stringify(data, null, 2));

  console.log("✔ Exportado:", data.length);

}

  function safeDate(value) {
  if (!value) return null;

  const d = new Date(value);

  if (isNaN(d.getTime())) return null;

  return d.toISOString();
}

exportHistorial();