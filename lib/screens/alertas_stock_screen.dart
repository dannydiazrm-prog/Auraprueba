import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/database_service.dart';

class AlertasStockScreen extends StatelessWidget {
  const AlertasStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Producto>>(
      stream: DatabaseService.instance.getProductos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = snapshot.data ?? [];

        // Filtrar solo productos con stock bajo
        final alertas = todos
            .where((p) => !p.esServicio && p.stock <= p.stockMinimo)
            .toList();

        // Ordenar por urgencia (menor stock primero)
        alertas.sort((a, b) => a.stock.compareTo(b.stock));

        return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
                            pageHeader(
                'ALERTAS DE STOCK',
                context,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: alertas.isEmpty
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alertas.isEmpty ? Icons.check_circle : Icons.warning,
                        color: alertas.isEmpty ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alertas.isEmpty ? 'Todo en orden' : '${alertas.length} alertas',
                        style: TextStyle(
                          color: alertas.isEmpty ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (alertas.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 60, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          '¡Todo el stock está en orden!',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ningún producto está por debajo del stock mínimo',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                    itemCount: alertas.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final p = alertas[index];
                      final porcentaje = p.stockMinimo > 0
                          ? (p.stock / p.stockMinimo).clamp(0.0, 1.0)
                          : 0.0;
                      final sinStock = p.stock == 0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: sinStock
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                sinStock
                                    ? Icons.remove_shopping_cart
                                    : Icons.warning_amber,
                                color: sinStock ? Colors.red : Colors.orange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        p.nombre,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: sinStock
                                              ? Colors.red
                                              : Colors.orange,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          sinStock
                                              ? 'SIN STOCK'
                                              : 'STOCK BAJO',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Código: ${p.codigo} | Stock actual: ${p.stock} | Mínimo: ${p.stockMinimo}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: porcentaje,
                                      backgroundColor: Colors.grey.shade200,
                                      color: sinStock
                                          ? Colors.red
                                          : Colors.orange,
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}