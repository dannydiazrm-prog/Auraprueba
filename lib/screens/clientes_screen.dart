import '../widgets/responsive.dart';
import "../widgets/page_header.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import 'dart:io';
import '../models/cliente.dart';
import '../services/firestore_service.dart';
import '../services/database_service.dart';
import 'cliente_form.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final FirestoreService _service = FirestoreService();
  final DatabaseService _db = DatabaseService.instance;
  final _buscarCtrl = TextEditingController();
  String _filtro = '';

  bool get _esEscritorio => kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux));

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _abrirEditar(Cliente cliente) async {
    if (_esEscritorio) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SizedBox(
            width: 500,
            child: ClienteForm(clienteExistente: cliente),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ClienteForm(clienteExistente: cliente),
      );
    }
    setState(() {});
  }

  void _confirmarEliminar(Cliente cliente) async {
    final tieneVentas = await _db.clienteTieneVentas(cliente.id);

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
            '${cliente.nombre} tiene ventas asociadas. Para eliminarlo primero debes anular todas sus facturas en el Historial de Ventas.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: PersonalizacionService.instance.colorPrimario),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(color: Colors.white)),
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
            Text('Eliminar cliente'),
          ],
        ),
        content: Text('¿Estás seguro que deseas eliminar a ${cliente.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.eliminarCliente(cliente.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente eliminado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarOpciones(Cliente cliente) {
    if (_esEscritorio) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SizedBox(
            width: 500,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF1E88E5)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2744))),
                          Text('RUC/CI: ${cliente.rucCi}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.edit, color: Colors.blue),
                    ),
                    title: const Text('Editar cliente'),
                    subtitle: const Text('Modificar datos del cliente'),
                    onTap: () {
                      Navigator.pop(context);
                      _abrirEditar(cliente);
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    title: const Text('Eliminar cliente'),
                    subtitle: const Text('Borrar datos de cliente'),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmarEliminar(cliente);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
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
                    child: const Icon(Icons.person, color: Color(0xFF1E88E5)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cliente.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2744))),
                      Text('RUC/CI: ${cliente.rucCi}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit, color: Colors.blue),
                ),
                title: const Text('Editar cliente'),
                subtitle: const Text('Modificar datos del cliente'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirEditar(cliente);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Eliminar cliente'),
                subtitle: const Text('Borrar datos de cliente'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminar(cliente);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader('CLIENTES', context),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _buscarCtrl,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre o RUC/CI',
                prefixIcon: Icon(Icons.search, color: Color(0xFF1E88E5)),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _filtro = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Cliente>>(
            stream: _db.getClientes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hay clientes registrados', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Los clientes se crean desde Nueva Venta', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              var clientes = snapshot.data!;

              if (_filtro.isNotEmpty) {
                clientes = clientes.where((c) =>
                    c.nombre.toLowerCase().contains(_filtro) ||
                    c.rucCi.toLowerCase().contains(_filtro)).toList();
              }

              if (_filtro.isEmpty && clientes.length > 10) {
                clientes = clientes.sublist(clientes.length - 10);
              }

              if (clientes.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('No se encontraron clientes', style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: clientes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final c = clientes[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            c.nombre[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'RUC/CI: ${c.rucCi}${c.telefono.isNotEmpty ? ' | Tel: ${c.telefono}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () => _mostrarOpciones(c),
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