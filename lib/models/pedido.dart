class ItemPedido {
  final String descripcion;
  final int cantidad;
  final double precio;

  ItemPedido({
    required this.descripcion,
    required this.cantidad,
    required this.precio,
  });

  double get subtotal => cantidad * precio;

  factory ItemPedido.fromMap(Map<String, dynamic> map) {
    return ItemPedido(
      descripcion: map['descripcion'] ?? '',
      cantidad: map['cantidad'] ?? 1,
      precio: (map['precio'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'cantidad': cantidad,
      'precio': precio,
    };
  }
}

class Pedido {
  final String id;
  final String clienteNombre;
  final List<ItemPedido> items;
  final double adelanto;
  final DateTime fechaEntrega;
  final String estado;
  final DateTime fechaCreacion;
  final String? motivo;
  final String? hora;

  Pedido({
    required this.id,
    required this.clienteNombre,
    required this.items,
    required this.adelanto,
    required this.fechaEntrega,
    required this.estado,
    required this.fechaCreacion,
    this.motivo, // Le sacamos el "required"
    this.hora,   // Le sacamos el "required"
  });

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  double get saldo => total - adelanto;

  factory Pedido.fromMap(String id, Map<String, dynamic> map) {
    return Pedido(
      id: id,
      clienteNombre: map['clienteNombre'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((i) => ItemPedido.fromMap(i as Map<String, dynamic>))
          .toList(),
      adelanto: (map['adelanto'] ?? 0).toDouble(),
      fechaEntrega: DateTime.parse(map['fechaEntrega']),
      estado: map['estado'] ?? 'pendiente',
      fechaCreacion: DateTime.parse(map['fechaCreacion'] ?? DateTime.now().toIso8601String()),
      motivo: map['motivo'], // AGREGADO AQUÍ PARA LEER
      hora: map['hora'],     // AGREGADO AQUÍ PARA LEER
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clienteNombre': clienteNombre,
      'items': items.map((i) => i.toMap()).toList(),
      'adelanto': adelanto,
      'fechaEntrega': fechaEntrega.toIso8601String(),
      'estado': estado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'motivo': motivo, // AGREGADO AQUÍ PARA GUARDAR
      'hora': hora,     // AGREGADO AQUÍ PARA GUARDAR
    };
  }
}
