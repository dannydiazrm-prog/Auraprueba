import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../models/venta.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // CLIENTES
  Future<Cliente?> buscarClientePorRucCi(String query) async {
    if (query == '1') return Cliente.mostrador();
    final q = query.trim();
    final esNumero = RegExp(r'^[0-9.\-]+$').hasMatch(q);
    if (esNumero) {
      final snap = await _db
          .collection('clientes')
          .where('rucCi', isEqualTo: q)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return Cliente.fromMap(snap.docs.first.id, snap.docs.first.data());
    } else {
      final snap = await _db
          .collection('clientes')
          .where('nombre', isGreaterThanOrEqualTo: q)
          .where('nombre', isLessThan: q + '\uf8ff')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return Cliente.fromMap(snap.docs.first.id, snap.docs.first.data());
    }
  }

  Future<String> agregarCliente(Cliente cliente) async {
    if (cliente.id.isNotEmpty) {
      await _db.collection('clientes').doc(cliente.id).update(cliente.toMap());
      return cliente.id;
    }
    final doc = await _db.collection('clientes').add(cliente.toMap());
    return doc.id;
  }

  Stream<List<Cliente>> getClientes() {
    return _db
        .collection('clientes')
        .orderBy('nombre')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Cliente.fromMap(doc.id, doc.data()))
            .toList());
  }

  // PRODUCTOS
  Stream<List<Producto>> getProductos() {
    return _db
        .collection('productos')
        .orderBy('nombre')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Producto.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> agregarProducto(Producto producto) async {
    if (producto.id.isNotEmpty) {
      await _db
          .collection('productos')
          .doc(producto.id)
          .update(producto.toMap());
    } else {
      await _db.collection('productos').add(producto.toMap());
    }
  }

  Future<List<Producto>> buscarProducto(String query) async {
    final snap = await _db.collection('productos').get();
    return snap.docs
        .map((doc) => Producto.fromMap(doc.id, doc.data()))
        .where((p) =>
            p.nombre.toLowerCase().contains(query.toLowerCase()) ||
            p.codigo.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // VENTAS
  Future<void> guardarVenta(Venta venta) async {
    final batch = _db.batch();

    // Guardar la venta
    final ventaRef = _db.collection('ventas').doc();
    batch.set(ventaRef, venta.toMap());

    // Por cada item vendido
    for (final item in venta.items) {
      final productoDoc = await _db
          .collection('productos')
          .doc(item.productoId)
          .get();

      if (productoDoc.exists) {
        final data = productoDoc.data()!;
        final esServicio = data['esServicio'] ?? false;

        if (!esServicio) {
          // Descontar stock
          batch.update(
            _db.collection('productos').doc(item.productoId),
            {'stock': FieldValue.increment(-item.cantidad)},
          );

          // Registrar costo de venta como gasto automático
          final costoTotal =
              (data['precioCompra'] ?? 0).toDouble() * item.cantidad;
          final gastoRef = _db.collection('gastos').doc();
          batch.set(gastoRef, {
            'fecha': DateTime.now().toIso8601String(),
            'categoria': 'Costo de Venta',
            'descripcion': '${item.nombre} x${item.cantidad}',
            'monto': costoTotal,
            'automatico': true,
          });
        }
      }
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getUltimasVentas() {
    return _db
        .collection('ventas')
        .orderBy('fecha', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
  
  Future<void> anularVenta(String ventaId, Map<String, dynamic> venta) async {
    final batch = _db.batch();

    // Cambiar estado de la venta a anulada
    batch.update(
      _db.collection('ventas').doc(ventaId),
      {'estado': 'anulada'},
    );

    // Devolver stock y eliminar gastos automáticos de cada producto
    final items = venta['items'] as List<dynamic>;
    for (final item in items) {
      final productoId = item['productoId'];
      final cantidad = item['cantidad'] as int;
      final nombre = item['nombre'];

      final productoDoc = await _db
          .collection('productos')
          .doc(productoId)
          .get();

      if (productoDoc.exists) {
        final esServicio = productoDoc.data()?['esServicio'] ?? false;
        if (!esServicio) {
          // Devolver stock
          batch.update(
            _db.collection('productos').doc(productoId),
            {'stock': FieldValue.increment(cantidad)},
          );

          // Eliminar gasto automático de costo de venta
          final gastosSnap = await _db
              .collection('gastos')
              .where('automatico', isEqualTo: true)
              .where('descripcion',
                  isEqualTo: '$nombre x$cantidad')
              .where('categoria', isEqualTo: 'Costo de Venta')
              .get();

          for (final gasto in gastosSnap.docs) {
            batch.delete(gasto.reference);
          }
        }
      }
    }

    await batch.commit();
  }
  Future<bool> clienteTieneVentas(String clienteId) async {
    final snap = await _db
        .collection('ventas')
        .where('clienteId', isEqualTo: clienteId)
        .where('estado', isEqualTo: 'pagado')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> eliminarCliente(String clienteId) async {
    await _db.collection('clientes').doc(clienteId).delete();
  }
  
  // FINANZAS
  Future<void> agregarGasto(Map<String, dynamic> gasto) async {
    await _db.collection('gastos').add(gasto);
  }

  Future<void> agregarCapital(Map<String, dynamic> capital) async {
    await _db.collection('capital').add(capital);
  }

  Stream<List<Map<String, dynamic>>> getGastos() {
    return _db
        .collection('gastos')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> getCapital() {
    return _db
        .collection('capital')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> eliminarGasto(String id) async {
    await _db.collection('gastos').doc(id).delete();
  }

  Future<void> eliminarCapital(String id) async {
    await _db.collection('capital').doc(id).delete();
  }

  Future<void> registrarGastoMercaderia(
      String nombre, int cantidad, double precioCompra) async {
    await _db.collection('gastos').add({
      'fecha': DateTime.now().toIso8601String(),
      'categoria': 'Mercadería',
      'descripcion': '$nombre x$cantidad',
      'monto': cantidad * precioCompra,
      'automatico': true,
    });
  }
  
  Future<void> eliminarGastoCostoVenta(String nombre, int cantidad) async {
    final snap = await _db
        .collection('gastos')
        .where('automatico', isEqualTo: true)
        .where('descripcion', isEqualTo: '$nombre x$cantidad')
        .where('categoria', isEqualTo: 'Costo de Venta')
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
  
  // AJUSTES
  Future<Map<String, dynamic>> getAjustes() async {
    final doc = await _db.collection('ajustes').doc('configuracion').get();
    return doc.exists ? doc.data()! : {};
  }

  Future<void> guardarAjustes(Map<String, dynamic> ajustes) async {
    await _db
        .collection('ajustes')
        .doc('configuracion')
        .set(ajustes, SetOptions(merge: true));
  }
  
  // DASHBOARD
  Future<Map<String, dynamic>> getEstadisticasDashboard() async {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);

    // Ventas del mes
    final ventasMes = await _db
        .collection('ventas')
        .where('fecha', isGreaterThanOrEqualTo: inicioMes.toIso8601String())
        .where('fecha', isLessThanOrEqualTo: finMes.toIso8601String())
        .where('estado', isNotEqualTo: 'anulada')
        .get();

    double totalVentasMes = 0;
    for (final v in ventasMes.docs) {
      totalVentasMes += (v.data()['total'] ?? 0).toDouble();
    }

    // Productos (sin servicios)
    final productos = await _db
        .collection('productos')
        .where('esServicio', isEqualTo: false)
        .get();

    // Stock bajo
    int stockBajo = 0;
    for (final p in productos.docs) {
      final stock = p.data()['stock'] ?? 0;
      final minimo = p.data()['stockMinimo'] ?? 0;
      if (stock <= minimo) stockBajo++;
    }

    return {
      'ventasMes': totalVentasMes,
      'totalProductos': productos.docs.length,
      'stockBajo': stockBajo,
    };
  }
}
