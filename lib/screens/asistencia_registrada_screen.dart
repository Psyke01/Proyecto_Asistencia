import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/materia.dart';
import '../models/registro_asistencia.dart';
import '../models/usuario.dart';
import '../widgets/geocheck_ui.dart';

/// Pantalla final del registro: confirma la asistencia y muestra el comprobante oficial.
class AsistenciaRegistradaScreen extends StatelessWidget {
  final Usuario usuario;
  final Materia materia;
  final RegistroAsistencia registro;
  final ValueChanged<int>? alIrAPestana;

  const AsistenciaRegistradaScreen({
    super.key,
    required this.usuario,
    required this.materia,
    required this.registro,
    this.alIrAPestana,
  });

  /// Cierra todo el flujo y abre la pestaña indicada de StudentHomeScreen
  void _irAPestana(BuildContext context, int indice) {
    Navigator.popUntil(context, (ruta) => ruta.isFirst);
    alIrAPestana?.call(indice);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _irAPestana(context, 0);
      },
      child: Scaffold(
        backgroundColor: GeoColores.fondo,
        appBar: GeoCheckAppBar(
          titulo: 'Asistencia',
          nombreUsuario: usuario.nombre,
          mostrarAtras: false,
          insignia: const InsigniaGeo(
            texto: '● GPS Activo',
            fondo: GeoColores.lavanda,
            color: GeoColores.verdeOscuro,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _encabezado(),
                const SizedBox(height: 20),
                _tarjetaTelemetria(),
                const SizedBox(height: 16),
                _comprobante(context),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _irAPestana(context, 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GeoColores.azulProfundo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.school, color: Colors.white),
                    label: const Text(
                      'Volver a Mis Cursos',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: TextButton.icon(
                    onPressed: () => _irAPestana(context, 2),
                    style: TextButton.styleFrom(
                      backgroundColor: GeoColores.lavanda,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.history, color: GeoColores.azulProfundo),
                    label: const Text(
                      'Ver Historial de Asistencias',
                      style: TextStyle(color: GeoColores.azulProfundo, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BarraInferiorEstudiante(
          indiceActual: 2,
          alSeleccionar: (i) => _irAPestana(context, i),
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: GeoColores.menta, shape: BoxShape.circle),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: GeoColores.verdeOscuro, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const InsigniaGeo(texto: 'VERIFICACIÓN COMPLETADA', fondo: GeoColores.menta),
        const SizedBox(height: 10),
        const Text(
          '¡Asistencia Registrada!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: GeoColores.azulProfundo),
        ),
        const SizedBox(height: 4),
        Text(
          'Los 4 factores de presencia física han sido certificados con éxito.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _tarjetaTelemetria() {
    return TarjetaGeo(
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user, color: GeoColores.verdeOscuro, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Telemetría Multifactorial',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: GeoColores.primario),
                ),
              ),
              InsigniaGeo(texto: '4/4 Válidos', fondo: GeoColores.menta),
            ],
          ),
          const SizedBox(height: 12),
          _factor(Icons.qr_code_2, 'Objeto físico detectado', '${registro.objetoValidacion} reconocido.'),
          _factor(Icons.near_me, 'Doble validación GPS',
              'Dentro de ${registro.salon} (a ${registro.distanciaMetros.toStringAsFixed(1)}m).'),
          _factor(Icons.schedule, 'Estado de clase', 'Activa y dentro del horario reglamentario'),
          _factor(Icons.shield, 'Autenticidad de cámara', 'Captura en tiempo real sin manipulaciones'),
        ],
      ),
    );
  }

  Widget _factor(IconData icono, String titulo, String detalle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: GeoColores.lavandaFondo, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: GeoColores.menta, shape: BoxShape.circle),
            child: Icon(icono, size: 16, color: GeoColores.verdeOscuro),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(detalle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comprobante(BuildContext context) {
    final codigoEstudiante =
        usuario.codigoMatricula.isNotEmpty ? usuario.codigoMatricula : 'Sin código';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Encabezado azul
          Container(
            color: GeoColores.azulProfundo,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'COMPROBANTE OFICIAL',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                  ),
                ),
                InsigniaGeo(
                  texto: '● CONFIRMADO',
                  color: Colors.white,
                  fondo: Colors.white.withValues(alpha: 0.15),
                  tamano: 10,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _dato('ESTUDIANTE', usuario.nombre, sub: codigoEstudiante, grande: true)),
                    Expanded(
                      child: _dato('CURSO', registro.materiaNombre,
                          sub: registro.materiaCodigo, grande: true, derecha: true),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _dato('Docente', registro.docente.isNotEmpty ? registro.docente : 'No asignado')),
                    Expanded(child: _dato('Ubicación', registro.salon)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _dato('Fecha y Hora', formatearFecha(registro.fecha),
                          sub: formatearHora(registro.fecha, conSegundos: true)),
                    ),
                    Expanded(child: _dato('Objeto de Validación', registro.objetoValidacion)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: GeoColores.lavanda, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.key, color: GeoColores.azulProfundo, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CÓDIGO CRIPTOGRÁFICO',
                                style: TextStyle(fontSize: 10, color: Colors.grey[700], letterSpacing: 0.4)),
                            const SizedBox(height: 2),
                            Text(
                              registro.codigoCriptografico,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                                color: GeoColores.azulProfundo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: GeoColores.primario),
                          tooltip: 'Copiar código',
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: registro.codigoCriptografico));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Código copiado al portapapeles.')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, String valor, {String? sub, bool grande = false, bool derecha = false}) {
    return Column(
      crossAxisAlignment: derecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(fontSize: grande ? 11 : 12, color: Colors.grey[600], letterSpacing: grande ? 0.4 : 0),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          textAlign: derecha ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: grande ? 18 : 14,
            fontWeight: grande ? FontWeight.w600 : FontWeight.bold,
            color: GeoColores.primario,
          ),
        ),
        if (sub != null)
          Text(
            sub,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: grande && derecha ? GeoColores.verdeOscuro : GeoColores.primario,
            ),
          ),
      ],
    );
  }
}
