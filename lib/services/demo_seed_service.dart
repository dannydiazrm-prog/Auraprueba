import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../models/venta.dart';

class DemoSeedService {
  static Future<void> sembrarSiHaceFalta() async {
    final prefs = await SharedPreferences.getInstance();
    final yaSembrado = prefs.getBool('demo_seeded') ?? false;
    if (yaSembrado) return;

    final db = DatabaseService.instance;
    final random = Random();

    // 1. Productos (temática veterinaria)
    final productosBase = <Map<String, dynamic>>[
      {'codigo': 'V001', 'nombre': 'Vacuna Antirrábica', 'precio': 80000.0, 'precioCompra': 40000.0, 'stock': 30, 'stockMinimo': 10, 'esServicio': false},
      {'codigo': 'V002', 'nombre': 'Vacuna Quíntuple', 'precio': 120000.0, 'precioCompra': 65000.0, 'stock': 25, 'stockMinimo': 8, 'esServicio': false},
      {'codigo': 'A001', 'nombre': 'Alimento Perro Adulto 15kg', 'precio': 250000.0, 'precioCompra': 170000.0, 'stock': 18, 'stockMinimo': 5, 'esServicio': false},
      {'codigo': 'A002', 'nombre': 'Alimento Gato Adulto 7kg', 'precio': 150000.0, 'precioCompra': 100000.0, 'stock': 20, 'stockMinimo': 5, 'esServicio': false},
      {'codigo': 'M001', 'nombre': 'Antipulgas y Garrapatas', 'precio': 65000.0, 'precioCompra': 35000.0, 'stock': 40, 'stockMinimo': 10, 'esServicio': false},
      {'codigo': 'M002', 'nombre': 'Desparasitante Interno', 'precio': 45000.0, 'precioCompra': 22000.0, 'stock': 35, 'stockMinimo': 10, 'esServicio': false},
      {'codigo': 'S001', 'nombre': 'Consulta Veterinaria General', 'precio': 100000.0, 'precioCompra': 0.0, 'stock': 0, 'stockMinimo': 0, 'esServicio': true},
      {'codigo': 'S002', 'nombre': 'Baño y Peluquería', 'precio': 90000.0, 'precioCompra': 0.0, 'stock': 0, 'stockMinimo': 0, 'esServicio': true},
      {'codigo': 'S003', 'nombre': 'Corte de Uñas', 'precio': 30000.0, 'precioCompra': 0.0, 'stock': 0, 'stockMinimo': 0, 'esServicio': true},
      {'codigo': 'A003', 'nombre': 'Juguete Mordedor', 'precio': 35000.0, 'precioCompra': 18000.0, 'stock': 22, 'stockMinimo': 5, 'esServicio': false},
    ];

    for (final p in productosBase) {
      await db.agregarProducto(Producto(
        codigo: p['codigo'],
        nombre: p['nombre'],
        precio: p['precio'],
        precioCompra: p['precioCompra'],
        stock: p['stock'],
        stockMinimo: p['stockMinimo'],
        esServicio: p['esServicio'],
      ));
    }

    final productosCreados = await db.buscarProducto('');

    // 2. Clientes
    final clientesBase = <Map<String, String>>[
      {'nombre': 'María González', 'rucCi': '3456789', 'telefono': '0981123456'},
      {'nombre': 'Carlos Benítez', 'rucCi': '2345678', 'telefono': '0982234567'},
      {'nombre': 'Laura Ramírez', 'rucCi': '4567891', 'telefono': '0983345678'},
      {'nombre': 'Diego Fernández', 'rucCi': '5678912', 'telefono': '0984456789'},
      {'nombre': 'Sofía Ayala', 'rucCi': '6789123', 'telefono': '0985567891'},
      {'nombre': 'Roberto Duarte', 'rucCi': '7891234', 'telefono': '0986678912'},
      {'nombre': 'Valentina Cáceres', 'rucCi': '8912345', 'telefono': '0987789123'},
      {'nombre': 'Fernando López', 'rucCi': '9123456', 'telefono': '0988891234'},
      {'nombre': 'Camila Rojas', 'rucCi': '1234567', 'telefono': '0989912345'},
      {'nombre': 'Andrés Martínez', 'rucCi': '2223334', 'telefono': '0990123456'},
    ];

    final clientesCreadosIds = <String>[];
    for (final c in clientesBase) {
      final id = await db.agregarCliente(Cliente(
        nombre: c['nombre']!,
        rucCi: c['rucCi']!,
        telefono: c['telefono']!,
      ));
      clientesCreadosIds.add(id);
    }

    // 3. Ventas del último mes (aprox 25 ventas repartidas en 30 días)
    final ahora = DateTime.now();
    for (int i = 0; i < 25; i++) {
      final diasAtras = random.nextInt(30);
      final fecha = ahora.subtract(Duration(
        days: diasAtras,
        hours: random.nextInt(10),
        minutes: random.nextInt(60),
      ));

      final clienteIndex = random.nextInt(clientesBase.length);
      final clienteId = clientesCreadosIds[clienteIndex];
      final clienteNombre = clientesBase[clienteIndex]['nombre']!;
      final clienteRucCi = clientesBase[clienteIndex]['rucCi']!;

      final cantidadItems = 1 + random.nextInt(3);
      final items = <ItemVenta>[];
      double subtotal = 0;

      for (int j = 0; j < cantidadItems; j++) {
        final producto = productosCreados[random.nextInt(productosCreados.length)];
        final cantidad = 1 + random.nextInt(2);
        final item = ItemVenta(
          productoId: producto.id,
          codigo: producto.codigo,
          nombre: producto.nombre,
          cantidad: cantidad,
          precioUnitario: producto.precio,
        );
        items.add(item);
        subtotal += item.subtotal;
      }

      final total = subtotal;
      final montoPagado = total;

      await db.guardarVenta(Venta(
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        clienteRucCi: clienteRucCi,
        items: items,
        subtotal: subtotal,
        iva10: 0,
        total: total,
        fecha: fecha,
        estado: 'pagado',
        montoPagado: montoPagado,
        vuelto: 0,
      ));
    }

    // 4. Agendamientos (5)
    final motivos = ['Control anual', 'Vacunación', 'Consulta por vómitos', 'Baño y corte', 'Chequeo post-operatorio'];
    for (int i = 0; i < 5; i++) {
      final clienteIndex = random.nextInt(clientesBase.length);
      final fechaEntrega = ahora.add(Duration(days: i + 1));
      await db.agregarPedido({
        'clienteNombre': clientesBase[clienteIndex]['nombre'],
        'items': [
          {'descripcion': motivos[i], 'cantidad': 1, 'precio': 0.0}
        ],
        'adelanto': 0.0,
        'fechaEntrega': fechaEntrega.toIso8601String(),
        'estado': 'pendiente',
        'fechaCreacion': ahora.toIso8601String(),
        'motivo': motivos[i],
        'hora': '${9 + i}:00',
      });
    }

    await prefs.setBool('demo_seeded', true);
  }
}
