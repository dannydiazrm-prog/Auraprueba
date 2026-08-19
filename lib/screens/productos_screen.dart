import 'package:flutter/foundation.dart';
import 'dart:io';
import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';
import 'producto_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final FirestoreService _service = FirestoreService();
  final DatabaseService _db = DatabaseService.instance;
  final _buscarCtrl = TextEditingController();
  String _filtro = '';
  String _tipoFiltro = 'Todos';

  bool get _esEscritorio => kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _abrirFormulario({Producto? producto}) async {
    if (_esEscritorio) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SizedBox(
            width: 500,
            child: ProductoForm(productoExistente: producto),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProductoForm(productoExistente: producto),
      );
    }
  }

  void _mostrarOpciones(Producto p) {
    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _esEscritorio ? BorderRadius.circular(24) : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2744))),
                    Text('Stock actual: ${p.stock}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              if (_esEscritorio)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF1E88E5)),
            title: const Text('Editar producto'),
            onTap: () {
              Navigator.pop(context);
              _abrirFormulario(producto: p);
            },
          ),
          if (!p.esServicio) ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.green),
            title: const Text('Reponer stock'),
            subtitle: const Text('Registra gasto en Finanzas'),
            onTap: () {
              Navigator.pop(context);
              _dialogReponerStock(p);
            },
          ),
          if (!p.esServicio) ListTile(
            leading: const Icon(Icons.remove_circle, color: Colors.orange),
            title: const Text('Dar de baja stock'),
            subtitle: const Text('Productos dañados o perdidos'),
            onTap: () {
              Navigator.pop(context);
              _dialogBajaStock(p);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Eliminar producto', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmarEliminar(p);
            },
          ),
        ],
      ),
    );

    if (_esEscritorio) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SizedBox(width: 500, child: content),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => content,
      );
    }
  }

  void _dialogReponerStock(Producto p) {
    final cantCtrl = TextEditingController();
    final precioUnitCtrl = TextEditingController(text: p.precioCompra > 0 ? p.precioCompra.toStringAsFixed(0) : '');
    double costoTotal = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reponer Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (p.precioCompra > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF4F6FA), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF1E88E5), size: 16),
                        const SizedBox(width: 8),
                        Text('Última compra: Gs. ${formatGs(p.precioCompra)} c/u', style: const TextStyle(fontSize: 13, color: Color(0xFF1A2744))),
                      ],
                    ),
                  ),
                ),
              TextField(
                controller: cantCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Cantidad a agregar', border: OutlineInputBorder()),
                onChanged: (v) {
                  final cant = int.tryParse(v) ?? 0;
                  final precio = double.tryParse(precioUnitCtrl.text.replaceAll('.', '')) ?? 0;
                  setDialogState(() => costoTotal = cant * precio);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precioUnitCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [MilesFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Precio unitario (Gs.)',
                  border: OutlineInputBorder(),
                  helperText: 'Podés modificarlo si cambió el precio',
                ),
                onChanged: (v) {
                  final cant = int.tryParse(cantCtrl.text) ?? 0;
                  final precio = double.tryParse(v.replaceAll('.', '')) ?? 0;
                  setDialogState(() => costoTotal = cant * precio);
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text('Costo total: Gs. ${formatGs(costoTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final cant = int.tryParse(cantCtrl.text) ?? 0;
                final precioUnit = double.tryParse(precioUnitCtrl.text.replaceAll('.', '')) ?? 0;
                final costo = costoTotal;
                if (cant <= 0) return;

                await _db.actualizarStock(p.id, p.stock + cant);

                if (costo > 0) {
                  await FirebaseFirestore.instance.collection('gastos').add({
                    'descripcion': 'Reposición stock: ${p.nombre} ($cant unidades)',
                    'monto': costo,
                    'categoria': 'Inventario',
                    'fecha': DateTime.now().toIso8601String(),
                    'automatico': true,
                  });
                }

                if (precioUnit > 0 && precioUnit != p.precioCompra) {
                  final actualizar = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Actualizar precio de compra'),
                      content: Text('El precio unitario cambió a Gs. ${formatGs(precioUnit)}. ¿Querés actualizar el precio de compra del producto?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: PersonalizacionService.instance.colorPrimario),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Sí, actualizar', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (actualizar == true) {
                    await _db.actualizarPrecioCompra(p.id, precioUnit);
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stock actualizado: +$cant unidades'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Reponer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogBajaStock(Producto p) {
    final cantCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dar de Baja Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad a dar de baja', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(labelText: 'Motivo (dañado, perdido, etc.)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final cant = int.tryParse(cantCtrl.text) ?? 0;
              if (cant <= 0 || cant > p.stock) return;
              final perdida = cant * p.precioCompra;
              await _db.actualizarStock(p.id, p.stock - cant);
              await FirebaseFirestore.instance.collection('gastos').add({
                'descripcion': 'Baja de stock: ${p.nombre} ($cant unidades) - ${motivoCtrl.text}',
                'monto': perdida,
                'categoria': 'Pérdida de inventario',
                'fecha': DateTime.now().toIso8601String(),
                'automatico': true,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Baja registrada: -$cant unidades. Pérdida: Gs. ${formatGs(perdida)}'), backgroundColor: Colors.orange),
              );
            },
            child: const Text('Dar de baja', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(Producto p) async {
    if (!p.esServicio && p.stock > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: Text('"${p.nombre}" todavía tiene ${p.stock} unidades en stock. Dalo de baja primero.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${p.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.eliminarProducto(p.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
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
          pageHeader(
            'PRODUCTOS',
            context,
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: PersonalizacionService.instance.colorPrimario,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                TextField(
                  controller: _buscarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre o código',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF1E88E5)),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Todos', 'Productos', 'Servicios'].map((tipo) {
                    final seleccionado = _tipoFiltro == tipo;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _tipoFiltro = tipo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: seleccionado ? const Color(0xFF1E88E5) : const Color(0xFFF4F6FA),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: seleccionado ? const Color(0xFF1E88E5) : Colors.grey.shade300),
                          ),
                          child: Text(tipo, style: TextStyle(color: seleccionado ? Colors.white : Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Producto>>(
            stream: _db.getProductos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Column(children: [
                    Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay productos aún', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Toca "Nuevo Producto" para agregar', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ])),
                );
              }
              var productos = snapshot.data!;
              if (_filtro.isNotEmpty) {
                productos = productos.where((p) => p.nombre.toLowerCase().contains(_filtro) || p.codigo.toLowerCase().contains(_filtro)).toList();
              }
              if (_tipoFiltro == 'Productos') {
                productos = productos.where((p) => !p.esServicio).toList();
              } else if (_tipoFiltro == 'Servicios') {
                productos = productos.where((p) => p.esServicio).toList();
              }
              if (productos.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: Text('No se encontraron resultados', style: TextStyle(color: Colors.grey))),
                );
              }
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: productos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final p = productos[index];
                    final alertaStock = !p.esServicio && p.stock <= p.stockMinimo;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: p.esServicio ? Colors.purple.withOpacity(0.1) : const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(p.esServicio ? Icons.build : Icons.inventory_2, color: p.esServicio ? Colors.purple : const Color(0xFF1E88E5), size: 22),
                      ),
                      title: Row(
                        children: [
                          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (alertaStock) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Stock bajo', style: TextStyle(color: Colors.red, fontSize: 11)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('Código: ${p.codigo} | ${p.esServicio ? "Servicio" : "Stock: ${p.stock}"}', style: const TextStyle(fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Gs. ${formatGs(p.precio)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                          if (!p.esServicio) Text('Compra: Gs. ${formatGs(p.precioCompra)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      onTap: () => _mostrarOpciones(p),
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