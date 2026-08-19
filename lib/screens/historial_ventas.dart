import '../widgets/responsive.dart';
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';
import '../services/ticket_service.dart';
import '../services/ajustes_service.dart';
import '../widgets/page_header.dart';

class HistorialVentasScreen extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  State<HistorialVentasScreen> createState() => _HistorialVentasScreenState();
}

class _HistorialVentasScreenState extends State<HistorialVentasScreen> {
  final FirestoreService _service = FirestoreService();
  final DatabaseService _db = DatabaseService.instance;
  final _buscarCtrl = TextEditingController();
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String _filtroCliente = '';

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (fecha != null) {
      setState(() {
        if (esDesde) {
          _fechaDesde = fecha;
        } else {
          _fechaHasta = fecha;
        }
      });
    }
  }

  void _verDetalle(Map<String, dynamic> venta, String ventaId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetalleVenta(
        venta: venta,
        ventaId: ventaId,
        db: _db,
        gastosService: _service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader('HISTORIAL DE VENTAS', context),

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
                    labelText: 'Buscar por cliente o RUC/CI',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF1E88E5)),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _filtroCliente = v.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _seleccionarFecha(true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF1E88E5)),
                              const SizedBox(width: 8),
                              Text(
                                _fechaDesde != null
                                    ? '${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'
                                    : 'Desde',
                                style: TextStyle(
                                  color: _fechaDesde != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _seleccionarFecha(false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF1E88E5)),
                              const SizedBox(width: 8),
                              Text(
                                _fechaHasta != null
                                    ? '${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'
                                    : 'Hasta',
                                style: TextStyle(
                                  color: _fechaHasta != null ? Colors.black : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_fechaDesde != null || _fechaHasta != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() {
                          _fechaDesde = null;
                          _fechaHasta = null;
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

         // Lista de ventas
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _db.getVentas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay ventas aún', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              var docs = snapshot.data!;

              // Filtrar por cliente
              if (_filtroCliente.isNotEmpty) {
                docs = docs.where((data) {
                  final nombre = (data['clienteNombre'] ?? '').toLowerCase();
                  final ruc = (data['clienteRucCi'] ?? '').toLowerCase();
                  return nombre.contains(_filtroCliente) || ruc.contains(_filtroCliente);
                }).toList();
              }

              // Filtrar por fecha
              if (_fechaDesde != null) {
                docs = docs.where((data) {
                  final fecha = DateTime.parse(data['fecha']);
                  return fecha.isAfter(_fechaDesde!.subtract(const Duration(days: 1)));
                }).toList();
              }
              if (_fechaHasta != null) {
                docs = docs.where((data) {
                  final fecha = DateTime.parse(data['fecha']);
                  return fecha.isBefore(_fechaHasta!.add(const Duration(days: 1)));
                }).toList();
              }        

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('No se encontraron ventas', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final ventaId = data['id'].toString();
                    final fecha = DateTime.parse(data['fecha']);
                    final anulada = data['estado'] == 'anulada';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: anulada
                              ? Colors.red.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          anulada ? Icons.cancel : Icons.check_circle,
                          color: anulada ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['clienteNombre'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: anulada ? TextDecoration.lineThrough : null,
                                color: anulada ? Colors.grey : Colors.black,
                              ),
                            ),
                          ),
                          if (anulada)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ANULADA',
                                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        'RUC/CI: ${data['clienteRucCi']} | ${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        'Gs. ${formatGs((data['total'] ?? 0).toDouble())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: anulada ? Colors.grey : const Color(0xFF1E88E5),
                          decoration: anulada ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      onTap: () => _verDetalle(data, ventaId),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetalleVenta extends StatelessWidget {
  final Map<String, dynamic> venta;
  final String ventaId;
  final DatabaseService db;
  final FirestoreService gastosService;

  const _DetalleVenta({
    required this.venta,
    required this.ventaId,
    required this.db,
    required this.gastosService,
  });

  void _anularVenta(BuildContext context) {
    final anulada = venta['estado'] == 'anulada';

    if (anulada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta venta ya está anulada')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Anular Venta'),
          ],
        ),
        content: const Text('Esta acción devolverá el stock de los productos. ¿Confirmás que querés anular esta venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final gastosParaEliminar = await db.anularVenta(ventaId, venta);
              for (final gasto in gastosParaEliminar) {
                await gastosService.eliminarGastoCostoVenta(
                  gasto['nombre'],
                  gasto['cantidad'],
                );
              }
              Navigator.pop(context); // Cierra el bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Venta anulada y stock restaurado'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(venta['fecha']);
    final items = venta['items'] as List<dynamic>;
    final anulada = venta['estado'] == 'anulada';

    // (Opcional si necesitas usarlo o mostrarlo) 
    final nombreClienteLimpio = (venta['clienteNombre'] ?? 'Cliente').toString().replaceAll(' ', '_');
    final nombreBasePdf = '${nombreClienteLimpio}_${fecha.day}-${fecha.month}-${fecha.year}';


    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
      padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, color: Color(0xFF1E88E5)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'DETALLE DE VENTA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2744),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Info cliente
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        venta['clienteNombre'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    'RUC/CI: ${venta['clienteRucCi']}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (anulada)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'VENTA ANULADA',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
			
            // Items
            const Text('PRODUCTOS / SERVICIOS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
            const SizedBox(height: 8),
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${item['cantidad']} x Gs. ${formatGs((item['precioUnitario'] ?? 0).toDouble())}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
              ),
                  Text(
                    'Gs. ${formatGs((item['subtotal'] ?? 0).toDouble())}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5)),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            // Totales
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(8),
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
                              Text('Gs. ${formatGs((venta['subtotal'] ?? 0).toDouble())}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('IVA 10%:'),
                              Text('Gs. ${formatGs((venta['iva10'] ?? 0).toDouble())}'),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'Gs. ${formatGs((venta['total'] ?? 0).toDouble())}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E88E5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Pagó:'),
                      Text('Gs. ${formatGs((venta['montoPagado'] ?? 0).toDouble())}'),
                    ],
                  ),
                  if ((venta['vuelto'] ?? 0) > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vuelto:'),
                        Text('Gs. ${formatGs((venta['vuelto'] ?? 0).toDouble())}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
                        // Botones
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2744),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final ajustes = await AjustesService.getAjustes();
                        await TicketService.imprimirA4(
                          venta: venta,
                          ajustes: ajustes,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir la vista de impresión A4.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text('A4', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PersonalizacionService.instance.colorPrimario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final ajustes = await AjustesService.getAjustes();
                        await TicketService.imprimirTicket(
                          venta: venta,
                          ajustes: ajustes,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir la vista de impresión del Ticket.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.receipt, color: Colors.white),
                    label: const Text('Ticket', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!anulada)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _anularVenta(context),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    'ANULAR VENTA',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
