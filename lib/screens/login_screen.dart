import '../widgets/responsive.dart';
import 'package:flutter/material.dart';
import '../services/personalizacion_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onActivado;
  const LoginScreen({super.key, required this.onActivado});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

    void _validarCodigo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    final codigo = _codigoCtrl.text.trim();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('codigos_activacion')
          .doc(codigo);
      final doc = await docRef.get().timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        setState(() => _error = 'Código inválido');
        return;
      }

      final data = doc.data()!;
      final bool usado = data['usado'] ?? false;
      final Timestamp? expiraTimestamp = data['creado_en'];

      if (usado) {
        setState(() => _error = 'Este código ya fue utilizado');
        return;
      }

      if (expiraTimestamp == null) {
        setState(() => _error = 'Código inválido');
        return;
      }

      final DateTime expira = expiraTimestamp.toDate();
      if (DateTime.now().isAfter(expira)) {
        setState(() => _error = 'Este código ya expiró');
        return;
      }

      await docRef.update({'usado': true}).timeout(const Duration(seconds: 10));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_activada', true);

      if (!mounted) return;
      widget.onActivado();

   } catch (e) {
      setState(() => _error = 'Sin conexión a internet. Verifica tu WiFi/datos e intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2744),
      body: Center(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/IMG-20260228-WA0018.jpg',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aura Estándar',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2744),
                    ),
                  ),
                  const Text(
                    'Ingresa tu código de activación',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 32),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _codigoCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: 'Código de 4 dígitos',
                      prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF1E88E5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa el código';
                      if (v.trim().length != 4) return 'El código debe tener 4 dígitos';
                      return null;
                    },
                    onFieldSubmitted: (_) => _validarCodigo(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PersonalizacionService.instance.colorPrimario,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _cargando ? null : _validarCodigo,
                      child: _cargando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'ACTIVAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
