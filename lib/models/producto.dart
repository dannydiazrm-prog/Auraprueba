class Producto {
  String id;
  String codigo;
  String nombre;
  double precio;
  double precioCompra;
  int stock;
  int stockMinimo;
  bool esServicio;

  Producto({
    this.id = '',
    required this.codigo,
    required this.nombre,
    required this.precio,
    this.precioCompra = 0,
    this.stock = 0,
    this.stockMinimo = 0,
    this.esServicio = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'precio': precio,
      'precioCompra': precioCompra,
      'stock': stock,
      'stockMinimo': stockMinimo,
      'esServicio': esServicio,
    };
  }

  factory Producto.fromMap(String id, Map<String, dynamic> map) {
    return Producto(
      id: id,
      codigo: map['codigo'] ?? '',
      nombre: map['nombre'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      precioCompra: (map['precioCompra'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      stockMinimo: map['stockMinimo'] ?? 0,
      esServicio: map['esServicio'] ?? false,
    );
  }
}