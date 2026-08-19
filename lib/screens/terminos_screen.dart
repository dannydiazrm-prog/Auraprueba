import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/personalizacion_service.dart';

class TerminosScreen extends StatefulWidget {
  final VoidCallback onAceptado;

  const TerminosScreen({super.key, required this.onAceptado});

  @override
  State<TerminosScreen> createState() => _TerminosScreenState();
}

class _TerminosScreenState extends State<TerminosScreen> {
  bool _aceptaTerminos = false;

  Future<void> _aceptar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terminos_aceptados', true);
    
    if (!mounted) return;
    widget.onAceptado();
  }

  void _rechazar() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = PersonalizacionService.instance.colorPrimario;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              width: double.infinity,
              color: colorPrimario.withOpacity(0.1),
              child: Column(
                children: [
                  Icon(Icons.gavel_rounded, size: 48, color: colorPrimario),
                  const SizedBox(height: 12),
                  const Text(
                    'Términos y Condiciones',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Por favor lee atentamente antes de continuar.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: const Text(
                    '''TÉRMINOS Y CONDICIONES DE USO

Bienvenido a Aura Estandar (en adelante , "La aplicacion"). Antes de utilizar la Aplicación, lea detenidamente los presentes Términos y Condiciones de Uso (en adelante, "Términos"). Al descargar, instalar o utilizar la Aplicación, usted acepta de forma expresa, automática y sin reservas todos los puntos aquí establecidos. Si no está de acuerdo con estos Términos, deberá abstenerse de instalar y utilizar la Aplicación.

1. OBLIGACIÓN DE LECTURA DE INSTRUCCIONES Y USO CORRECTO
El usuario se compromete y obliga a leer atentamente todas las instrucciones, guías, etiquetas, herramientas de ayuda y pantallas informativas integradas dentro de la Aplicación antes de proceder a su uso operativo o al registro de transacciones. 
La Aplicación es una herramienta de asistencia técnica y automatización matemática; su correcto funcionamiento depende directamente de que el usuario introduzca datos precisos y comprenda el flujo de la interfaz (como filtros de fechas, tipos de movimientos, egresos y balances). El desarrollador no se hace responsable de errores derivados de una mala interpretación del funcionamiento del software.

2. RESPONSABILIDAD EXCLUSIVA DEL USUARIO
Una vez adquirida, descargada o instalada la Aplicación, el usuario asume la total y exclusiva responsabilidad en todos los ámbitos derivados de su uso, incluyendo de forma enunciativa pero no limitativa:
• Ámbito Financiero y Comercial: El usuario es el único responsable de las decisiones financieras, comerciales, de precios, de reposición de stock, retiros de dinero o inyecciones de capital que realice en su negocio real. La Aplicación actúa únicamente como un registro informativo y matemático.
• Ámbito Legal y Fiscal: El registro de ventas, costos, servicios y egresos dentro de la Aplicación se realiza con fines organizativos privados. Es responsabilidad exclusiva del usuario cumplir con las normativas tributarias, fiscales, de facturación y legales vigentes en su respectiva jurisdicción o país.
• Uso del Dispositivo: El usuario es responsable de mantener la seguridad de su dispositivo móvil, claves de acceso y de asegurar que terceros no autorizados manipulen sus registros financieros.

3. RIESGO DE PÉRDIDA DE DATOS Y ALMACENAMIENTO LOCAL
La Aplicación procesa, gestiona y almacena la información financiera de manera estrictamente local en el dispositivo del usuario. 
• El desarrollador no realiza copias de seguridad automáticas en la nube, ni almacena la información del usuario en servidores externos, garantizando así la privacidad absoluta de sus números.
• Como consecuencia directa de هذا modelo de almacenamiento, existe un riesgo inherente de pérdida total e irreversible de datos en casos de: avería, daño o robo del dispositivo móvil; restauración de fábrica del sistema operativo; desinstalación voluntaria o involuntaria de la Aplicación; o borrado manual de la caché/datos del sistema por parte del usuario.
• El desarrollador queda completamente exonerado de cualquier responsabilidad por la pérdida de datos, historial de ventas, balances o métricas, siendo obligación del usuario tomar las previsiones o respaldos necesarios si el sistema operativo lo permite.

4. DERECHOS DEL DESARROLLADOR Y PROPIEDAD INTELECTUAL
El desarrollador retiene de forma exclusiva todos los derechos de propiedad intelectual, derechos de autor, marcas, logotipos, interfaces de usuario (UI), diseños visuales, arquitecturas de gráficos y el código fuente completo de la Aplicación.
• Licencia de Uso: Se otorga al usuario una licencia de uso personal, comercial-individual, revocable, no exclusiva y no transferible para utilizar el software conforme a su destino natural.
• Restricciones Estrictas: Queda terminantemente prohibido al usuario, de forma directa o indirecta: copiar, modificar, adaptar, traducir, realizar ingeniería inversa, descompilar, desensamblar o intentar extraer el código fuente o las consultas lógicas de la Aplicación. Cualquier violación a esta cláusula resultará en la revocación inmediata de la licencia de uso y facultará al desarrollador a iniciar las acciones legales correspondientes.
• Actualizaciones: El desarrollador se reserva el derecho de modificar, actualizar, suspender o discontinuar funciones, interfaces o características de la Aplicación en cualquier momento, sin que esto genere derecho a compensación alguna para el usuario.

5. EXCLUSIÓN DE GARANTÍAS Y LIMITACIÓN DE RESPONSABILIDAD
La Aplicación se proporciona "tal cual" y "según disponibilidad", sin garantías de ningún tipo, ya sean expresas o implícitas. El desarrollador no garantiza que la Aplicación sea absolutamente infalible, libre de bugs tipográficos o de redondeo matemático menor, ni que funcione de manera ininterrumpida en todos los modelos de dispositivos móviles del mercado. Bajo ninguna circunstancia el desarrollador será responsable por daños directos, indirectos, incidentales, lucro cesante o pérdidas financieras tangibles o intangibles que el usuario sufra como consecuencia directa o indirecta del uso o la imposibilidad de uso de la Aplicación.

6. MODIFICACIONES A LOS TÉRMINOS
El desarrollador se reserva el derecho de actualizar o modificar estos Términos y Condiciones en cualquier momento. El uso continuado de la Aplicación tras dichas modificaciones constituirá la aceptación de los nuevos Términos.''',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _aceptaTerminos,
                        activeColor: colorPrimario,
                        onChanged: (val) {
                          setState(() {
                            _aceptaTerminos = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'He leído y acepto los términos y condiciones de uso y asumo la responsabilidad sobre mis datos.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rechazar,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('No Acepto'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _aceptaTerminos ? _aceptar : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aceptar y Entrar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
