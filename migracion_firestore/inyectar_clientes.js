const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Función para corregir caracteres especiales antes de subir
function corregir(txt) {
    if (!txt) return "";
    try {
        return Buffer.from(txt, 'latin1').toString('utf8');
    } catch (e) { return txt; }
}

const clientesNuevos = [
    ["5862","Pilar Fernandez","79562461","9174780","Pretta","2026-02-10","Mestizo","","Negro","Canina","Hembra","Irpavi Calle 1, edf. mendizabal dep. 1A "],
    ["5863","Jaret Viscarra ","70695524","8467876","Bill","2026-01-23","Mestizo","","Negro","Felino","Macho","Vergel c/4 Irpavi Edif Vengala Deoto 306"],
    ["5864","Grace Romero","70659453","3428701","Milo","2026-10-20","Mestizo","","Naranja","Felino","Macho","Bolognia calle 1 # 158"],
    ["5865","Raul Mejia / Tellez ","79664241","4922463","Bella (Bela)","2018-02-10","Cooker","","cafe","Canina","Hembra","Irpavi Caballero # 7026"],
    ["5866","Martinez","78112228","4826143","Filipo","2016-03-10","Mestizo","","Blanco ","Canina","Macho","Irpavi 2 Calle 2 # 500"],
    ["5867","Pamela Cusiquinanqui","77792871","8466817","Howl (Jow)","0206-01-20","Mestizo","","gris","Felino","Macho","Av. Los Sargentos"],
    ["5868","Lisset Gandarillas","67598694","2898812","kIithy (Kiti)","2024-02-15","Mestizo","","Blanco y negro","Felina","Hembra","Irpavi calle 1 Edf. Heroes"],
    ["5869","Brenda Alvarado","70131412","6962667","Toby","2026-02-15","Husky Siberiano","","cafe","Canina","Macho","Irpavi calle Av. Gobles #6576"],
    ["5870"," Valeria MuÃ±oz Barbery","78288806","6156835","Pili","2020-03-15","Mestizo","","Blanco y negro","Felino","Hembra","Lomas de Alto Irpavi c/4 #183B"],
    ["5871","Valeria MuÃ±oz Barbery","78288806","6156835","Mili","2020-02-15","Mestizo","","Blanco y negro","Felino","Hembra","Lomas de Alto Irpavi c/4 #183B"],
    ["5872","Ines Fabian Mayta","68049313","4884426","Charlotte","2025-11-15","Mestizo","","Negro","Canina","Hembra","Irpavi calle 6 Av Vera NÂª 6581"],
    ["5873","Karen Vonvogler","73015950","2395050","MuÃ±eca","2018-02-15","Samoyedo","","Blanco ","Canina","Hembra","Av, Heroinas 16 de Julio #1141"],
    ["5874","Jorge Roman","68214369","3352072","Gerges","2024-01-03","Pastor Belga","","Negro","Canina","Macho","Av. Gobles no 6888"],
    ["5875","Valeria MuÃ±oz Barbery","78288806","6156835","Lili Put","2016-05-12","Mestiza","esterilizada","Plomo y Blanco","Felina","Hembra","Lomas de Alto Irpavi c/4 #183B"],
    ["5876","Noelia Canaza Dorado","73773366","8340696","Perla","2015-08-06","Mestizo","23617V","Blanco ","Canina","Hembra","Alto Obrajes Sector B Calle Guido Villagomez NÂª1131"],
    ["5877","Noelia Canaza Dorado","73773366","8340696","Pushi","2018-05-12","Mestiza","Esterilizada","naranja/ blanco","Felino","Hembra","Alto Obrajes Sector B Calle Guido Villagomez NÂª1131"],
    ["5878","Solange Ramos","76560207","3348527","Burbujita (Burbuja)","2026-01-05","Mestizo","","Tricolor","Felina","Hembra","Irpavi calle 3 # 6868"],
    ["5879","Victor Luis Quispe ","73210036","5992477","Migo","2022-08-08","Mestizo","","Balnco y Negro","Felino","Macho","Bolognia calle 12 NÂª400"]
];

async function subirClientes() {
    console.log("🚀 Iniciando carga de clientes faltantes...");
    const batch = db.batch();

    clientesNuevos.forEach(c => {
        // Mapeo exacto a tu estructura de Firestore
        const data = {
            id_cliente: c[0],
            nombre: corregir(c[1]),
            telefono: c[2],
            dni: c[3], // Lo mapeamos como 'dni' según tu estructura
            nombre_mascota: corregir(c[4]),
            fechanac: c[5],
            raza: corregir(c[6]),
            color: corregir(c[8]),
            especie: corregir(c[9]),
            sexo: corregir(c[10]),
            direccion: corregir(c[11]),
            correo: ""
        };

        const ref = db.collection("clientes").doc(); // Genera ID automático o podrías usar .doc(c[0])
        batch.set(ref, data);
    });

    await batch.commit();
    console.log("✅ Clientes inyectados con éxito.");
}

subirClientes().catch(console.error);