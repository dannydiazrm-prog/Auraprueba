import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../models/venta.dart';
import '../models/pedido.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;

  // ---------------- STREAMS ----------------
  final StreamController<List<Producto>> _productosController =
      StreamController<List<Producto>>.broadcast();
  final StreamController<List<Cliente>> _clientesController =
      StreamController<List<Cliente>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _ventasController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _gastosController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _capitalController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Pedido>> _pedidosController =
      StreamController<List<Pedido>>.broadcast();

  // ---------------- MEMORIA (solo Web) ----------------
  final List<Producto> _productosMemoria = [];
  int _contadorProductoMemoria = 1;

  final List<Cliente> _clientesMemoria = [];
  int _contadorClienteMemoria = 1;

  final List<Map<String, dynamic>> _ventasMemoria = [];
  int _contadorVentaMemoria = 1;

  final List<Map<String, dynamic>> _gastosMemoria = [];
  int _contadorGastoMemoria = 1;

  final List<Map<String, dynamic>> _capitalMemoria = [];
  int _contadorCapitalMemoria = 1;

  final List<Pedido> _pedidosMemoria = [];
  int _contadorPedidoMemoria = 1;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      // Solo Windows necesita este inicializador especial.
      // Android usa su motor de base de datos normal, sin tocar nada acá.
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'aura_estandar.db');

        _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2, // Subimos la versión a 2
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE productos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              codigo TEXT,
              nombre TEXT,
              precio REAL,
              precioCompra REAL,
              stock INTEGER,
              stockMinimo INTEGER,
              esServicio INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE clientes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT,
              rucCi TEXT,
              email TEXT,
              telefono TEXT,
              direccion TEXT,
              tipoContribuyente TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE ventas (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clienteId TEXT,
              clienteNombre TEXT,
              clienteRucCi TEXT,
              itemsJson TEXT,
              subtotal REAL,
              iva10 REAL,
              total REAL,
              condicion TEXT,
              fecha TEXT,
              estado TEXT,
              montoPagado REAL,
              vuelto REAL
            )
          ''');
          await db.execute('''
            CREATE TABLE gastos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fecha TEXT,
              categoria TEXT,
              descripcion TEXT,
              monto REAL,
              automatico INTEGER
            )
          ''');
          await db.execute('''
            CREATE TABLE capital (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              fecha TEXT,
              descripcion TEXT,
              monto REAL,
              tipo TEXT
            )
          ''');
          // Tabla pedidos actualizada con motivo y hora
          await db.execute('''
            CREATE TABLE pedidos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clienteNombre TEXT,
              itemsJson TEXT,
              adelanto REAL,
              fechaEntrega TEXT,
              estado TEXT,
              fechaCreacion TEXT,
              motivo TEXT,
              hora TEXT
            )
          ''');
        },
        // Esto agrega las columnas automáticamente si el usuario ya tenía la versión 1
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute("ALTER TABLE pedidos ADD COLUMN motivo TEXT;");
            await db.execute("ALTER TABLE pedidos ADD COLUMN hora TEXT;");
          }
        },
      ),
    );

    return _db!;
  }

  // =========================================================
  // PRODUCTOS
  // =========================================================

  Stream<List<Producto>> getProductos() {
    _emitirProductos();
    return _productosController.stream;
  }

  Future<void> _emitirProductos() async {
    final lista = await _listarProductos();
    if (!_productosController.isClosed) _productosController.add(lista);
  }

  Future<List<Producto>> _listarProductos() async {
    if (kIsWeb) {
      final copia = List<Producto>.from(_productosMemoria);
      copia.sort((a, b) => a.nombre.compareTo(b.nombre));
      return copia;
    }
    final db = await _getDb();
    final maps = await db.query('productos', orderBy: 'nombre');
    return maps.map((m) => _productoDesdeFila(m)).toList();
  }

  Future<Producto?> _obtenerProductoPorId(String id) async {
    final lista = await _listarProductos();
    try {
      return lista.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> agregarProducto(Producto producto) async {
    if (kIsWeb) {
      if (producto.id.isNotEmpty) {
        final index =
            _productosMemoria.indexWhere((p) => p.id == producto.id);
        if (index != -1) _productosMemoria[index] = producto;
      } else {
        _productosMemoria.add(Producto(
          id: (_contadorProductoMemoria++).toString(),
          codigo: producto.codigo,
          nombre: producto.nombre,
          precio: producto.precio,
          precioCompra: producto.precioCompra,
          stock: producto.stock,
          stockMinimo: producto.stockMinimo,
          esServicio: producto.esServicio,
        ));
      }
      await _emitirProductos();
      return;
    }

    final db = await _getDb();
    final fila = _filaDesdeProducto(producto);
    if (producto.id.isNotEmpty) {
      await db.update('productos', fila,
          where: 'id = ?', whereArgs: [producto.id]);
    } else {
      await db.insert('productos', fila);
    }
    await _emitirProductos();
  }

  Future<List<Producto>> buscarProducto(String query) async {
    final lista = await _listarProductos();
    final q = query.toLowerCase();
    return lista
        .where((p) =>
            p.nombre.toLowerCase().contains(q) ||
            p.codigo.toLowerCase().contains(q))
        .toList();
  }

  Future<void> eliminarProducto(String id) async {
    if (kIsWeb) {
      _productosMemoria.removeWhere((p) => p.id == id);
      await _emitirProductos();
      return;
    }
    final db = await _getDb();
    await db.delete('productos', where: 'id = ?', whereArgs: [id]);
    await _emitirProductos();
  }

  Future<void> actualizarStock(String id, int nuevoStock) async {
    if (kIsWeb) {
      final index = _productosMemoria.indexWhere((p) => p.id == id);
      if (index != -1) _productosMemoria[index].stock = nuevoStock;
      await _emitirProductos();
      return;
    }
    final db = await _getDb();
    await db.update('productos', {'stock': nuevoStock},
        where: 'id = ?', whereArgs: [id]);
    await _emitirProductos();
  }

  Future<void> actualizarPrecioCompra(String id, double precio) async {
    if (kIsWeb) {
      final index = _productosMemoria.indexWhere((p) => p.id == id);
      if (index != -1) _productosMemoria[index].precioCompra = precio;
      await _emitirProductos();
      return;
    }
    final db = await _getDb();
    await db.update('productos', {'precioCompra': precio},
        where: 'id = ?', whereArgs: [id]);
    await _emitirProductos();
  }

  Producto _productoDesdeFila(Map<String, dynamic> fila) {
    return Producto(
      id: fila['id'].toString(),
      codigo: fila['codigo'] ?? '',
      nombre: fila['nombre'] ?? '',
      precio: (fila['precio'] ?? 0).toDouble(),
      precioCompra: (fila['precioCompra'] ?? 0).toDouble(),
      stock: fila['stock'] ?? 0,
      stockMinimo: fila['stockMinimo'] ?? 0,
      esServicio: (fila['esServicio'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> _filaDesdeProducto(Producto p) {
    return {
      'codigo': p.codigo,
      'nombre': p.nombre,
      'precio': p.precio,
      'precioCompra': p.precioCompra,
      'stock': p.stock,
      'stockMinimo': p.stockMinimo,
      'esServicio': p.esServicio ? 1 : 0,
    };
  }

  // =========================================================
  // CLIENTES
  // =========================================================

  Stream<List<Cliente>> getClientes() {
    _emitirClientes();
    return _clientesController.stream;
  }

  Future<void> _emitirClientes() async {
    final lista = await _listarClientes();
    if (!_clientesController.isClosed) _clientesController.add(lista);
  }

  Future<List<Cliente>> _listarClientes() async {
    if (kIsWeb) {
      final copia = List<Cliente>.from(_clientesMemoria);
      copia.sort((a, b) => a.nombre.compareTo(b.nombre));
      return copia;
    }
    final db = await _getDb();
    final maps = await db.query('clientes', orderBy: 'nombre');
    return maps
        .map((m) => Cliente.fromMap(m['id'].toString(), m))
        .toList();
  }

  Future<String> agregarCliente(Cliente cliente) async {
    if (kIsWeb) {
      if (cliente.id.isNotEmpty) {
        final index = _clientesMemoria.indexWhere((c) => c.id == cliente.id);
        if (index != -1) _clientesMemoria[index] = cliente;
        await _emitirClientes();
        return cliente.id;
      }
      final nuevoId = (_contadorClienteMemoria++).toString();
      _clientesMemoria.add(Cliente(
        id: nuevoId,
        nombre: cliente.nombre,
        rucCi: cliente.rucCi,
        email: cliente.email,
        telefono: cliente.telefono,
        direccion: cliente.direccion,
        tipoContribuyente: cliente.tipoContribuyente,
      ));
      await _emitirClientes();
      return nuevoId;
    }

    final db = await _getDb();
    if (cliente.id.isNotEmpty) {
      await db.update('clientes', cliente.toMap(),
          where: 'id = ?', whereArgs: [cliente.id]);
      await _emitirClientes();
      return cliente.id;
    }
    final nuevoId = await db.insert('clientes', cliente.toMap());
    await _emitirClientes();
    return nuevoId.toString();
  }

  Future<void> eliminarCliente(String id) async {
    if (kIsWeb) {
      _clientesMemoria.removeWhere((c) => c.id == id);
      await _emitirClientes();
      return;
    }
    final db = await _getDb();
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    await _emitirClientes();
  }

  Future<Cliente?> buscarClientePorRucCi(String query) async {
    if (query == '1') return Cliente.mostrador();
    final q = query.trim();
    final lista = await _listarClientes();
    final esNumero = RegExp(r'^[0-9.\-]+$').hasMatch(q);
    try {
      if (esNumero) {
        return lista.firstWhere((c) => c.rucCi == q);
      } else {
        return lista.firstWhere(
            (c) => c.nombre.toLowerCase().startsWith(q.toLowerCase()));
      }
    } catch (_) {
      return null;
    }
  }

  Future<bool> clienteTieneVentas(String clienteId) async {
    final ventas = await _listarVentas();
    return ventas.any(
        (v) => v['clienteId'] == clienteId && v['estado'] == 'pagado');
  }

  // =========================================================
  // VENTAS
  // =========================================================

  Stream<List<Map<String, dynamic>>> getVentas() {
    _emitirVentas();
    return _ventasController.stream;
  }

  Future<void> _emitirVentas() async {
    final lista = await _listarVentas();
    if (!_ventasController.isClosed) _ventasController.add(lista);
  }

  Future<List<Map<String, dynamic>>> _listarVentas() async {
    List<Map<String, dynamic>> lista;
    if (kIsWeb) {
      lista = _ventasMemoria
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
    } else {
      final db = await _getDb();
      final filas = await db.query('ventas');
      lista = filas.map((f) {
        final map = Map<String, dynamic>.from(f);
        map['id'] = f['id'].toString();
        map['items'] = jsonDecode(f['itemsJson'] as String);
        map.remove('itemsJson');
        return map;
      }).toList();
    }
    lista.sort((a, b) =>
        DateTime.parse(b['fecha']).compareTo(DateTime.parse(a['fecha'])));
    return lista;
  }

  Future<List<Map<String, dynamic>>> guardarVenta(Venta venta) async {
    final map = venta.toMap();
    final items = map.remove('items') as List;

    if (kIsWeb) {
      final nuevoId = (_contadorVentaMemoria++).toString();
      _ventasMemoria.add({
        'id': nuevoId,
        ...map,
        'items': items,
      });
    } else {
      final db = await _getDb();
      final fila = {...map, 'itemsJson': jsonEncode(items)};
      await db.insert('ventas', fila);
    }

    final gastosAutomaticos = <Map<String, dynamic>>[];
    for (final item in venta.items) {
      final producto = await _obtenerProductoPorId(item.productoId);
      if (producto != null && !producto.esServicio) {
        await actualizarStock(item.productoId, producto.stock - item.cantidad);
        gastosAutomaticos.add({
          'nombre': item.nombre,
          'cantidad': item.cantidad,
          'costoTotal': item.cantidad * producto.precioCompra,
        });
      }
    }

    await _emitirVentas();
    return gastosAutomaticos;
  }

  Future<List<Map<String, dynamic>>> anularVenta(
      String ventaId, Map<String, dynamic> venta) async {
    if (kIsWeb) {
      final index = _ventasMemoria.indexWhere((v) => v['id'] == ventaId);
      if (index != -1) _ventasMemoria[index]['estado'] = 'anulada';
    } else {
      final db = await _getDb();
      await db.update('ventas', {'estado': 'anulada'},
          where: 'id = ?', whereArgs: [ventaId]);
    }

    final gastosParaEliminar = <Map<String, dynamic>>[];
    final items = venta['items'] as List<dynamic>;
    for (final item in items) {
      final productoId = item['productoId'];
      final cantidad = item['cantidad'] as int;
      final nombre = item['nombre'];

      final producto = await _obtenerProductoPorId(productoId);
      if (producto != null && !producto.esServicio) {
        await actualizarStock(productoId, producto.stock + cantidad);
        gastosParaEliminar.add({'nombre': nombre, 'cantidad': cantidad});
      }
    }

    await _emitirVentas();
    return gastosParaEliminar;
  }

  // =========================================================
  // GASTOS
  // =========================================================

  Stream<List<Map<String, dynamic>>> getGastos() {
    _emitirGastos();
    return _gastosController.stream;
  }

  Future<void> _emitirGastos() async {
    final lista = await _listarGastos();
    if (!_gastosController.isClosed) _gastosController.add(lista);
  }

  Future<List<Map<String, dynamic>>> _listarGastos() async {
    List<Map<String, dynamic>> lista;
    if (kIsWeb) {
      lista = _gastosMemoria.map((g) => Map<String, dynamic>.from(g)).toList();
    } else {
      final db = await _getDb();
      final filas = await db.query('gastos');
      lista = filas.map((f) {
        final map = Map<String, dynamic>.from(f);
        map['id'] = f['id'].toString();
        map['automatico'] = f['automatico'] == 1;
        return map;
      }).toList();
    }
    lista.sort((a, b) =>
        DateTime.parse(b['fecha']).compareTo(DateTime.parse(a['fecha'])));
    return lista;
  }

  Future<void> agregarGasto(Map<String, dynamic> gasto) async {
    if (kIsWeb) {
      _gastosMemoria.add({
        'id': (_contadorGastoMemoria++).toString(),
        ...gasto,
      });
      await _emitirGastos();
      return;
    }
    final db = await _getDb();
    final fila = {...gasto, 'automatico': (gasto['automatico'] == true) ? 1 : 0};
    await db.insert('gastos', fila);
    await _emitirGastos();
  }

  Future<void> eliminarGasto(String id) async {
    if (kIsWeb) {
      _gastosMemoria.removeWhere((g) => g['id'] == id);
      await _emitirGastos();
      return;
    }
    final db = await _getDb();
    await db.delete('gastos', where: 'id = ?', whereArgs: [id]);
    await _emitirGastos();
  }

  // =========================================================
  // CAPITAL
  // =========================================================

  Stream<List<Map<String, dynamic>>> getCapital() {
    _emitirCapital();
    return _capitalController.stream;
  }

  Future<void> _emitirCapital() async {
    final lista = await _listarCapital();
    if (!_capitalController.isClosed) _capitalController.add(lista);
  }

  Future<List<Map<String, dynamic>>> _listarCapital() async {
    List<Map<String, dynamic>> lista;
    if (kIsWeb) {
      lista =
          _capitalMemoria.map((c) => Map<String, dynamic>.from(c)).toList();
    } else {
      final db = await _getDb();
      final filas = await db.query('capital');
      lista = filas.map((f) {
        final map = Map<String, dynamic>.from(f);
        map['id'] = f['id'].toString();
        return map;
      }).toList();
    }
    lista.sort((a, b) =>
        DateTime.parse(b['fecha']).compareTo(DateTime.parse(a['fecha'])));
    return lista;
  }

  Future<void> agregarCapital(Map<String, dynamic> capital) async {
    if (kIsWeb) {
      _capitalMemoria.add({
        'id': (_contadorCapitalMemoria++).toString(),
        ...capital,
      });
      await _emitirCapital();
      return;
    }
    final db = await _getDb();
    await db.insert('capital', capital);
    await _emitirCapital();
  }

  Future<void> eliminarCapital(String id) async {
    if (kIsWeb) {
      _capitalMemoria.removeWhere((c) => c['id'] == id);
      await _emitirCapital();
      return;
    }
    final db = await _getDb();
    await db.delete('capital', where: 'id = ?', whereArgs: [id]);
    await _emitirCapital();
  }

  // =========================================================
  // PEDIDOS
  // =========================================================

  Stream<List<Pedido>> getPedidos() {
    _emitirPedidos();
    return _pedidosController.stream;
  }

  Future<void> _emitirPedidos() async {
    final lista = await _listarPedidos();
    if (!_pedidosController.isClosed) _pedidosController.add(lista);
  }

  Future<List<Pedido>> _listarPedidos() async {
    List<Pedido> lista;
    if (kIsWeb) {
      lista = List<Pedido>.from(_pedidosMemoria);
    } else {
      final db = await _getDb();
      final filas = await db.query('pedidos');
      lista = filas.map((f) {
        final map = Map<String, dynamic>.from(f);
        map['items'] = jsonDecode(f['itemsJson'] as String);
        return Pedido.fromMap(f['id'].toString(), map);
      }).toList();
    }
    lista.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    return lista;
  }

  Future<void> agregarPedido(Map<String, dynamic> data) async {
    if (kIsWeb) {
      final nuevoId = (_contadorPedidoMemoria++).toString();
      _pedidosMemoria.add(Pedido.fromMap(nuevoId, data));
      await _emitirPedidos();
      return;
    }
    final db = await _getDb();
    final items = data['items'];
    final fila = {...data, 'itemsJson': jsonEncode(items)};
    fila.remove('items');
    await db.insert('pedidos', fila);
    await _emitirPedidos();
  }

  Future<void> actualizarPedido(String id, Map<String, dynamic> data) async {
    if (kIsWeb) {
      final index = _pedidosMemoria.indexWhere((p) => p.id == id);
      if (index != -1) _pedidosMemoria[index] = Pedido.fromMap(id, data);
      await _emitirPedidos();
      return;
    }
    final db = await _getDb();
    final items = data['items'];
    final fila = {...data, 'itemsJson': jsonEncode(items)};
    fila.remove('items');
    await db.update('pedidos', fila, where: 'id = ?', whereArgs: [id]);
    await _emitirPedidos();
  }

    Future<void> actualizarEstadoPedido(String id, String estado) async {
    if (kIsWeb) {
      final index = _pedidosMemoria.indexWhere((p) => p.id == id);
      if (index != -1) {
        final p = _pedidosMemoria[index];
        _pedidosMemoria[index] = Pedido(
          id: p.id,
          clienteNombre: p.clienteNombre,
          items: p.items,
          adelanto: p.adelanto,
          fechaEntrega: p.fechaEntrega,
          estado: estado,
          fechaCreacion: p.fechaCreacion,
          motivo: p.motivo, // Conservamos el motivo
          hora: p.hora,     // Conservamos la hora
        );
      }
      await _emitirPedidos();
      return;
    }
    final db = await _getDb();
    await db.update('pedidos', {'estado': estado},
        where: 'id = ?', whereArgs: [id]);
    await _emitirPedidos();
  }


  Future<void> eliminarPedido(String id) async {
    if (kIsWeb) {
      _pedidosMemoria.removeWhere((p) => p.id == id);
      await _emitirPedidos();
      return;
    }
    final db = await _getDb();
    await db.delete('pedidos', where: 'id = ?', whereArgs: [id]);
    await _emitirPedidos();
  }

  Future<void> limpiarPedidosEntregadosViejos(DateTime antesDe) async {
    final todos = await _listarPedidos();
    for (final p in todos) {
      if (p.estado == 'entregado' && p.fechaCreacion.isBefore(antesDe)) {
        await eliminarPedido(p.id);
      }
    }
  }
}
