import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';
import '../services/personalizacion_service.dart';

class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen> {
  String _periodoSeleccionado = 'Semana';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  bool _cargando = true;

  List<Map<String, dynamic>> _ventas = [];

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() => _cargando = true);
    final todas = await DatabaseService.instance.getVentas().first;

    setState(() {
      _ventas = todas.where((v) => v['estado'] != 'anulada').toList();
      _cargando = false;
    });
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
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

  List<Map<String, dynamic>> get _ventasFiltradas {
    final ahora = DateTime.now();
    return _ventas.where((v) {
      final fecha = DateTime.parse(v['fecha']);
      if (_periodoSeleccionado == 'Semana') {
        final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
        return fecha.isAfter(inicioSemana.subtract(const Duration(days: 1)));
      } else if (_periodoSeleccionado == 'Mes') {
        return fecha.month == ahora.month && fecha.year == ahora.year;
      } else if (_periodoSeleccionado == 'Personalizado') {
        if (_fechaDesde != null && fecha.isBefore(_fechaDesde!)) return false;
        if (_fechaHasta != null && fecha.isAfter(_fechaHasta!.add(const Duration(days: 1)))) return false;
        return true;
      }
      return true;
    }).toList();
  }

  Map<String, double> get _ventasPorDia {
    final Map<String, double> resultado = {};
    for (final v in _ventasFiltradas) {
      final fecha = DateTime.parse(v['fecha']);
      final clave = '${fecha.day}/${fecha.month}';
      resultado[clave] = (resultado[clave] ?? 0) + (v['total'] ?? 0).toDouble();
    }
    return resultado;
  }

  Map<String, double> get _topClientes {
    final Map<String, double> resultado = {};
    for (final v in _ventasFiltradas) {
      final nombre = v['clienteNombre'] ?? 'Sin nombre';
      if (nombre == 'Cliente Mostrador') continue;
      resultado[nombre] = (resultado[nombre] ?? 0) + (v['total'] ?? 0).toDouble();
    }
    final sorted = resultado.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  double get _totalPeriodo =>
      _ventasFiltradas.fold(0, (sum, v) => sum + (v['total'] ?? 0).toDouble());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    pageHeader('REPORTE DE VENTAS', context),


          // Selector de período
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
                  'Período',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2744),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Semana', 'Mes', 'Personalizado'].map((periodo) {
                    final seleccionado = _periodoSeleccionado == periodo;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _periodoSeleccionado = periodo),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? const Color(0xFF1E88E5)
                                : const Color(0xFFF4F6FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: seleccionado
                                  ? const Color(0xFF1E88E5)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            periodo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: seleccionado ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_periodoSeleccionado == 'Personalizado') ...[
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
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total período
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total del período',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      'Ventas no anuladas',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                Text(
                  'Gs. ${formatGs(_totalPeriodo)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gráfico lineal ventas por día
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else ...[
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
                    'Ventas por día',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2744),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _ventasPorDia.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay ventas en este período',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final keys = _ventasPorDia.keys.toList();
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= keys.length) return const Text('');
                                      return Text(
                                        keys[idx],
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _ventasPorDia.values
                                      .toList()
                                      .asMap()
                                      .entries
                                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                                      .toList(),
                                  isCurved: true,
                                  color: const Color(0xFF1E88E5),
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Gráfico barras horizontales top clientes
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
                    'Top 5 Clientes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2744),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_topClientes.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No hay datos de clientes en este período',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...(_topClientes.entries.toList().asMap().entries.map((entry) {
                      final idx = entry.key;
                      final nombre = entry.value.key;
                      final total = entry.value.value;
                      final maxTotal = _topClientes.values.first;
                      final porcentaje = total / maxTotal;

                      final colores = [
                        const Color(0xFF1E88E5),
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.red,
                      ];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${idx + 1}. $nombre',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Gs. ${formatGs(total)}',
                                  style: TextStyle(
                                    color: colores[idx],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: porcentaje,
                                backgroundColor: Colors.grey.shade200,
                                color: colores[idx],
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    })),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}