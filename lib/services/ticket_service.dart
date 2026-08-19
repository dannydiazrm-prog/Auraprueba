import '../widgets/responsive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'personalizacion_service.dart';

class TicketService {
  static Future<void> imprimirA4({
    required Map<String, dynamic> venta,
    required Map<String, dynamic> ajustes,
  }) async {
    final pdf = pw.Document();
    final tieneFactura = ajustes['timbrado'] != null &&
        ajustes['timbrado'].toString().trim().isNotEmpty;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header empresa
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    PersonalizacionService.instance.nombreComercio,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (ajustes['direccion'] != null &&
                      ajustes['direccion'].toString().isNotEmpty)
                    pw.Text(ajustes['direccion'],
                        style: const pw.TextStyle(fontSize: 11)),
                  if (ajustes['telefono'] != null &&
                      ajustes['telefono'].toString().isNotEmpty)
                    pw.Text('Tel: ${ajustes['telefono']}',
                        style: const pw.TextStyle(fontSize: 11)),
                  if (ajustes['ruc'] != null &&
                      ajustes['ruc'].toString().isNotEmpty)
                    pw.Text('RUC: ${ajustes['ruc']}',
                        style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Título comprobante o factura
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    tieneFactura ? 'FACTURA' : 'COMPROBANTE DE VENTA',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (tieneFactura) ...[
                    pw.Text('Timbrado: ${ajustes['timbrado']}',
                        style: const pw.TextStyle(fontSize: 11)),
                    if (ajustes['nroFactura'] != null &&
                        ajustes['nroFactura'].toString().isNotEmpty)
                      pw.Text('Nº: ${ajustes['nroFactura']}',
                          style: const pw.TextStyle(fontSize: 11)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Datos cliente y fecha
            _filaDato('Fecha:', _formatearFecha(venta['fecha'])),
            _filaDato('Cliente:', venta['clienteNombre'] ?? ''),
            _filaDato('RUC/CI:', venta['clienteRucCi'] ?? ''),
            _filaDato('Condición:', venta['condicion'] ?? ''),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Items
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _celdaHeader('Descripción'),
                    _celdaHeader('Cant.'),
                    _celdaHeader('P. Unit.'),
                    _celdaHeader('Subtotal'),
                  ],
                ),
                ...(venta['items'] as List<dynamic>).map((item) => pw.TableRow(
                      children: [
                        _celda(item['nombre'] ?? ''),
                        _celda('${item['cantidad']}'),
                        _celda(
                            'Gs. ${formatGs((item['precioUnitario'] ?? 0).toDouble())}'),
                        _celda(
                            'Gs. ${formatGs((item['subtotal'] ?? 0).toDouble())}'),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // Totales
            if (tieneFactura) ...[
              _filaTotal('Subtotal:',
                  'Gs. ${formatGs((venta['subtotal'] ?? 0).toDouble())}'),
              _filaTotal('IVA 10%:',
                  'Gs. ${formatGs((venta['iva10'] ?? 0).toDouble())}'),
            ],
            _filaTotalNegrita(
                'TOTAL:', 'Gs. ${formatGs((venta['total'] ?? 0).toDouble())}'),
            pw.SizedBox(height: 4),
            _filaTotal('Pagó:',
                'Gs. ${formatGs((venta['montoPagado'] ?? 0).toDouble())}'),
            _filaTotal('Vuelto:',
                'Gs. ${formatGs((venta['vuelto'] ?? 0).toDouble())}'),
            pw.SizedBox(height: 16),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                '¡Gracias por su compra!',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (!tieneFactura) ...[
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Este comprobante no tiene validez fiscal.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static Future<void> imprimirTicket({
    required Map<String, dynamic> venta,
    required Map<String, dynamic> ajustes,
  }) async {
    final pdf = pw.Document();
    final tieneFactura = ajustes['timbrado'] != null &&
        ajustes['timbrado'].toString().trim().isNotEmpty;

    const double anchoTicket = 80 * PdfPageFormat.mm;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(anchoTicket, double.infinity,
            marginAll: 6 * PdfPageFormat.mm),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              PersonalizacionService.instance.nombreComercio,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            if (ajustes['direccion'] != null &&
                ajustes['direccion'].toString().isNotEmpty)
              pw.Text(ajustes['direccion'],
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center),
            if (ajustes['telefono'] != null &&
                ajustes['telefono'].toString().isNotEmpty)
              pw.Text('Tel: ${ajustes['telefono']}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center),
            if (ajustes['ruc'] != null && ajustes['ruc'].toString().isNotEmpty)
              pw.Text('RUC: ${ajustes['ruc']}',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 6),
            pw.Text(
              tieneFactura ? 'FACTURA' : 'COMPROBANTE DE VENTA',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            if (tieneFactura) ...[
              pw.Text('Timbrado: ${ajustes['timbrado']}',
                  style: const pw.TextStyle(fontSize: 9)),
              if (ajustes['nroFactura'] != null &&
                  ajustes['nroFactura'].toString().isNotEmpty)
                pw.Text('Nº: ${ajustes['nroFactura']}',
                    style: const pw.TextStyle(fontSize: 9)),
            ],
            pw.SizedBox(height: 4),
            _ticketFila('Fecha:', _formatearFecha(venta['fecha'])),
            _ticketFila('Cliente:', venta['clienteNombre'] ?? ''),
            _ticketFila('RUC/CI:', venta['clienteRucCi'] ?? ''),
            pw.Text('--------------------------------',
                style: const pw.TextStyle(fontSize: 9)),
            ...(venta['items'] as List<dynamic>).map((item) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item['nombre'] ?? '',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                            '  ${item['cantidad']} x Gs. ${formatGs((item['precioUnitario'] ?? 0).toDouble())}',
                            style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(
                            'Gs. ${formatGs((item['subtotal'] ?? 0).toDouble())}',
                            style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                )),
            pw.Text('--------------------------------',
                style: const pw.TextStyle(fontSize: 9)),
            if (tieneFactura) ...[
              _ticketFila('Subtotal:',
                  'Gs. ${formatGs((venta['subtotal'] ?? 0).toDouble())}'),
              _ticketFila('IVA 10%:',
                  'Gs. ${formatGs((venta['iva10'] ?? 0).toDouble())}'),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL:',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.Text('Gs. ${formatGs((venta['total'] ?? 0).toDouble())}',
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            _ticketFila('Pagó:',
                'Gs. ${formatGs((venta['montoPagado'] ?? 0).toDouble())}'),
            _ticketFila('Vuelto:',
                'Gs. ${formatGs((venta['vuelto'] ?? 0).toDouble())}'),
            pw.SizedBox(height: 6),
            pw.Text(
              '¡Gracias por su compra!',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            if (!tieneFactura) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Este comprobante no tiene validez fiscal.',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static String _formatearFecha(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fechaStr;
    }
  }

  static pw.Widget _filaDato(String label, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 8),
          pw.Text(valor, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _filaTotal(String label, String valor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(valor, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _filaTotalNegrita(String label, String valor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Text(valor,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _ticketFila(String label, String valor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(valor, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _celdaHeader(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(texto,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _celda(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(texto, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
