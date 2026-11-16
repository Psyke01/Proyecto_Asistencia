import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/materia.dart';
import '../models/usuario.dart';
import '../services/asistencia_service.dart';
import '../widgets/geocheck_ui.dart';
import 'captura_qr_screen.dart';

/// Paso 1 de 2 del registro de asistencia del Estudiante.
/// Radar GPS: verifica en tiempo real que el estudiante esté dentro de la geocerca del aula,
/// sin ubicación simulada y dentro de la ventana de registro.
class RadarActivoScreen extends StatefulWidget {
  final Usuario usuario;
  final Materia materia;
  final ValueChanged<int>? alIrAPestana; // Para volver a una pestaña de StudentHomeScreen

  const RadarActivoScreen({
    super.key,
    required this.usuario,
    required this.materia,
    this.alIrAPestana,
  });

  @override
  State<RadarActivoScreen> createState() => _RadarActivoScreenState();
}

class _RadarActivoScreenState extends State<RadarActivoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso;
  final DateTime _inicioFlujo = DateTime.now();

  StreamSubscription<Position>? _suscripcionGps;
  Timer? _relojVentana;

  bool _cargando = true;
  String? _error;
  bool _yaRegistrado = false;

  Position? _posicion;
  double? _distancia;
  double? _centroLat;
  double? _centroLng;
  bool _geocercaDePrueba = false;

  Materia get _materia => widget.materia;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Re-evalúa la ventana de registro cada 15 segundos
    _relojVentana = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
    _iniciarRadar();
  }

  @override
  void dispose() {
    _pulso.dispose();
    _suscripcionGps?.cancel();
    _relojVentana?.cancel();
    super.dispose();
  }

  Future<void> _iniciarRadar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final errorPermiso = await AsistenciaService.verificarPermisosUbicacion();
    if (!mounted) return;
    if (errorPermiso != null) {
      setState(() {
        _cargando = false;
        _error = errorPermiso;
      });
      return;
    }

    if (_materia.tieneGeocerca) {
      _centroLat = _materia.latitud;
      _centroLng = _materia.longitud;
    } else if (!AsistenciaService.permitirGeocercaDePrueba) {
      setState(() {
        _cargando = false;
        _error = 'El docente aún no ha calibrado la geocerca de ${_materia.salon}.';
      });
      return;
    }

    try {
      _yaRegistrado = await AsistenciaService.yaRegistroHoy(widget.usuario.uid, _materia.id);
    } catch (e) {
      debugPrint('No se pudo verificar registros previos: $e');
    }

    await _suscripcionGps?.cancel();
    _suscripcionGps = AsistenciaService.escucharPosicion().listen(
      (pos) {
        if (!mounted) return;
        // Sin geocerca calibrada (solo en debug): la primera lectura se toma como centro del aula
        if (_centroLat == null || _centroLng == null) {
          _centroLat = pos.latitude;
          _centroLng = pos.longitude;
          _geocercaDePrueba = true;
        }
        setState(() {
          _cargando = false;
          _posicion = pos;
          _distancia = AsistenciaService.distanciaEntre(pos, _centroLat!, _centroLng!);
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _error = 'No fue posible obtener tu ubicación: $e';
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Condiciones de validación
  // ---------------------------------------------------------------------------

  DateTime get _horaLimite => AsistenciaService.horaLimiteRegistro(_materia, _inicioFlujo);
  bool get _ventanaVigente => DateTime.now().isBefore(_horaLimite);
  bool get _sinSimulador => _posicion != null && !_posicion!.isMocked;
  bool get _dentroDelRadio => _distancia != null && _distancia! <= _materia.radioGeocerca;
  bool get _precisionSuficiente =>
      _posicion != null && _posicion!.accuracy <= _materia.radioGeocerca;

  bool get _puedeContinuar =>
      _error == null &&
      !_yaRegistrado &&
      _materia.enCurso &&
      _ventanaVigente &&
      _sinSimulador &&
      _dentroDelRadio &&
      _precisionSuficiente;

  void _continuar() {
    if (!_puedeContinuar) return;
    final token = AsistenciaService.generarToken(
      uid: widget.usuario.uid,
      materiaId: _materia.id,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturaQrScreen(
          usuario: widget.usuario,
          materia: _materia,
          token: token,
          centroLat: _centroLat!,
          centroLng: _centroLng!,
          alIrAPestana: widget.alIrAPestana,
        ),
      ),
    );
  }

  void _mostrarRestricciones() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restricciones activas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GeoColores.primario),
            ),
            const SizedBox(height: 14),
            _itemRestriccion(
              Icons.radar,
              'Radio máximo de ${_materia.radioGeocerca.toStringAsFixed(0)}m',
              'Fuera de este perímetro alrededor de ${_materia.salon} el registro se bloquea.',
            ),
            const SizedBox(height: 12),
            _itemRestriccion(
              Icons.gps_off,
              'Bloqueo de ubicación simulada',
              'Si se detecta Mock GPS o una app de spoofing, el intento queda registrado y se rechaza.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRestriccion(IconData icono, String titulo, String detalle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: GeoColores.rojoSuave, borderRadius: BorderRadius.circular(10)),
          child: Icon(icono, size: 18, color: Colors.red[700]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(detalle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoColores.fondo,
      appBar: GeoCheckAppBar(titulo: 'Radar Activo', nombreUsuario: widget.usuario.nombre),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IndicadorPasos(pasoActual: 1, conEtiquetas: true),
              const SizedBox(height: 16),
              _tarjetaSesion(),
              const SizedBox(height: 16),
              _tarjetaRadar(),
              const SizedBox(height: 16),
              _tarjetaEstado(),
              const SizedBox(height: 16),
              _tarjetaRestriccion(),
              const SizedBox(height: 16),
              _tarjetaTelemetria(),
              const SizedBox(height: 16),
              _preguntaFueraDelAula(),
              const SizedBox(height: 24),
              _botonContinuar(),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Paso 1 de 2 • Validación de presencia GPS',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Sesión en curso
  Widget _tarjetaSesion() {
    return TarjetaGeo(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: GeoColores.lavanda, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.terminal, color: GeoColores.azulProfundo, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESIÓN EN CURSO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_materia.nombre} · ${_materia.salon}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: GeoColores.primario),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _materia.enCurso
              ? const InsigniaGeo(texto: 'En horario', fondo: GeoColores.menta)
              : InsigniaGeo(texto: 'Sin clase activa', color: Colors.grey[700]!, fondo: GeoColores.lavanda),
        ],
      ),
    );
  }

  /// 2. Radar con anillos concéntricos animados
  Widget _tarjetaRadar() {
    final Color colorCentro;
    if (_posicion == null) {
      colorCentro = Colors.grey[300]!;
    } else if (_dentroDelRadio && _sinSimulador) {
      colorCentro = GeoColores.menta;
    } else {
      colorCentro = const Color(0xFFFCA5A5);
    }

    final precision = _posicion?.accuracy;

    return TarjetaGeo(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: 230,
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulso exterior
                AnimatedBuilder(
                  animation: _pulso,
                  builder: (context, _) {
                    final t = _pulso.value;
                    return Container(
                      width: 170 + 60 * t,
                      height: 170 + 60 * t,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GeoColores.lavanda.withValues(alpha: 1 - t),
                      ),
                    );
                  },
                ),
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: GeoColores.lavandaFondo),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: GeoColores.lavanda),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colorCentro),
                  child: _cargando
                      ? const Padding(
                          padding: EdgeInsets.all(26),
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: GeoColores.verdeOscuro),
                        )
                      : const Icon(Icons.person_pin_circle, color: GeoColores.verdeOscuro, size: 34),
                ),
                // Insignia satelital
                Positioned(
                  top: 22,
                  right: 22,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: GeoColores.azulProfundo, shape: BoxShape.circle),
                    child: const Icon(Icons.satellite_alt, color: Colors.white, size: 16),
                  ),
                ),
                // Etiqueta del radio
                Positioned(
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4)],
                    ),
                    child: Text(
                      'Radio: ${_materia.radioGeocerca.toStringAsFixed(0)}m',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_distancia != null)
            InsigniaGeo(
              texto: 'A ${_distancia!.toStringAsFixed(0)} metros del centro del aula',
              icono: Icons.near_me_outlined,
              color: _dentroDelRadio ? GeoColores.verdeOscuro : Colors.red[700]!,
              fondo: _dentroDelRadio ? GeoColores.mentaSuave : GeoColores.rojoSuave,
              tamano: 12,
            )
          else
            InsigniaGeo(
              texto: _error != null ? 'Ubicación no disponible' : 'Buscando señal satelital...',
              icono: Icons.satellite_alt_outlined,
              color: Colors.grey[700]!,
              fondo: GeoColores.lavanda,
              tamano: 12,
            ),
          const SizedBox(height: 8),
          if (precision != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gps_fixed, size: 14, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text('Precisión GPS: ', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                Text(
                  '±${precision.toStringAsFixed(0)}m (${AsistenciaService.calidadSenal(precision)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          if (_geocercaDePrueba) ...[
            const SizedBox(height: 8),
            Text(
              'Modo prueba: geocerca centrada en tu primera lectura GPS',
              style: TextStyle(fontSize: 10, color: Colors.orange[800]),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Estado de la validación (válida / fuera del área / error)
  Widget _tarjetaEstado() {
    IconData icono;
    String titulo;
    String detalle;
    Color fondo;
    Color colorTexto = Colors.white;

    if (_error != null) {
      icono = Icons.location_off_outlined;
      titulo = 'No se pudo validar tu ubicación';
      detalle = _error!;
      fondo = Colors.red[700]!;
    } else if (_yaRegistrado) {
      icono = Icons.event_available;
      titulo = 'Asistencia ya registrada hoy';
      detalle = 'Ya existe un registro tuyo en ${_materia.nombre} para la fecha de hoy.';
      fondo = GeoColores.azulBoton;
    } else if (_posicion == null) {
      icono = Icons.satellite_alt_outlined;
      titulo = 'Obteniendo ubicación...';
      detalle = 'Mantén el teléfono desbloqueado y con el GPS activo.';
      fondo = GeoColores.lavanda;
      colorTexto = GeoColores.primario;
    } else if (!_sinSimulador) {
      icono = Icons.gpp_bad_outlined;
      titulo = 'Ubicación simulada detectada';
      detalle = 'Desactiva cualquier proveedor de Mock GPS para poder registrar asistencia.';
      fondo = Colors.red[700]!;
    } else if (!_dentroDelRadio) {
      icono = Icons.wrong_location_outlined;
      titulo = 'Estás fuera del área autorizada';
      detalle = 'Acércate a ${_materia.salon}. Debes estar a menos de ${_materia.radioGeocerca.toStringAsFixed(0)}m del centro.';
      fondo = Colors.red[700]!;
    } else if (!_precisionSuficiente) {
      icono = Icons.gps_not_fixed;
      titulo = 'Señal GPS insuficiente';
      detalle = 'Tu precisión actual es baja. Acércate a una ventana o espera unos segundos.';
      fondo = Colors.orange[800]!;
    } else if (!_ventanaVigente) {
      icono = Icons.timer_off_outlined;
      titulo = 'Ventana de registro cerrada';
      detalle = 'El tiempo para registrar asistencia terminó a las ${formatearHora(_horaLimite)}.';
      fondo = Colors.orange[800]!;
    } else if (!_materia.enCurso) {
      icono = Icons.event_busy_outlined;
      titulo = 'La clase no está activa';
      detalle = 'El docente aún no ha iniciado la sesión de ${_materia.nombre}.';
      fondo = Colors.orange[800]!;
    } else {
      icono = Icons.check_circle_outline;
      titulo = 'Ubicación válida y confirmada';
      detalle = 'Te encuentras físicamente dentro del área autorizada del ${_materia.salon}.';
      fondo = GeoColores.verdeOscuro;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorTexto.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: colorTexto, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(color: colorTexto, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(detalle, style: TextStyle(color: colorTexto.withValues(alpha: 0.9), fontSize: 13)),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (_error!.contains('ajustes')) {
                        await Geolocator.openAppSettings();
                      } else if (_error!.contains('desactivado')) {
                        await Geolocator.openLocationSettings();
                      }
                      _iniciarRadar();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Restricción preventiva antifraude
  Widget _tarjetaRestriccion() {
    final distanciaTexto = _distancia != null ? '${_distancia!.toStringAsFixed(0)}m del centro' : 'midiendo distancia';
    final radio = _materia.radioGeocerca.toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GeoColores.lavanda,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3F8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(color: GeoColores.rojoSuave, shape: BoxShape.circle),
            child: Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESTRICCIÓN PREVENTIVA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.red[700]),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[800], height: 1.4),
                    children: [
                      const TextSpan(text: 'Estás a '),
                      TextSpan(text: distanciaTexto, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                        text: ' (radio permitido de ${radio}m). Si te alejas a más de ${radio}m o activas '
                            'proveedores de ubicación simulada (Mock GPS), el registro quedará '
                            'inmediatamente bloqueado por protocolo antifraude institucional.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _mostrarRestricciones,
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: GeoColores.azulProfundo),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ver detalles de restricciones (2 activas)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GeoColores.azulProfundo),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: GeoColores.azulProfundo),
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

  /// 5. Condiciones de telemetría segura
  Widget _tarjetaTelemetria() {
    return TarjetaGeo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, size: 20, color: GeoColores.primario),
              SizedBox(width: 8),
              Text(
                'Condiciones de Telemetría Segura',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: GeoColores.primario),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _filaCondicion(
            Icons.verified_outlined,
            _posicion == null
                ? 'Analizando proveedor de ubicación'
                : _sinSimulador
                    ? 'Sin simuladores ni spoofing detectado'
                    : 'Ubicación simulada detectada',
            _posicion == null
                ? const InsigniaGeo(texto: '...', color: Colors.grey, fondo: GeoColores.lavanda)
                : _sinSimulador
                    ? const InsigniaGeo(texto: 'Óptimo', fondo: GeoColores.menta)
                    : InsigniaGeo(texto: 'Bloqueado', color: Colors.red[700]!, fondo: GeoColores.rojoSuave),
          ),
          const SizedBox(height: 12),
          _filaCondicion(
            Icons.schedule,
            _ventanaVigente ? 'Ventana de registro vigente' : 'Ventana de registro cerrada',
            Text(
              formatearHora(_horaLimite),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _ventanaVigente ? GeoColores.primario : Colors.red[700],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _filaCondicion(
            Icons.badge_outlined,
            'Estudiante matriculado en este grupo',
            const InsigniaGeo(texto: 'Activo', fondo: GeoColores.menta),
          ),
        ],
      ),
    );
  }

  Widget _filaCondicion(IconData icono, String texto, Widget estado) {
    return Row(
      children: [
        Icon(icono, size: 18, color: GeoColores.verdeOscuro),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        estado,
      ],
    );
  }

  /// 6. Pregunta frecuente desplegable
  Widget _preguntaFueraDelAula() {
    return Container(
      decoration: BoxDecoration(color: GeoColores.lavandaFondo, borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.help_outline, color: Colors.grey[700]),
          title: const Text(
            '¿Qué ocurre si estuvieras fuera del aula?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'El botón para continuar se deshabilita y no podrás escanear el QR del docente. '
              'Si sales del radio durante el proceso, la validación GPS '
              'rechazará el registro. Acércate al ${_materia.salon} y el radar se actualizará '
              'automáticamente.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[800], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonContinuar() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _puedeContinuar ? _continuar : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: GeoColores.azulProfundo,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CONTINUAR A ESCANEAR QR',
              style: TextStyle(
                color: _puedeContinuar ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.qr_code_2, color: _puedeContinuar ? Colors.white : Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
