class ItemVenta {
  String productoId;
  String codigo;
  String nombre;
  int cantidad;
  double precioUnitario;
  double subtotal;
  int stockDisponible;

  ItemVenta({
    required this.productoId,
    required this.codigo,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    this.stockDisponible = 0,
  }) : subtotal = cantidad * precioUnitario;

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'codigo': codigo,
      'nombre': nombre,
      'cantidad': cantidad,
      'precioUnitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}

class Venta {
  String id;
  String clienteId;
  String clienteNombre;
  String clienteRucCi;
  List<ItemVenta> items;
  double subtotal;
  double iva10;
  double total;
  String condicion;
  DateTime fecha;
  String estado;
  double montoPagado;
  double vuelto;

  Venta({
    this.id = '',
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteRucCi,
    required this.items,
    required this.subtotal,
    required this.iva10,
    required this.total,
    this.condicion = 'contado',
    required this.fecha,
    this.estado = 'pagado',
    this.montoPagado = 0,
    this.vuelto = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'clienteRucCi': clienteRucCi,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'iva10': iva10,
      'total': total,
      'condicion': condicion,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'montoPagado': montoPagado,
      'vuelto': vuelto,
    };
  }
}
