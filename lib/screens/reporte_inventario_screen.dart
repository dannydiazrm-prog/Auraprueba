import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
import 'producto_form.dart';

class ReporteInventarioScreen extends StatefulWidget {
  const ReporteInventarioScreen({super.key});

  @override
  State<ReporteInventarioScreen> createState() =>
      _ReporteInventarioScreenState();
}

class _ReporteInventarioScreenState extends State<ReporteInventarioScreen> {
  final DatabaseService _service = DatabaseService.instance;
  final _buscarCtrl = TextEditingController();
  String _filtro = '';
  String _filtroStock = 'Todos';

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<bool> _productoTieneVentas(String productoId) async {
    final ventas = await DatabaseService.instance.getVentas().first;
    for (final v in ventas.where((v) => v['estado'] == 'pagado')) {
      final items = v['items'] as List<dynamic>;
      if (items.any((i) => i['productoId'] == productoId)) return true;
    }
    return false;
  }

  Future<bool> _productoSinMovimiento(String productoId) async {
    final hace7dias = DateTime.now().subtract(const Duration(days: 7));
    final ventas = await DatabaseService.instance.getVentas().first;
    for (final v in ventas.where((v) => v['estado'] == 'pagado')) {
      final fecha = DateTime.parse(v['fecha']);
      if (fecha.isAfter(hace7dias)) {
        final items = v['items'] as List<dynamic>;
        if (items.any((i) => i['productoId'] == productoId)) return false;
      }
    }
    return true;
  }
  
  void _mostrarOpciones(Producto producto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory, color: Color(0xFF1E88E5)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A2744),
                      ),
                    ),
                    Text(
                      'Código: ${producto.codigo}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text('Editar producto'),
              onTap: () async {
                Navigator.pop(context);
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      ProductoForm(productoExistente: producto),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              title: const Text('Eliminar producto'),
              onTap: () async {
                Navigator.pop(context);
                final tieneVentas =
                    await _productoTieneVentas(producto.id);
                if (tieneVentas) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('No se puede eliminar'),
                        ],
                      ),
                      content: Text(
                        '${producto.nombre} tiene ventas asociadas. Para eliminarlo primero debes anular todas sus facturas en Historial de Ventas.',
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PersonalizacionService.instance.colorPrimario,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Entendido',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar producto'),
                      ],
                    ),
                    content: Text(
                        '¿Eliminar ${producto.nombre}? Esta acción no se puede deshacer.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style:
                            ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await _service.eliminarProducto(producto.id);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Producto eliminado'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: const Text('Eliminar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _generarPDF(List<Producto> productos, double valorTotal) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${PersonalizacionService.instance.nombreComercio} - Gestión e Inventario',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Reporte de Inventario',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.Text(
                'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Resumen
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total productos: ${productos.length}'),
              pw.Text(
                'Valor total inventario: Gs. ${formatGs(valorTotal)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Tabla
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              // Header tabla
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Código',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Nombre',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Stock',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('P. Compra',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('P. Venta',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10)),
                  ),
                ],
              ),
              // Filas productos
              ...productos.asMap().entries.map((entry) {
                final idx = entry.key;
                final p = entry.value;
                final color =
                    idx % 2 == 0 ? PdfColors.white : PdfColors.grey100;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: color),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(p.codigo,
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(p.nombre,
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                          p.esServicio ? '∞' : '${p.stock}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                          p.esServicio
                              ? '-'
                              : 'Gs. ${formatGs(p.precioCompra)}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                          'Gs. ${formatGs(p.precio)}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Producto>>(
      stream: _service.getProductos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = snapshot.data ?? [];

        // Filtrar por búsqueda
        var productos = todos.where((p) =>
            _filtro.isEmpty ||
            p.nombre.toLowerCase().contains(_filtro) ||
            p.codigo.toLowerCase().contains(_filtro)).toList();

        /// Filtrar por stock
        if (_filtroStock == 'Con stock') {
          productos = productos.where((p) => p.esServicio || p.stock > 0).toList();
        } else if (_filtroStock == 'Sin stock') {
          productos = productos.where((p) => !p.esServicio && p.stock == 0).toList();
        }

        // Limitar a 10 si no hay filtro activo
        if (_filtro.isEmpty) {
          productos = productos.take(10).toList();
        }

        // Valor total inventario
        final valorTotal = todos
            .where((p) => !p.esServicio)
            .fold(0.0, (sum, p) => sum + (p.stock * p.precioCompra));

                // Productos sin movimiento
        final sinMovimiento = todos.where((p) => !p.esServicio).length;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  pageHeader(
                    'REPORTE DE INVENTARIO',
                    context,
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2744),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _generarPDF(
                        productos.where((p) => !p.esServicio).toList(), 
                        valorTotal
                      ),
                     icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: const SizedBox.shrink(),
                    ),
                  ),



              // Tarjetas resumen
              Row(
                children: [
                  _tarjeta(
                    titulo: 'Valor Total Inventario',
                    valor: 'Gs. ${formatGs(valorTotal)}',
                    icono: Icons.attach_money,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _tarjeta(
                    titulo: 'Total Productos',
                    valor: '${todos.length}',
                    icono: Icons.inventory_2,
                    color: const Color(0xFF1E88E5),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sin movimiento warning
              FutureBuilder<List<bool>>(
                future: Future.wait(
                  todos.where((p) => !p.esServicio)
                      .map((p) => _productoSinMovimiento(p.id)),
                ),
                builder: (context, snapMovimiento) {
                  final sinMov = snapMovimiento.data
                          ?.where((b) => b)
                          .length ??
                      0;
                  if (sinMov == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '$sinMov producto(s) sin ventas hace 7 días',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
			  
			                // Filtros
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _buscarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nombre o código',
                        prefixIcon:
                            Icon(Icons.search, color: Color(0xFF1E88E5)),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) =>
                          setState(() => _filtro = v.toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Todos', 'Con stock', 'Sin stock']
                          .map((tipo) {
                        final seleccionado = _filtroStock == tipo;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _filtroStock = tipo),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: seleccionado
                                    ? const Color(0xFF1E88E5)
                                    : const Color(0xFFF4F6FA),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: seleccionado
                                      ? const Color(0xFF1E88E5)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                tipo,
                                style: TextStyle(
                                  color: seleccionado
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista productos
              if (productos.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No se encontraron productos',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: productos.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final p = productos[index];
                      final alertaStock =
                          !p.esServicio && p.stock <= p.stockMinimo;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: p.esServicio
                                ? Colors.purple.withOpacity(0.1)
                                : const Color(0xFF1E88E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            p.esServicio ? Icons.build : Icons.inventory_2,
                            color: p.esServicio
                                ? Colors.purple
                                : const Color(0xFF1E88E5),
                            size: 22,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (alertaStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Stock bajo',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Código: ${p.codigo} | ${p.esServicio ? "Servicio" : "Stock: ${p.stock} | Mín: ${p.stockMinimo}"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Gs. ${formatGs(p.precio)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E88E5),
                              ),
                            ),
                            if (!p.esServicio)
                              Text(
                                'Compra: Gs. ${formatGs(p.precioCompra)}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                          ],
                        ),
                        // onTap removido
                      ); // Cierra ListTile
                    }, // Cierra itemBuilder
                  ), // Cierra ListView.separated
                ), // Cierra Container
            ], // Cierra children: [
          ), // Cierra Column
        ), // Cierra SingleChildScrollView
      ), // Cierra SafeArea
    ); // Cierra Scaffold
  }, // Cierra builder: (context, snapshot) {
); // Cierra StreamBuilder(
} // Cierra el método Widget build

  Widget _tarjeta({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
