import 'package:flutter/material.dart';

Widget pageHeader(String titulo, BuildContext context, {Widget? trailing}) {
  final now = DateTime.now();
  final fecha = '${now.day}/${now.month}/${now.year}';
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Hoy: $fecha', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2744),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ],
    ),
  );
}
