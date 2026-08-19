import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final inicioDia = DateTime(ahora.year, ahora.month, ahora.day);
    final finDia = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.instance.getVentas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data ?? [];

        // Filtrar ventas del día
        final ventasHoy = docs.where((data) {
          final fecha = DateTime.parse(data['fecha']);
          return fecha.isAfter(inicioDia) && fecha.isBefore(finDia);
        }).toList();

        // Calcular totales
        double totalVendido = 0;
        int cantidadFacturas = 0;
        double totalAnulado = 0;
        int cantidadAnuladas = 0;

        for (final data in ventasHoy) {
          final anulada = data['estado'] == 'anulada';
          final total = (data['total'] ?? 0).toDouble();

          if (anulada) {
            totalAnulado += total;
            cantidadAnuladas++;
          } else {
            totalVendido += total;
            cantidadFacturas++;
          }
        }

        return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
                            pageHeader('CAJA DEL DÍA', context),


              // Tarjetas resumen
              Row(
                children: [
                  _tarjeta(
                    titulo: 'Total Vendido',
                    valor: 'Gs. ${formatGs(totalVendido)}',
                    icono: Icons.trending_up,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _tarjeta(
                    titulo: 'Facturas Emitidas',
                    valor: '$cantidadFacturas',
                    icono: Icons.receipt,
                    color: const Color(0xFF1E88E5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _tarjeta(
                    titulo: 'Ventas Anuladas',
                    valor: '$cantidadAnuladas',
                    icono: Icons.cancel,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _tarjeta(
                    titulo: 'Monto Anulado',
                    valor: 'Gs. ${formatGs(totalAnulado)}',
                    icono: Icons.money_off,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lista de ventas del día
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
                      'VENTAS DE HOY',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2744),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (ventasHoy.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay ventas hoy todavía',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ventasHoy.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final data = ventasHoy[index];
                          final fecha = DateTime.parse(data['fecha']);
                          final anulada = data['estado'] == 'anulada';

                          return ListTile(
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
                            title: Text(
                              data['clienteNombre'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: anulada ? Colors.grey : Colors.black,
                                decoration: anulada
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              '${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')} | RUC/CI: ${data['clienteRucCi']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              'Gs. ${formatGs((data['total'] ?? 0).toDouble())}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: anulada
                                    ? Colors.grey
                                    : const Color(0xFF1E88E5),
                                decoration: anulada
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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