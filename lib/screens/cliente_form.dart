import '../widgets/responsive.dart';
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import 'package:flutter/services.dart';
import '../models/cliente.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';

class ClienteForm extends StatefulWidget {
  final String rucCiInicial;
  final Cliente? clienteExistente;

  const ClienteForm({
    super.key,
    this.rucCiInicial = '',
    this.clienteExistente,
  });

  @override
  State<ClienteForm> createState() => _ClienteFormState();
}

class _ClienteFormState extends State<ClienteForm> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService.instance;

  final _nombreCtrl = TextEditingController();
  final _rucCiCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  String _tipoContribuyente = 'Física';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.clienteExistente != null) {
      _nombreCtrl.text = widget.clienteExistente!.nombre;
      _rucCiCtrl.text = widget.clienteExistente!.rucCi;
      _correoCtrl.text = widget.clienteExistente!.email;
      _telefonoCtrl.text = widget.clienteExistente!.telefono;
      _direccionCtrl.text = widget.clienteExistente!.direccion;
      _tipoContribuyente = widget.clienteExistente!.tipoContribuyente;
    } else {
      _rucCiCtrl.text = widget.rucCiInicial;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rucCiCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final cliente = Cliente(
      id: widget.clienteExistente?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      rucCi: _rucCiCtrl.text.trim(),
      email: _correoCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      tipoContribuyente: _tipoContribuyente,
    );

    final id = await _db.agregarCliente(cliente);
    setState(() => _guardando = false);

    Navigator.pop(context, Cliente(
      id: id,
      nombre: cliente.nombre,
      rucCi: cliente.rucCi,
      email: cliente.email,
      telefono: cliente.telefono,
      direccion: cliente.direccion,
      tipoContribuyente: cliente.tipoContribuyente,
    ));
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                        child: const Icon(Icons.person_add, color: Color(0xFF1E88E5)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.clienteExistente != null ? 'EDITAR CLIENTE' : 'NUEVO CLIENTE',
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
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Tipo de Contribuyente',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2744),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Física', 'Jurídica'].map((tipo) {
                  final seleccionado = _tipoContribuyente == tipo;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tipoContribuyente = tipo),
                      child: Container(
                        margin: EdgeInsets.only(right: tipo == 'Física' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: seleccionado ? const Color(0xFF1E88E5) : const Color(0xFFF4F6FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: seleccionado ? const Color(0xFF1E88E5) : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tipo == 'Física' ? Icons.person : Icons.business,
                              color: seleccionado ? Colors.white : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tipo,
                              style: TextStyle(
                                color: seleccionado ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _campo(
                controller: _nombreCtrl,
                label: 'Nombre completo *',
                icono: Icons.badge,
                maxLength: 50,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _campo(
                controller: _rucCiCtrl,
                label: 'RUC o CI *',
                icono: Icons.fingerprint,
                maxLength: 15,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'El RUC o CI es obligatorio';
                  if (v.trim().length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _campo(
                controller: _correoCtrl,
                label: 'Correo electrónico (opcional)',
                icono: Icons.email,
                maxLength: 50,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    if (!v.contains('@') || !v.contains('.')) return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _campo(
                controller: _telefonoCtrl,
                label: 'Teléfono (opcional)',
                icono: Icons.phone,
                maxLength: 15,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              _campo(
                controller: _direccionCtrl,
                label: 'Dirección (opcional)',
                icono: Icons.location_on,
                maxLength: 50,
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
                            Text(
                              'GUARDAR CLIENTE',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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