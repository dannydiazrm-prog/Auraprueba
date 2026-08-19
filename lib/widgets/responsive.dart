import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  static double paddingH(BuildContext context) =>
      isMobile(context) ? 16 : 24;

  static double sidebarWidth(BuildContext context) =>
      isMobile(context) ? 0 : 230;

  static EdgeInsets pagePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.fromLTRB(16, 60, 16, 80);
    }
    return const EdgeInsets.fromLTRB(32, 24, 32, 24);
  }
}

String formatGs(double monto) {
  final String s = monto.toStringAsFixed(0);
  final buffer = StringBuffer();
  final int start = s.length % 3;
  if (start > 0) buffer.write(s.substring(0, start));
  for (int i = start; i < s.length; i += 3) {
    if (buffer.isNotEmpty) buffer.write('.');
    buffer.write(s.substring(i, i + 3));
  }
  return buffer.toString();
}

class MilesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final texto = newValue.text.replaceAll('.', '');
    if (texto.isEmpty) return newValue.copyWith(text: '');
    final numero = int.tryParse(texto);
    if (numero == null) return oldValue;
    final formateado = formatGs(numero.toDouble());
    return newValue.copyWith(
      text: formateado,
      selection: TextSelection.collapsed(offset: formateado.length),
    );
  }
}
