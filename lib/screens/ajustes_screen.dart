import 'dart:io';
import '../widgets/responsive.dart';
import '../widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/personalizacion_service.dart';

// --- NUEVAS IMPORTACIONES PARA IMPORTAR/EXPORTAR ---
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final _nombreComercioCtrl = TextEditingController();
  bool _guardandoMarca = false;

  @override
  void initState() {
    super.initState();
    _nombreComercioCtrl.text = PersonalizacionService.instance.nombreComercio;
  }

  @override
  void dispose() {
    _nombreComercioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarNombreComercio() async {
    final nombre = _nombreComercioCtrl.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardandoMarca = true);
    await PersonalizacionService.instance.guardarNombre(nombre);
    setState(() => _guardandoMarca = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nombre actualizado exitosamente'), backgroundColor: Colors.green),
    );
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (imagen == null) return;

    final archivoOrigen = File(imagen.path);
    final pesoBytes = await archivoOrigen.length();
    if (pesoBytes > 3 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La imagen es muy pesada, elegí una más liviana (máx. 3 MB)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final directorio = await getApplicationDocumentsDirectory();
    final nuevoPath = '${directorio.path}/logo_negocio.png';
    await archivoOrigen.copy(nuevoPath);
    await PersonalizacionService.instance.guardarLogoPath(nuevoPath);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logo actualizado'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
  }

  Future<void> _abrirWhatsapp() async {
    final uri = Uri.parse('https://wa.me/595983069263');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp. Verificá que la app esté instalada.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al conectar con soporte'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarRestaurar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar valores por defecto'),
        content: const Text('Esto va a volver el nombre, color y logo a los valores originales de Aura Estándar. ¿Confirmás?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PersonalizacionService.instance.restaurarValoresPorDefecto();
              _nombreComercioCtrl.text = PersonalizacionService.instance.nombreComercio;
              if (mounted) setState(() {});
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }
  
    Future<void> _seleccionarColor() async {
    Color colorSeleccionado = PersonalizacionService.instance.colorPrimario;
    final resultado = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true, // <--- 1. ESTO PERMITE QUE EL MODAL CREZCA MÁS DEL 50%
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                24,
          ),
          child: SingleChildScrollView( // <--- 2. ESTO EVITA QUE SE CORTE EN PANTALLAS PEQUEÑAS
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Seleccionar color principal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: colorSeleccionado,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.storefront, color: PersonalizacionService.instance.colorTextoPara(colorSeleccionado)),
                      const SizedBox(height: 6),
                      Text(
                        PersonalizacionService.instance.nombreComercio,
                        style: TextStyle(
                          color: PersonalizacionService.instance.colorTextoPara(colorSeleccionado),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ColorPicker(
                  pickerColor: colorSeleccionado,
                  onColorChanged: (c) => setModalState(() => colorSeleccionado = c),
                  enableAlpha: false,
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.5,
                  pickerAreaBorderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorSeleccionado,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context, colorSeleccionado),
                    child: Text('APLICAR', style: TextStyle(color: PersonalizacionService.instance.colorTextoPara(colorSeleccionado), fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (resultado != null) {
      await PersonalizacionService.instance.guardarColor(resultado);
      if (mounted) setState(() {});
    }
  }

  void _mostrarAcercaDe() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PersonalizacionService.instance.colorPrimario.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline, color: PersonalizacionService.instance.colorPrimario, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Aura estándar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Versión 1.0', style: TextStyle(fontSize: 15, color: Colors.grey)),
              const SizedBox(height: 4),
              const Text('Creado por JP Labs', style: TextStyle(fontSize: 15, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: PersonalizacionService.instance.colorPrimario,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('CERRAR'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================================
  // LÓGICA DE BACKUP: EXPORTAR E IMPORTAR
  // =====================================================================

  Future<void> _exportarDatos() async {
    try {
      final dbFolder = await getDatabasesPath();
      final dbPath = path_pkg.join(dbFolder, 'aura_estandar.db');
      final file = File(dbPath);

      if (await file.exists()) {
        // Share permite enviar el archivo por WhatsApp, guardarlo en Drive o Descargas
        await Share.shareXFiles(
          [XFile(dbPath)],
          text: 'Copia de seguridad - Aura Estándar',
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró la base de datos.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importarDatos() async {
    try {
      // Abre el explorador de archivos para que el usuario elija el backup
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, 
      );

      if (result != null && result.files.single.path != null) {
        final backupPath = result.files.single.path!;
        
        // Validación de seguridad para que no suban cualquier archivo
        if (!backupPath.endsWith('.db')) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo debe ser una base de datos (.db)'), backgroundColor: Colors.red),
          );
          return;
        }

        // Advertencia crítica antes de destruir los datos actuales
        if (!mounted) return;
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Advertencia Crítica'),
            content: const Text('Esto reemplazará TODOS tus datos actuales (productos, ventas, clientes) por los del archivo importado. Esta acción NO se puede deshacer. ¿Continuar?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí, reemplazar datos', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (confirmar == true) {
          final dbFolder = await getDatabasesPath();
          final dbPath = path_pkg.join(dbFolder, 'aura_estandar.db');
          
          // Reemplaza el archivo físico
          final backupFile = File(backupPath);
          await backupFile.copy(dbPath);

          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('¡Importación Exitosa!'),
              content: const Text('Los datos se han restaurado correctamente. Es necesario cerrar la aplicación para aplicar los cambios.'),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => exit(0), // Cierra la app forzadamente para reiniciar limpio
                  child: const Text('Cerrar App', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // =====================================================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pageHeader('Ajustes', context),
          const SizedBox(height: 8),
          _seccion(
            titulo: 'Identidad',
            icono: Icons.palette_outlined,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _seleccionarLogo,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: PersonalizacionService.instance.colorPrimario.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: PersonalizacionService.instance.logoPath != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(PersonalizacionService.instance.logoPath!), fit: BoxFit.cover))
                          : Icon(Icons.add_photo_alternate, color: PersonalizacionService.instance.colorPrimario, size: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarLogo,
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Cambiar logo'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreComercioCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del comercio',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _guardandoMarca ? null : _guardarNombreComercio,
                  style: FilledButton.styleFrom(
                    backgroundColor: PersonalizacionService.instance.colorPrimario,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _guardandoMarca ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('GUARDAR CAMBIOS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Configuración de Estilo',
            icono: Icons.style_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: PersonalizacionService.instance.colorPrimario, shape: BoxShape.circle)),
                title: const Text('Color principal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _seleccionarColor,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // --- NUEVA SECCIÓN: COPIA DE SEGURIDAD ---
          _seccion(
            titulo: 'Copia de Seguridad',
            icono: Icons.save_outlined,
            children: [
              const Text(
                'Guardá un respaldo de todos tus datos (productos, ventas, clientes) o restauralos si cambiaste de celular.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportarDatos,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Exportar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _importarDatos,
                      icon: const Icon(Icons.download),
                      label: const Text('Importar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.redAccent, width: 0.5), // Un sutil borde rojo para que sepan que es delicado
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ------------------------------------------

          const SizedBox(height: 16),
          _seccion(
            titulo: 'Restaurar',
            icono: Icons.restore,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmarRestaurar,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restaurar valores por defecto'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Soporte',
            icono: Icons.headset_mic_outlined,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _abrirWhatsapp,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contactar por WhatsApp'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Acerca de',
            icono: Icons.info_outline,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _mostrarAcercaDe,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Ver información de la app'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _seccion({required String titulo, required IconData icono, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icono, color: PersonalizacionService.instance.colorPrimario), const SizedBox(width: 12), Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
