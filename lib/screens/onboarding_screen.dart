import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompletado;
  const OnboardingScreen({super.key, required this.onCompletado});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _tipoSeleccionado; // 'Comercio' o 'Servicios'

  final Map<String, List<String>> _subcategorias = {
    'Comercio': [
      'Supermercado',
      'Restaurante',
      'Tienda de Ropa',
      'Ferretería',
      'Minimarket',
      'Tienda de Electrónica',
      'Farmacia',
      'Librería',
      'Boutique',
      'Bodega',
    ],
    'Servicios': [
      'Peluquería',
      'Veterinaria',
      'Consultorio Médico',
      'Taller Mecánico',
      'Gimnasio',
      'Estudio Contable',
      'Salón de Belleza',
      'Servicios de Limpieza',
      'Consultoría',
      'Reparación de Celulares',
    ],
  };

  Future<void> _guardarYContinuar(String tipo, String sub) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tipo_negocio', tipo);
    await prefs.setString('sub_categoria', sub);
    await prefs.setString('nombre_comercio', sub);

    if (!mounted) return;
    widget.onCompletado();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Bloquea el retroceso hacia la pantalla de Login
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_tipoSeleccionado != null) {
          // Si está en la lista, al retroceder vuelve a las dos tarjetas
          setState(() => _tipoSeleccionado = null);
        }
        // Si está en las dos tarjetas principales, no hace nada (bloqueado)
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A2744),
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Configuración Inicial',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _tipoSeleccionado == null
                        ? 'Selecciona el enfoque principal de tu negocio:'
                        : 'Selecciona tu rubro específico ($_tipoSeleccionado):',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _tipoSeleccionado == null
                          ? _buildTarjetasPrincipales()
                          : _buildListaRubros(),
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

  Widget _buildTarjetasPrincipales() {
    return Column(
      key: const ValueKey(1),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tarjetaOpcion(
          titulo: 'Comercio',
          subtitulo: 'Venta de productos, artículos y mercaderías',
          icono: Icons.storefront,
          color: const Color(0xFF1E88E5),
          onTap: () => setState(() => _tipoSeleccionado = 'Comercio'),
        ),
        const SizedBox(height: 20),
        _tarjetaOpcion(
          titulo: 'Servicios',
          subtitulo: 'Prestación de servicios, atención y agendamiento',
          icono: Icons.design_services,
          color: Colors.teal,
          onTap: () => setState(() => _tipoSeleccionado = 'Servicios'),
        ),
      ],
    );
  }

  Widget _tarjetaOpcion({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, size: 40, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2744),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildListaRubros() {
    final lista = _subcategorias[_tipoSeleccionado] ?? [];
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _tipoSeleccionado = null),
            ),
            const Text(
              'Volver a categorías',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: lista.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rubro = lista[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _guardarYContinuar(_tipoSeleccionado!, rubro),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rubro,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A2744),
                          ),
                        ),
                        const Icon(Icons.check_circle_outline, color: Color(0xFF1E88E5)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
