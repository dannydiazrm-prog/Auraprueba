import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalizacionService extends ChangeNotifier {
  static final PersonalizacionService instance = PersonalizacionService._();
  PersonalizacionService._();

  String nombreComercio = 'Aura Estándar';
  Color colorPrimario = const Color(0xFF29B6F6);
  String? logoPath;

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    nombreComercio = prefs.getString('nombre_comercio') ?? 'Aura Estándar';
    final colorGuardado = prefs.getInt('color_primario');
    colorPrimario =
        colorGuardado != null ? Color(colorGuardado) : const Color(0xFF29B6F6);
    logoPath = prefs.getString('logo_path');
    notifyListeners();
  }

  Future<void> guardarNombre(String nombre) async {
    nombreComercio = nombre;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre_comercio', nombre);
    notifyListeners();
  }

    Future<void> guardarColor(Color color) async {
    colorPrimario = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('color_primario', color.value);
    notifyListeners();
  }


  Future<void> guardarLogoPath(String path) async {
    logoPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logo_path', path);
    notifyListeners();
  }
  
  Color colorTextoPara(Color color) {
    return color.computeLuminance() > 0.6
        ? const Color(0xFF1A2744)
        : Colors.white;
  }

  Color get colorTexto => colorTextoPara(colorPrimario);
  
  Future<void> restaurarValoresPorDefecto() async {
    nombreComercio = 'Aura Estándar';
    colorPrimario = const Color(0xFF29B6F6);
    logoPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nombre_comercio');
    await prefs.remove('color_primario');
    await prefs.remove('logo_path');
    notifyListeners();
  }
}