import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  final FirestoreService _service = FirestoreService();
  final DatabaseService _db = DatabaseService.instance;
  String _periodoSeleccionado = 'Mes';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  int _paginaGastosAuto = 0;
  int _paginaGastosManuales = 0;
  int _paginaIngresos = 0;
  static const int _itemsPorPagina = 10;

  Future<bool> _pedirContrasena() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Confirmás que querés eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result == true;
  }
  
  Widget _paginador({required int total, required int paginaActual, required Function(int) onCambiar}) {
    final totalPaginas = (total / _itemsPorPagina).ceil();
    if (totalPaginas <= 1) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPaginas, (i) {
        final seleccionado = i == paginaActual;
        return GestureDetector(
          onTap: () => onCambiar(i),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: seleccionado ? const Color(0xFF1E88E5) : const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: seleccionado ? const Color(0xFF1E88E5) : Colors.grey.shade300),
            ),
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: seleccionado ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
  Widget _listaGastos(List gastos, {required bool mostrarEliminar}) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: gastos.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
            final g = gastos[index];
            final fecha = DateTime.parse(g['fecha']);
            final automatico = g['automatico'] ?? false;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(automatico ? Icons.inventory : Icons.receipt_long, color: Colors.red, size: 20),
              ),
              title: Text(g['descripcion'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${g['categoria']} | ${fecha.day}/${fecha.month}/${fecha.year}', style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Gs. ${formatGs((g['monto'] ?? 0).toDouble())}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  if (mostrarEliminar)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                      onPressed: () async {
                        if (await _pedirContrasena()) {
                          _db.eliminarGasto(g['id']);
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      );
    }

  void _mostrarTodosGastos(List gastos, String titulo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2744))),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: gastos.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final g = gastos[index];
                  final fecha = DateTime.parse(g['fecha']);
                  final automatico = g['automatico'] ?? false;
                  return ListTile(
                    leading: Icon(automatico ? Icons.inventory : Icons.receipt_long, color: Colors.red),
                    title: Text(g['descripcion'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${g['categoria']} | ${fecha.day}/${fecha.month}/${fecha.year}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Gs. ${formatGs((g['monto'] ?? 0).toDouble())}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        if (!automatico)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () async {
                              if (await _pedirContrasena()) {
                                _db.eliminarGasto(g['id']);
                                Navigator.pop(context);
                              }
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _listaIngresos(List ingresos) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ingresos.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final c = ingresos[index];
          final fecha = DateTime.parse(c['fecha']);
          final esGanancia = c['tipo'] == 'ganancia_extra';
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (esGanancia ? Colors.green : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                esGanancia ? Icons.star : Icons.account_balance,
                color: esGanancia ? Colors.green : Colors.blue,
                size: 20,
              ),
            ),
            title: Text(c['descripcion'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${esGanancia ? "Ganancia Extra" : "Capital Inyectado"} | ${fecha.day}/${fecha.month}/${fecha.year}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gs. ${formatGs((c['monto'] ?? 0).toDouble())}',
                    style: TextStyle(color: esGanancia ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                  onPressed: () async {
                    if (await _pedirContrasena()) {
                      _db.eliminarCapital(c['id']);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _mostrarTodosIngresos(List ingresos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('INGRESOS DEL PERÍODO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2744))),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                itemCount: ingresos.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final c = ingresos[index];
                  final fecha = DateTime.parse(c['fecha']);
                  final esGanancia = c['tipo'] == 'ganancia_extra';
                  return ListTile(
                    leading: Icon(
                      esGanancia ? Icons.star : Icons.account_balance,
                      color: esGanancia ? Colors.green : Colors.blue,
                    ),
                    title: Text(c['descripcion'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${esGanancia ? "Ganancia Extra" : "Capital Inyectado"} | ${fecha.day}/${fecha.month}/${fecha.year}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Gs. ${formatGs((c['monto'] ?? 0).toDouble())}',
                            style: TextStyle(color: esGanancia ? Colors.green : Colors.blue, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                          onPressed: () async {
                            if (await _pedirContrasena()) {
                              _db.eliminarCapital(c['id']);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
        if (esDesde) _fechaDesde = fecha;
        else _fechaHasta = fecha;
      });
    }
  }

  bool _enPeriodo(String fechaStr) {
    final fecha = DateTime.parse(fechaStr);
    final ahora = DateTime.now();
    if (_periodoSeleccionado == 'Hoy') {
      return fecha.day == ahora.day &&
          fecha.month == ahora.month &&
          fecha.year == ahora.year;
    } else if (_periodoSeleccionado == 'Semana') {
      final inicioSemana =
          ahora.subtract(Duration(days: ahora.weekday - 1));
      return fecha.isAfter(
          inicioSemana.subtract(const Duration(days: 1)));
    } else if (_periodoSeleccionado == 'Mes') {
      return fecha.month == ahora.month && fecha.year == ahora.year;
    } else if (_periodoSeleccionado == 'Personalizado') {
      if (_fechaDesde != null &&
          fecha.isBefore(_fechaDesde!)) return false;
      if (_fechaHasta != null &&
          fecha.isAfter(
              _fechaHasta!.add(const Duration(days: 1)))) return false;
      return true;
    }
    return true;
  }

void _mostrarTutorialFinanzas() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E88E5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Guía de Finanzas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _TutorialSeccionFinanzas(
                      numero: '1',
                      titulo: 'Entendiendo el Resumen Principal',
                      descripcion: 'En la pantalla de inicio verás indicadores clave:',
                      items: [
                        'Estado Actual: El recuadro grande te indica si tienes un balance positivo o negativo en el periodo seleccionado.',
                        'Ingresos y Gastos: El total de dinero que entró por ventas vs. el total que salió.',
                        'Saldo en Caja: El efectivo real que deberías tener disponible.',
                        'Capital Inyectado: Dinero propio o externo que pusiste en el negocio (no es una venta).',
                      ],
                    ),
                    SizedBox(height: 16),
                    _TutorialSeccionFinanzas(
                      numero: '2',
                      titulo: 'Cómo Registrar un Nuevo Gasto',
                      descripcion: 'Cada vez que compres insumos o pagues un servicio:',
                      items: [
                        'Tocá el botón Nuevo Gasto.',
                        'Seleccioná la Categoría: Insumos, Salario, Servicios u Otros.',
                        'Descripción: Escribí qué compraste (ej: "Compra de cartuchos").',
                        'Monto: Ingresá el valor total en Guaraníes.',
                        '⚙️ Nota: Los gastos Automáticos se generan solos cuando realizás una venta que descuenta stock.',
                      ],
                    ),
                    SizedBox(height: 16),
                    _TutorialSeccionFinanzas(
                      numero: '3',
                      titulo: 'Cómo Agregar Ingresos o Capital',
                      descripcion: 'Si metés dinero al negocio o recibís un ingreso extra:',
                      items: [
                        'Tocá el botón Agregar Ingreso.',
                        'Capital Inyectado: Es dinero que metes al negocio, no generado por el mismo.',
                        'Ganancia Extra: Si es un ingreso por fuera de tus ventas habituales.',
                        'Poné una descripción clara (ej: "Aporte para mercaderías").',
                      ],
                    ),
                    SizedBox(height: 16),
                    _TutorialSeccionFinanzas(
                      numero: '4',
                      titulo: 'Revisión de Historial',
                      descripcion: 'Desplazate hacia abajo para ver:',
                      items: [
                        'Gastos del Periodo: Para controlar en qué se está yendo el dinero.',
                        'Ingresos del Periodo: Para saber cuánto dinero has invertido o recibido.',
                      ],
                    ),
                    SizedBox(height: 16),
                    _TipFinanzas(texto: 'Registrá todo al instante: No esperes que finalice el día para anotar los gastos pequeños; así tu Saldo en Caja siempre será exacto.'),
                    SizedBox(height: 8),
                    _TipFinanzas(texto: 'Usá las gráficas: El gráfico de ventas por mes te ayudará a identificar cuáles son tus mejores épocas.'),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _mostrarAgregarGasto() {
    final montoCtrl = TextEditingController();
    final descripCtrl = TextEditingController();
    String categoria = 'Insumos';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                24,
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
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
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.remove_circle,
                            color: Colors.red),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'NUEVO GASTO',
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

              // Categoría
              const Text(
                'Categoría',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2744),
                    fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Insumos', 'Salario', 'Servicios', 'Otros']
                    .map((cat) {
                  final sel = categoria == cat;
                  return GestureDetector(
                    onTap: () => setModalState(() => categoria = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF1E88E5)
                            : const Color(0xFFF4F6FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF1E88E5)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Descripción
              TextField(
                controller: descripCtrl,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Descripción *',
                  prefixIcon: const Icon(Icons.description,
                      color: Color(0xFF1E88E5)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1E88E5), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Monto
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Monto (Gs.) *',
                  prefixIcon: const Icon(Icons.attach_money,
                      color: Color(0xFF1E88E5)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: Color(0xFF1E88E5), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (descripCtrl.text.trim().isEmpty ||
                        montoCtrl.text.trim().isEmpty) return;
                    await _db.agregarGasto({
                      'fecha': DateTime.now().toIso8601String(),
                      'categoria': categoria,
                      'descripcion': descripCtrl.text.trim(),
                      'monto': double.parse(montoCtrl.text.trim()),
                      'automatico': false,
                    });
                    Navigator.pop(context);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'GUARDAR GASTO',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
              ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _mostrarAgregarCapital() {
    final montoCtrl = TextEditingController();
    final descripCtrl = TextEditingController();
    String tipoCapital = 'capital';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              24,
        ),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
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
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.add_circle, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'INYECTAR CAPITAL',
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
            StatefulBuilder(
              builder: (context, setModalState) => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => tipoCapital = 'capital'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: tipoCapital == 'capital' ? const Color(0xFF1E88E5) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Capital Inyectado', textAlign: TextAlign.center,
                          style: TextStyle(color: tipoCapital == 'capital' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => tipoCapital = 'ganancia_extra'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: tipoCapital == 'ganancia_extra' ? Colors.green : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Ganancia Extra', textAlign: TextAlign.center,
                          style: TextStyle(color: tipoCapital == 'ganancia_extra' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripCtrl,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Descripción *',
                prefixIcon: const Icon(Icons.description,
                    color: Color(0xFF1E88E5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E88E5), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Monto (Gs.) *',
                prefixIcon: const Icon(Icons.attach_money,
                    color: Color(0xFF1E88E5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E88E5), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (descripCtrl.text.trim().isEmpty ||
                      montoCtrl.text.trim().isEmpty) return;
                  await _db.agregarCapital({
                    'fecha': DateTime.now().toIso8601String(),
                    'descripcion': descripCtrl.text.trim(),
                    'monto': double.parse(montoCtrl.text.trim()),
                    'tipo': tipoCapital,
                  });
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'GUARDAR CAPITAL',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Map<String, double> _ventasPorMes(List<Map<String, dynamic>> ventas) {
    final Map<String, double> resultado = {};
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    for (final v in ventas) {
      final fecha = DateTime.parse(v['fecha']);
      final clave = meses[fecha.month - 1];
      resultado[clave] = (resultado[clave] ?? 0) + (v['total'] ?? 0).toDouble();
    }
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getVentas(),
      builder: (context, snapVentas) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getGastos(),
          builder: (context, snapGastos) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getCapital(),
              builder: (context, snapCapital) {
                if (snapVentas.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Ventas del período
                final todasVentas = snapVentas.data ?? [];
                final ventasPeriodo = todasVentas
                    .where((v) => _enPeriodo(v['fecha']) && v['estado'] != 'anulada')
                    .toList();
                final totalIngresos = ventasPeriodo.fold(
                    0.0, (sum, v) => sum + (v['total'] ?? 0).toDouble());

                // Gastos del período
                final todosGastos = snapGastos.data ?? [];
                final gastosPeriodo = todosGastos
                    .where((g) => _enPeriodo(g['fecha']))
                    .toList();
                final totalGastos = gastosPeriodo.fold(
                    0.0, (sum, g) => sum + (g['monto'] ?? 0).toDouble());

                // Capital del período
                final todoCapital = snapCapital.data ?? [];
                final capitalPeriodo = todoCapital
                    .where((c) => _enPeriodo(c['fecha']))
                    .toList();
                final totalCapitalInyectado = capitalPeriodo
                    .where((c) => (c['tipo'] ?? 'capital') == 'capital')
                    .fold(0.0, (sum, c) => sum + (c['monto'] ?? 0).toDouble());

                final totalGananciasExtras = capitalPeriodo
                    .where((c) => c['tipo'] == 'ganancia_extra')
                    .fold(0.0, (sum, c) => sum + (c['monto'] ?? 0).toDouble());

                final utilidad = totalIngresos + totalGananciasExtras - totalGastos;
                final flujoCaja = totalIngresos + totalGananciasExtras + totalCapitalInyectado - totalGastos;
                final resultado = utilidad;
                final ganando = utilidad >= 0;

                // Datos gráfico por mes
                final ventasMes = _ventasPorMes(todasVentas);
                final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

                return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                            Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          pageHeader('FINANZAS', context),
                          IconButton(
                            icon: const Icon(Icons.help_outline, color: Color(0xFF1E88E5), size: 28),
                            onPressed: _mostrarTutorialFinanzas,
                          ),
                        ],
                      ),


                      // Selector período
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
                                  color: Color(0xFF1A2744)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: ['Hoy', 'Semana', 'Mes', 'Personalizado']
                                  .map((p) {
                                final sel = _periodoSeleccionado == p;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _periodoSeleccionado = p),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? const Color(0xFF1E88E5)
                                            : const Color(0xFFF4F6FA),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: sel
                                              ? const Color(0xFF1E88E5)
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        p,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: sel
                                              ? Colors.white
                                              : Colors.grey,
                                             fontWeight: FontWeight.w600,
                                          fontSize: 11,
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
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 16,
                                                color: Color(0xFF1E88E5)),
                                            const SizedBox(width: 8),
                                            Text(
                                              _fechaDesde != null
                                                  ? '${_fechaDesde!.day}/${_fechaDesde!.month}/${_fechaDesde!.year}'
                                                  : 'Desde',
                                              style: TextStyle(
                                                color: _fechaDesde != null
                                                    ? Colors.black
                                                    : Colors.grey,
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
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 16,
                                                color: Color(0xFF1E88E5)),
                                            const SizedBox(width: 8),
                                            Text(
                                              _fechaHasta != null
                                                  ? '${_fechaHasta!.day}/${_fechaHasta!.month}/${_fechaHasta!.year}'
                                                  : 'Hasta',
                                              style: TextStyle(
                                                color: _fechaHasta != null
                                                    ? Colors.black
                                                    : Colors.grey,
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

                      // Resultado principal
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ganando ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              ganando
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ganando ? '¡ESTÁS GANANDO!' : 'ESTÁS PERDIENDO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gs. ${formatGs(resultado.abs())}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tarjetas ingresos gastos capital
                      Row(
                        children: [
                          _tarjeta(
                            titulo: 'Ingresos',
                            valor: 'Gs. ${formatGs(totalIngresos)}',
                            icono: Icons.arrow_upward,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _tarjeta(
                            titulo: 'Gastos',
                            valor: 'Gs. ${formatGs(totalGastos)}',
                            icono: Icons.arrow_downward,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _tarjeta(
                            titulo: 'Ganancias Extras',
                            valor: 'Gs. ${formatGs(totalGananciasExtras)}',
                            icono: Icons.star,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _tarjeta(
                            titulo: 'Capital Inyectado',
                            valor: 'Gs. ${formatGs(totalCapitalInyectado)}',
                            icono: Icons.account_balance,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _tarjetaAncha(
                        titulo: 'Saldo en Caja',
                        valor: 'Gs. ${formatGs(flujoCaja)}',
                        icono: Icons.account_balance_wallet,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 16),

                      // Gráfico comparativo por mes
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
                              'Ventas por mes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2744),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 200,
                              child: ventasMes.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No hay datos aún',
                                        style:
                                            TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        gridData:
                                            const FlGridData(show: false),
                                        borderData:
                                            FlBorderData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false),
                                          ),
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget:
                                                  (value, meta) {
                                                final idx = value.toInt();
                                                if (idx < 0 ||
                                                    idx >= meses.length) {
                                                  return const Text('');
                                                }
                                                return Text(
                                                  meses[idx],
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        barGroups: meses
                                            .asMap()
                                            .entries
                                            .map((e) => BarChartGroupData(
                                                  x: e.key,
                                                  barRods: [
                                                    BarChartRodData(
                                                      toY: ventasMes[
                                                              e.value] ??
                                                          0,
                                                      color: const Color(
                                                          0xFF1E88E5),
                                                      width: 16,
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(4),
                                                    ),
                                                  ],
                                                ))
                                            .toList(),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botones agregar
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _mostrarAgregarGasto,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'Agregar Gasto',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _mostrarAgregarCapital,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'Agregar ingreso',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lista gastos del período
                      if (gastosPeriodo.isNotEmpty) ...[
                        // Gastos Automáticos
                        Builder(builder: (context) {
                          final automaticos = gastosPeriodo.where((g) => g['automatico'] == true).toList();
                          final manuales = gastosPeriodo.where((g) => (g['automatico'] ?? false) == false).toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (automaticos.isNotEmpty) ...[
                                const Text('GASTOS AUTOMÁTICOS',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                                const SizedBox(height: 8),
                                _listaGastos(automaticos.skip(_paginaGastosAuto * _itemsPorPagina).take(_itemsPorPagina).toList(), mostrarEliminar: false),
                                _paginador(total: automaticos.length, paginaActual: _paginaGastosAuto, onCambiar: (p) => setState(() => _paginaGastosAuto = p)),





                                const SizedBox(height: 16),
                              ],
                              if (manuales.isNotEmpty) ...[
                                const Text('GASTOS MANUALES',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                                const SizedBox(height: 8),
                                _listaGastos(manuales.skip(_paginaGastosManuales * _itemsPorPagina).take(_itemsPorPagina).toList(), mostrarEliminar: true),
                                _paginador(total: manuales.length, paginaActual: _paginaGastosManuales, onCambiar: (p) => setState(() => _paginaGastosManuales = p)),





                              ],
                            ],
                          );
                        }),
                      ],

                                         // Lista capital del período
                      if (capitalPeriodo.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'INGRESOS DEL PERÍODO',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2744),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _listaIngresos(capitalPeriodo.skip(_paginaIngresos * _itemsPorPagina).take(_itemsPorPagina).toList()),
                        _paginador(total: capitalPeriodo.length, paginaActual: _paginaIngresos, onCambiar: (p) => setState(() => _paginaIngresos = p)),





                      ],
                    ],
                  ),
                );
              },
            );
          },
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
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                  Text(valor,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAncha({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
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
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(valor,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
  
}
class _TutorialSeccionFinanzas extends StatelessWidget {
  final String numero;
  final String titulo;
  final String descripcion;
  final List<String> items;
  const _TutorialSeccionFinanzas({required this.numero, required this.titulo, required this.descripcion, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle),
                child: Center(child: Text(numero, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A2744)))),
            ],
          ),
          const SizedBox(height: 8),
          Text(descripcion, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item, style: const TextStyle(fontSize: 13, color: Color(0xFF1A2744))),
          )),
        ],
      ),
    );
  }
}

class _TipFinanzas extends StatelessWidget {
  final String texto;
  const _TipFinanzas({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13, color: Color(0xFF1A2744)))),
        ],
      ),
    );
  }
}
