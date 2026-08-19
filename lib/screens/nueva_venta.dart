import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../models/venta.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';
import 'cliente_form.dart';
import '../services/ticket_service.dart';
import '../services/ajustes_service.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final FirestoreService _service = FirestoreService();
  final DatabaseService _db = DatabaseService.instance;
  final _rucCiController = TextEditingController();
  final _buscarProductoController = TextEditingController();
  final _montoPagadoController = TextEditingController();

  Cliente _clienteSeleccionado = Cliente.mostrador();
  List<ItemVenta> _items = [];
  List<Producto> _productosFiltrados = [];
  bool _buscandoCliente = false;
  bool _buscandoProducto = false;

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);
  double get _iva10 => _subtotal / 11;
  double get _total => _subtotal;
  double get _vuelto {
    final pagado = double.tryParse(_montoPagadoController.text.replaceAll(".", "")) ?? 0;
    return pagado - _total;
  }

  void _buscarCliente() async {
    if (_rucCiController.text.isEmpty) return;
    setState(() => _buscandoCliente = true);
    final query = _rucCiController.text.trim();
    final esNumero = RegExp(r'^[0-9.\-]+$').hasMatch(query);
    final cliente = await _db.buscarClientePorRucCi(query);
    setState(() => _buscandoCliente = false);
    if (cliente != null) {
      setState(() => _clienteSeleccionado = cliente);
    } else if (esNumero) {
      _mostrarFormCliente();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró ningún cliente con ese nombre'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _mostrarFormCliente() async {
    final cliente = await showModalBottomSheet<Cliente>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClienteForm(
        rucCiInicial: _rucCiController.text,
      ),
    );
    if (cliente != null) {
      setState(() => _clienteSeleccionado = cliente);
    }
  }

  void _buscarProducto(String query) async {
    if (query.isEmpty) {
      setState(() => _productosFiltrados = []);
      return;
    }
    setState(() => _buscandoProducto = true);
    final productos = await _db.buscarProducto(query);
    setState(() {
      _productosFiltrados = productos;
      _buscandoProducto = false;
    });
  }

  static const String _codigoServicioLibre = '100';

  void _agregarProducto(Producto producto) {
    if (producto.codigo == _codigoServicioLibre) {
      _mostrarMontoLibre(producto);
      return;
    }
    setState(() {
      final index = _items.indexWhere((i) => i.productoId == producto.id);
      if (index >= 0) {
        final item = _items[index];
        if (!producto.esServicio && item.cantidad >= producto.stock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stock insuficiente. Disponible: ${producto.stock}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _items[index] = ItemVenta(
          productoId: item.productoId,
          codigo: item.codigo,
          nombre: item.nombre,
          cantidad: item.cantidad + 1,
          precioUnitario: item.precioUnitario,
          stockDisponible: producto.stock,
        );
      } else {
        if (!producto.esServicio && producto.stock <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este producto no tiene stock disponible'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        _items.add(ItemVenta(
          productoId: producto.id,
          codigo: producto.codigo,
          nombre: producto.nombre,
          cantidad: 1,
          precioUnitario: producto.precio,
          stockDisponible: producto.stock,
        ));
      }
      _productosFiltrados = [];
      _buscarProductoController.clear();
    });
  }
void _mostrarMontoLibre(Producto producto) {
    final montoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servicios Prestados'),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [MilesFormatter()],
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Monto (Gs.)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money, color: Color(0xFF1E88E5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PersonalizacionService.instance.colorPrimario),
            onPressed: () {
              final monto = double.tryParse(montoCtrl.text.replaceAll('.', '')) ?? 0;
              if (monto <= 0) return;
              Navigator.pop(context);
              setState(() {
                _items.add(ItemVenta(
                  productoId: producto.id,
                  codigo: producto.codigo,
                  nombre: producto.nombre,
                  cantidad: 1,
                  precioUnitario: monto,
                  stockDisponible: 0,
                ));
                _productosFiltrados = [];
                _buscarProductoController.clear();
              });
            },
            child: const Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _actualizarCantidad(int index, int cantidad) {
    final item = _items[index];
    if (cantidad > item.stockDisponible && item.stockDisponible > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock insuficiente. Disponible: ${item.stockDisponible}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      if (cantidad <= 0) {
        _items.removeAt(index);
      } else {
        _items[index] = ItemVenta(
          productoId: item.productoId,
          codigo: item.codigo,
          nombre: item.nombre,
          cantidad: cantidad,
          precioUnitario: item.precioUnitario,
          stockDisponible: item.stockDisponible,
        );
      }
    });
  }

    void _finalizarVenta() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    // 1. Guardamos el estado del teclado antes de limpiar
    FocusScope.of(context).unfocus();

    final venta = Venta(
      clienteId: _clienteSeleccionado.id,
      clienteNombre: _clienteSeleccionado.nombre,
      clienteRucCi: _clienteSeleccionado.rucCi,
      items: _items,
      subtotal: _subtotal,
      iva10: _iva10,
      total: _total,
      fecha: DateTime.now(),
      // Si está vacío, asume que pagó el total exacto:
      montoPagado: double.tryParse(_montoPagadoController.text.replaceAll(".", "")) ?? _total,
      vuelto: _vuelto > 0 ? _vuelto : 0,
    );

    try {
      // 2. Operaciones de Base de Datos
      final gastosAutomaticos = await _db.guardarVenta(venta);
      for (final gasto in gastosAutomaticos) {
        await _db.agregarGasto({
          'fecha': DateTime.now().toIso8601String(),
          'categoria': 'Costo de Venta',
          'descripcion': '${gasto['nombre']} x${gasto['cantidad']}',
          'monto': gasto['costoTotal'],
          'automatico': true,
        });
      }

      // 3. Cargamos los ajustes ANTES de borrar los datos de la pantalla
      final ajustes = await AjustesService.getAjustes();

      // 4. Verificación de seguridad (Crucial para que no falle el showDialog)
      if (!mounted) return;

      final ventaMap = venta.toMap();
      ventaMap['clienteNombre'] = _clienteSeleccionado.nombre;
      ventaMap['clienteRucCi'] = _clienteSeleccionado.rucCi;

      // 5. Mostramos el diálogo de éxito PRIMERO
      showDialog(
        context: context,
        barrierDismissible: false, // Evita que se cierre tocando afuera sin querer
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Venta guardada'),
            ],
          ),
          content: const Text('¿Desea imprimir el comprobante?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ahora no'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2744),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await TicketService.imprimirA4(
                  venta: ventaMap,
                  ajustes: ajustes,
                );
              },
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text('A4', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PersonalizacionService.instance.colorPrimario,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await TicketService.imprimirTicket(
                  venta: ventaMap,
                  ajustes: ajustes,
                );
              },
              icon: const Icon(Icons.receipt, color: Colors.white),
              label: const Text('Ticket', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      // 6. Finalmente, reseteamos la pantalla para la siguiente venta
      setState(() {
        _items = [];
        _clienteSeleccionado = Cliente.mostrador();
        _rucCiController.clear();
        _montoPagadoController.clear();
      });

    } catch (e) {
      // Por si algo falla en la BD, que te avise en lugar de quedarse mudo
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar la venta.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final esMostrador = _clienteSeleccionado.rucCi == '1';

    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //          // Header
          pageHeader('NUEVA VENTA', context),

          const SizedBox(height: 24),

          // Cliente
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CLIENTE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2744),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _mostrarFormCliente,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Nuevo cliente'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _rucCiController,
                        keyboardType: TextInputType.text,
                        inputFormatters: [],
                        decoration: const InputDecoration(
                          labelText: 'Numero o Nombre del cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (_) => _buscarCliente(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PersonalizacionService.instance.colorPrimario,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: _buscarCliente,
                      child: _buscandoCliente
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Buscar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: esMostrador
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: esMostrador ? Colors.orange : Colors.green,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        esMostrador ? Icons.storefront : Icons.check_circle,
                        color: esMostrador ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _clienteSeleccionado.nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'RUC/CI: ${_clienteSeleccionado.rucCi}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            if (!esMostrador && _clienteSeleccionado.email.isNotEmpty)
                              Text(
                                _clienteSeleccionado.email,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (!esMostrador)
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => setState(() {
                            _clienteSeleccionado = Cliente.mostrador();
                            _rucCiController.clear();
                          }),
                          tooltip: 'Quitar cliente',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Productos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRODUCTOS / SERVICIOS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _buscarProductoController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o código',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _buscarProducto,
                ),
                if (_buscandoProducto)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                if (_productosFiltrados.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _productosFiltrados.length,
                      itemBuilder: (context, index) {
                        final p = _productosFiltrados[index];
                        return ListTile(
                          leading: Icon(
                            p.esServicio ? Icons.build : Icons.inventory,
                            color: const Color(0xFF1E88E5),
                          ),
                          title: Text(p.nombre),
                          subtitle: Text(
                            'Código: ${p.codigo} | ${p.esServicio ? "Servicio" : "Stock: ${p.stock}"}',
                          ),
                          trailing: Text(
                            'Gs. ${formatGs(p.precio)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E88E5),
                            ),
                          ),
                          onTap: () => _agregarProducto(p),
                        );
                      },
                    ),
                  ),
                if (_items.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Items agregados:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Gs. ${formatGs(item.precioUnitario)} c/u',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _actualizarCantidad(index, item.cantidad - 1),
                            ),
                            Text(
                              '${item.cantidad}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => _actualizarCantidad(index, item.cantidad + 1),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'Gs. ${formatGs(item.subtotal)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
		  
		         // Totales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: AjustesService.getAjustes(),
                  builder: (context, snap) {
                    final tieneFactura = snap.hasData &&
                        AjustesService.tieneTimbrado(snap.data!);
                    if (!tieneFactura) return const SizedBox.shrink();
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('Gs. ${formatGs(_subtotal)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('IVA 10%:'),
                            Text('Gs. ${formatGs(_iva10)}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'Gs. ${formatGs(_total)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _montoPagadoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MilesFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Monto pagado por el cliente (Gs.)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_montoPagadoController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _vuelto >= 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _vuelto >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _vuelto >= 0 ? 'VUELTO:' : 'FALTA:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _vuelto >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          'Gs. ${formatGs(_vuelto.abs())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _vuelto >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PersonalizacionService.instance.colorPrimario,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _finalizarVenta,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'GUARDAR VENTA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
