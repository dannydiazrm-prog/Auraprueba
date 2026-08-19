class Cliente {
  String id;
  String nombre;
  String rucCi;
  String email;
  String telefono;
  String direccion;
  String tipoContribuyente;

  Cliente({
    this.id = '',
    required this.nombre,
    required this.rucCi,
    this.email = '',
    this.telefono = '',
    this.direccion = '',
    this.tipoContribuyente = 'Física',
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'rucCi': rucCi,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'tipoContribuyente': tipoContribuyente,
    };
  }

  factory Cliente.fromMap(String id, Map<String, dynamic> map) {
    return Cliente(
      id: id,
      nombre: map['nombre'] ?? '',
      rucCi: map['rucCi'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'] ?? '',
      tipoContribuyente: map['tipoContribuyente'] ?? 'Física',
    );
  }

  static Cliente mostrador() {
    return Cliente(
      id: 'mostrador',
      nombre: 'Cliente Mostrador',
      rucCi: '1',
    );
  }
}
