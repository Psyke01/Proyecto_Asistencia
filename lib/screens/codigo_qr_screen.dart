import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/materia.dart';
import '../models/usuario.dart';
import '../services/asistencia_service.dart';
import '../widgets/geocheck_ui.dart';
import 'captura_qr_screen.dart';

/// Paso 2 de 3 del registro de asistencia del Estudiante.
/// Genera un código QR individual, firmado e inmutable, con vigencia limitada.
/// Ese token se vincula al registro final junto con la captura del QR del aula.
class CodigoQrScreen extends StatefulWidget {
  final Usuario usuario;
  final Materia materia;
  final Position posicion;
  final double distancia;
  final double centroLat; // Centro de la geocerca usado en el paso 1
  final double centroLng;
  final ValueChanged<int>? alIrAPestana;

  const CodigoQrScreen({
    super.key,
    required this.usuario,
    required this.materia,
    required this.posicion,
    required this.distancia,
    required this.centroLat,
    required this.centroLng,
    this.alIrAPestana,
  });

  @override
  State<CodigoQrScreen> createState() => _CodigoQrScreenState();
}

class _CodigoQrScreenState extends State<CodigoQrScreen> {
  late TokenSesion _token;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _generarToken();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _generarToken() {
    _token = AsistenciaService.generarToken(
      uid: widget.usuario.uid,
      materiaId: widget.materia.id,
    );
  }

  String get _cuentaRegresiva {
    final r = _token.restante;
    final m = r.inMinutes.toString().padLeft(2, '0');
    final s = (r.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _accionPrincipal() {
    if (_token.expirado) {
      setState(_generarToken);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nuevo código individual generado.'), backgroundColor: Colors.green),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturaQrScreen(
          usuario: widget.usuario,
          materia: widget.materia,
          token: _token,
          centroLat: widget.centroLat,
          centroLng: widget.centroLng,
          alIrAPestana: widget.alIrAPestana,
        ),
      ),
    );
  }

  void _cancelarRegistro() {
    Navigator.popUntil(context, (ruta) => ruta.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final expirado = _token.expirado;

    return Scaffold(
      backgroundColor: GeoColores.fondo,
      appBar: GeoCheckAppBar(titulo: 'Código QR', nombreUsuario: widget.usuario.nombre),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const IndicadorPasos(pasoActual: 2),
              const SizedBox(height: 16),
              _tarjetaGeolocalizacion(),
              const SizedBox(height: 20),
              _tarjetaQr(expirado),
              const SizedBox(height: 16),
              _tarjetaProtocolo(expirado),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _accionPrincipal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GeoColores.verdeOscuro,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: Icon(expirado ? Icons.refresh : Icons.photo_camera_outlined, color: Colors.white),
                  label: Text(
                    expirado ? 'GENERAR NUEVO CÓDIGO' : 'INICIAR CAPTURA',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _cancelarRegistro,
                child: Text(
                  'Cancelar registro',
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sesión expira automáticamente si no se inicia la captura antes del límite.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Resumen del paso 1 superado
  Widget _tarjetaGeolocalizacion() {
    return TarjetaGeo(
      color: GeoColores.lavandaFondo,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(color: GeoColores.menta, shape: BoxShape.circle),
            child: const Icon(Icons.location_on_outlined, color: GeoColores.verdeOscuro),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GEOLOCALIZACIÓN EXITOSA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: GeoColores.verdeOscuro),
                ),
                const SizedBox(height: 2),
                Text(
                  '¡Ubicación comprobada en ${widget.materia.salon}!',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: GeoColores.primario),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: GeoColores.lavanda, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Precisión', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GeoColores.azulProfundo)),
                Text(
                  '${widget.posicion.accuracy.toStringAsFixed(1)}m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GeoColores.azulProfundo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta azul con el QR individual
  Widget _tarjetaQr(bool expirado) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2A4A8F), GeoColores.azulProfundo, Color(0xFF1B3A86)],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: const [BoxShadow(color: Color(0x33001E6C), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 9, color: GeoColores.menta),
                    SizedBox(width: 6),
                    Text('Asignado individualmente',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: Color(0xFF9DB4F5)),
                  SizedBox(width: 4),
                  Text('Inmutable',
                      style: TextStyle(color: Color(0xFF9DB4F5), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Código QR
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: QrImageView(
                  data: _token.contenidoQr,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: GeoColores.azulProfundo),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: GeoColores.primario,
                  ),
                ),
              ),
              if (expirado)
                Container(
                  width: 204,
                  height: 204,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_off_outlined, size: 40, color: Colors.orange[800]),
                      const SizedBox(height: 8),
                      Text('Código expirado',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900])),
                      const SizedBox(height: 4),
                      Text('Genera uno nuevo para continuar',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2, color: GeoColores.menta, size: 20),
                const SizedBox(width: 10),
                Text(
                  _token.valor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Protocolo de verificación con la cuenta regresiva del token
  Widget _tarjetaProtocolo(bool expirado) {
    final total = AsistenciaService.vigenciaToken.inSeconds;
    final restante = _token.restante.inSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: GeoColores.lavandaFondo, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: GeoColores.azulProfundo),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Protocolo de Verificación e Integridad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: GeoColores.primario),
                ),
              ),
              expirado
                  ? InsigniaGeo(
                      texto: 'Expirado',
                      icono: Icons.timer_outlined,
                      color: Colors.brown[800]!,
                      fondo: GeoColores.naranjaSuave,
                    )
                  : InsigniaGeo(texto: _cuentaRegresiva, icono: Icons.timer_outlined, fondo: GeoColores.menta),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: total > 0 ? restante / total : 0,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: GeoColores.lavanda,
            color: expirado ? Colors.orange : GeoColores.verdeOscuro,
          ),
          const SizedBox(height: 16),
          _itemProtocolo(Icons.fingerprint, 'Firma SHA-256', '${_token.firma.substring(0, 12)}…'),
          _itemProtocolo(Icons.badge_outlined, 'Vinculado a',
              widget.usuario.codigoMatricula.isNotEmpty ? widget.usuario.codigoMatricula : widget.usuario.correo),
          _itemProtocolo(Icons.class_outlined, 'Válido solo para', '${widget.materia.nombre} (${widget.materia.codigo})'),
          _itemProtocolo(Icons.schedule, 'Emitido', formatearHora(_token.emitido, conSegundos: true)),
          _itemProtocolo(Icons.near_me_outlined, 'Distancia al aula', '${widget.distancia.toStringAsFixed(1)}m'),
        ],
      ),
    );
  }

  Widget _itemProtocolo(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(etiqueta, style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: GeoColores.primario),
            ),
          ),
        ],
      ),
    );
  }
}
