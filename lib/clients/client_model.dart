class Cliente {
  String idCliente;
  String nombre;
  String telefono;
  String nombreMascota;
  String dni;
  String fechanac;
  String raza;
  String correo;
  String color;
  String especie;
  String sexo;
  String direccion;

  Cliente({
    required this.idCliente,
    required this.nombre,
    required this.telefono,
    required this.nombreMascota,
    required this.dni,
    required this.fechanac,
    required this.raza,
    required this.correo,
    required this.color,
    required this.especie,
    required this.sexo,
    required this.direccion,
  });

  factory Cliente.fromMap(Map<String, dynamic> map, String id) {
    return Cliente(
      idCliente: id,
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      nombreMascota: map['nombre_mascota'] ?? '',
      dni: map['dni'] ?? '',
      fechanac: map['fechanac'] ?? '',
      raza: map['raza'] ?? '',
      correo: map['correo'] ?? '',
      color: map['color'] ?? '',
      especie: map['especie'] ?? '',
      sexo: map['sexo'] ?? '',
      direccion: map['direccion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "nombre": nombre,
      "telefono": telefono,
      "nombre_mascota": nombreMascota,
      "dni": dni,
      "fechanac": fechanac,
      "raza": raza,
      "correo": correo,
      "color": color,
      "especie": especie,
      "sexo": sexo,
      "direccion": direccion,
    };
  }
}