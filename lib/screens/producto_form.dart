import '../widgets/responsive.dart';
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import 'package:flutter/services.dart';
import '../models/producto.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';

class ProductoForm extends StatefulWidget {
  final Producto? productoExistente;
  const ProductoForm({super.key, this.productoExistente});

  @override
  State<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _gastosService = FirestoreService();
  final DatabaseService _db = DatabaseService.instance;

  final _codigoCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _stockMinimoCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();

  bool _esServicio = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.productoExistente != null) {
      final p = widget.productoExistente!;
      _codigoCtrl.text = p.codigo;
      _nombreCtrl.text = p.nombre;
      _stockCtrl.text = p.stock.toString();
      _stockMinimoCtrl.text = p.stockMinimo.toString();
      _precioCompraCtrl.text = formatGs(p.precioCompra);
      _precioVentaCtrl.text = formatGs(p.precio);
      _esServicio = p.esServicio;
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    _stockCtrl.dispose();
    _stockMinimoCtrl.dispose();
    _precioCompraCtrl.dispose();
    _precioVentaCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final stockAnterior = widget.productoExistente?.stock ?? 0;
    final stockNuevo = _esServicio ? 0 : int.parse(_stockCtrl.text.trim());
    final diferencia = stockNuevo - stockAnterior;

    final producto = Producto(
      id: widget.productoExistente?.id ?? '',
      codigo: _codigoCtrl.text.trim(),
      nombre: _nombreCtrl.text.trim(),
      esServicio: _esServicio,
      stock: stockNuevo,
      stockMinimo: _esServicio ? 0 : int.parse(_stockMinimoCtrl.text.trim()),
      precioCompra: _esServicio ? 0 : double.parse(_precioCompraCtrl.text.trim().replaceAll('.', '')),
      precio: double.parse(_precioVentaCtrl.text.trim().replaceAll('.', '')),
    );

    await _db.agregarProducto(producto);

    if (!_esServicio && diferencia > 0) {
      final precioCompra = double.parse(_precioCompraCtrl.text.trim().replaceAll('.', ''));
      await _db.agregarGasto({
        'fecha': DateTime.now().toIso8601String(),
        'categoria': 'Mercadería',
        'descripcion': '${_nombreCtrl.text.trim()} x$diferencia',
        'monto': diferencia * precioCompra,
        'automatico': true,
      });
    }

    if (!mounted) return;
    setState(() => _guardando = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                        child: const Icon(Icons.inventory, color: Color(0xFF1E88E5)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.productoExistente != null ? 'EDITAR PRODUCTO' : 'NUEVO PRODUCTO',
                        style: const TextStyle(
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
              const Text(
                'Tipo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2744),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _esServicio = false),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_esServicio ? const Color(0xFF1E88E5) : const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !_esServicio ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, color: !_esServicio ? Colors.white : Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Text('Producto', style: TextStyle(color: !_esServicio ? Colors.white : Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _esServicio = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _esServicio ? const Color(0xFF1E88E5) : const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _esServicio ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.build, color: _esServicio ? Colors.white : Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Text('Servicio', style: TextStyle(color: _esServicio ? Colors.white : Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _campo(
                controller: _codigoCtrl,
                label: 'Código *',
                icono: Icons.qr_code,
                maxLength: 20,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El código es obligatorio';
                  if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _campo(
                controller: _nombreCtrl,
                label: 'Nombre del producto *',
                icono: Icons.label,
                maxLength: 50,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (!_esServicio) ...[
                Row(
                  children: [
                    Expanded(
                      child: _campo(
                        controller: _stockCtrl,
                        label: 'Stock inicial *',
                        icono: Icons.archive,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        inputFormatters: [MilesFormatter()],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obligatorio';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _campo(
                        controller: _stockMinimoCtrl,
                        label: 'Stock mínimo *',
                        icono: Icons.warning_amber,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        inputFormatters: [MilesFormatter()],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obligatorio';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _campo(
                  controller: _precioCompraCtrl,
                  label: 'Precio de compra (Gs.) *',
                  icono: Icons.shopping_cart,
                  maxLength: 15,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MilesFormatter()],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'El precio de compra es obligatorio';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              _campo(
                controller: _precioVentaCtrl,
                label: 'Precio de venta (Gs.) *',
                icono: Icons.sell,
                maxLength: 15,
                keyboardType: TextInputType.number,
                inputFormatters: [MilesFormatter()],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El precio de venta es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PersonalizacionService.instance.colorPrimario,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 8),
                            Text('GUARDAR PRODUCTO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        counterStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}