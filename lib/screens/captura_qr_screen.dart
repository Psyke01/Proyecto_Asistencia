import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/materia.dart';
import '../models/usuario.dart';
import '../services/asistencia_service.dart';
import '../widgets/geocheck_ui.dart';
import 'asistencia_registrada_screen.dart';

/// Paso 2 de 2 del registro de asistencia del Estudiante.
/// Abre la cámara en tiempo real para escanear el QR institucional generado por el docente.
/// Al detectarlo valida: QR del aula del docente + presencia dentro del geofence GPS,
/// y guarda el registro en Firestore.
class CapturaQrScreen extends StatefulWidget {
  final Usuario usuario;
  final Materia materia;
  final TokenSesion token;
  final double centroLat;
  final double centroLng;
  final ValueChanged<int>? alIrAPestana;

  const CapturaQrScreen({
    super.key,
    required this.usuario,
    required this.materia,
    required this.token,
    required this.centroLat,
    required this.centroLng,
    this.alIrAPestana,
  });

  @override
  State<CapturaQrScreen> createState() => _CapturaQrScreenState();
}

class _CapturaQrScreenState extends State<CapturaQrScreen> {
  final MobileScannerController _camara = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _procesando = false;
  bool _linterna = false;
  bool _hayError = false;
  String _estado = 'Apunta al QR del aula generado por el docente';
  DateTime? _ignorarHasta; // Pausa breve tras un error para que el estudiante lea el mensaje

  @override
  void dispose() {
    _camara.dispose();
    super.dispose();
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    setState(() {
      _procesando = false;
      _hayError = true;
      _estado = mensaje;
      _ignorarHasta = DateTime.now().add(const Duration(seconds: 3));
    });
  }

  Future<void> _alDetectar(BarcodeCapture captura) async {
    if (_procesando || captura.barcodes.isEmpty) return;
    if (_ignorarHasta != null && DateTime.now().isBefore(_ignorarHasta!)) return;
    final contenido = captura.barcodes.first.rawValue;

    setState(() {
      _procesando = true;
      _hayError = false;
      _estado = 'QR detectado. Validando código criptográfico...';
    });

    // 1. Token individual de sesión todavía vigente
    if (widget.token.expirado) {
      _mostrarError('La sesión de validación expiró. Regresa al radar para reintentar.');
      return;
    }

    // 2. QR institucional correcto para esta materia
    final errorQr = AsistenciaService.validarQrAula(contenido, widget.materia);
    if (errorQr != null) {
      _mostrarError(errorQr);
      return;
    }

    await _camara.stop();
    if (!mounted) return;
    setState(() => _estado = 'Verificando tu posición en el aula...');

    try {
      // 3. Doble validación GPS: nueva lectura en el momento de la captura
      final posicion = await AsistenciaService.obtenerPosicionActual();
      if (posicion.isMocked) {
        await _reanudar('Ubicación simulada detectada. Registro bloqueado.');
        return;
      }
      final distancia = AsistenciaService.distanciaEntre(posicion, widget.centroLat, widget.centroLng);
      if (distancia > widget.materia.radioGeocerca) {
        await _reanudar(
          'Estás a ${distancia.toStringAsFixed(0)}m del aula. '
          'Debes estar a menos de ${widget.materia.radioGeocerca.toStringAsFixed(0)}m.',
        );
        return;
      }

      // 4. Evita doble registro el mismo día
      if (await AsistenciaService.yaRegistroHoy(widget.usuario.uid, widget.materia.id)) {
        await _reanudar('Ya registraste asistencia hoy en ${widget.materia.nombre}.');
        return;
      }

      if (!mounted) return;
      setState(() => _estado = 'Guardando registro...');

      final registro = await AsistenciaService.registrarAsistencia(
        uid: widget.usuario.uid,
        materia: widget.materia,
        posicion: posicion,
        distancia: distancia,
        token: widget.token,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AsistenciaRegistradaScreen(
            usuario: widget.usuario,
            materia: widget.materia,
            registro: registro,
            alIrAPestana: widget.alIrAPestana,
          ),
        ),
      );
    } catch (e) {
      await _reanudar('No se pudo completar el registro: $e');
    }
  }

  /// Muestra el error y vuelve a encender la cámara para otro intento
  Future<void> _reanudar(String mensaje) async {
    _mostrarError(mensaje);
    try {
      await _camara.start();
    } catch (e) {
      debugPrint('No se pudo reanudar la cámara: $e');
    }
  }

  Future<void> _alternarCamara() async {
    await _camara.switchCamera();
  }

  Future<void> _alternarLinterna() async {
    await _camara.toggleTorch();
    setState(() => _linterna = !_linterna);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeoColores.fondo,
      appBar: GeoCheckAppBar(titulo: 'Detalle de Captura', nombreUsuario: widget.usuario.nombre),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const IndicadorPasos(
                pasoActual: 2,
                accionDerecha: InsigniaGeo(texto: '● Sensor Activo', fondo: GeoColores.menta),
              ),
              const SizedBox(height: 16),
              _visorCamara(),
              const SizedBox(height: 16),
              _panelControles(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _visorCamara() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 460,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _camara, onDetect: _alDetectar),
            // Oscurecido suave para resaltar el marco
            Container(color: Colors.black.withValues(alpha: 0.25)),
            // Marco de escaneo
            Center(
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _hayError ? Colors.redAccent : GeoColores.menta,
                    width: 3,
                  ),
                ),
              ),
            ),
            // Botón cancelar
            Positioned(
              top: 14,
              left: 14,
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Cancelar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Estado de la captura
            Positioned(
              left: 24,
              right: 24,
              bottom: 56,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: _hayError ? const Color(0xFFFFF1F1) : const Color(0xFFEDEEEE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    if (_procesando)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: GeoColores.azulProfundo),
                      )
                    else
                      Icon(
                        _hayError ? Icons.error_outline : Icons.qr_code_scanner,
                        size: 20,
                        color: _hayError ? Colors.red[700] : GeoColores.azulProfundo,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _estado,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _hayError ? Colors.red[800] : GeoColores.primario,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelControles() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: GeoColores.lavandaFondo, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _botonCircular(
                icono: _linterna ? Icons.flash_on : Icons.flash_off,
                etiqueta: 'Linterna',
                alPresionar: _alternarLinterna,
              ),
              _botonCircular(
                icono: Icons.flip_camera_ios_outlined,
                etiqueta: 'Alternar',
                alPresionar: _alternarCamara,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, color: GeoColores.azulProfundo),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Al detectar el QR institucional generado por el docente, el sistema validará tu posición '
                    'GPS y confirmará tu asistencia en tiempo real.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonCircular({
    required IconData icono,
    required String etiqueta,
    required VoidCallback alPresionar,
  }) {
    return Column(
      children: [
        Material(
          color: GeoColores.lavanda,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _procesando ? null : alPresionar,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icono, color: GeoColores.azulProfundo),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(etiqueta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
      ],
    );
  }
}
