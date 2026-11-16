import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/materia.dart';
import '../models/registro_asistencia.dart';

/// Token individual de la sesión de registro (Paso 2).
/// Se genera para un estudiante y una materia, y caduca a los pocos segundos.
class TokenSesion {
  final String valor; // Ej: TKN-8F2A-91C3
  final String firma; // Hash SHA-256 completo
  final DateTime emitido;
  final DateTime expira;

  TokenSesion({
    required this.valor,
    required this.firma,
    required this.emitido,
    required this.expira,
  });

  bool get expirado => DateTime.now().isAfter(expira);

  Duration get restante {
    final r = expira.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  /// Contenido que se dibuja dentro del QR individual
  String get contenidoQr => 'GEOTOKEN:$valor:${firma.substring(0, 16)}';
}

/// Servicio con la lógica del flujo de asistencia del estudiante:
/// GPS (geocerca) → Escaneo del QR institucional del aula (docente) → Registro.
class AsistenciaService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Prefijo del QR institucional que muestra el docente en el aula.
  /// Formato: GEOCHECK:{CODIGO_MATERIA}  o  GEOCHECK:{CODIGO_MATERIA}:{MINUTO_EPOCH}
  static const String prefijoQrAula = 'GEOCHECK';

  /// Vigencia del token individual del Paso 2
  static const Duration vigenciaToken = Duration(seconds: 90);

  /// Si el docente aún no calibró la geocerca, en modo debug se usa la
  /// primera lectura GPS como centro del aula para poder probar el flujo.
  static bool get permitirGeocercaDePrueba => kDebugMode;

  // ---------------------------------------------------------------------------
  // GPS
  // ---------------------------------------------------------------------------

  /// Verifica servicio de ubicación y permisos. Devuelve un mensaje de error o null si todo está bien.
  static Future<String?> verificarPermisosUbicacion() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      return 'El GPS del dispositivo está desactivado. Actívalo para continuar.';
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      return 'Debes conceder el permiso de ubicación para registrar asistencia.';
    }
    if (permiso == LocationPermission.deniedForever) {
      return 'El permiso de ubicación está bloqueado. Habilítalo desde los ajustes del teléfono.';
    }
    return null;
  }

  /// Flujo continuo de posiciones GPS de alta precisión
  static Stream<Position> escucharPosicion() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    );
  }

  /// Lectura puntual (usada para la confirmación GPS en el Paso 2)
  static Future<Position> obtenerPosicionActual() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

  static double distanciaEntre(Position p, double lat, double lng) {
    return Geolocator.distanceBetween(p.latitude, p.longitude, lat, lng);
  }

  /// Texto descriptivo de la calidad de la señal según la precisión reportada
  static String calidadSenal(double precision) {
    if (precision <= 5) return 'Excelente señal';
    if (precision <= 15) return 'Buena señal';
    if (precision <= 30) return 'Señal regular';
    return 'Señal débil';
  }

  /// Hora límite para registrar asistencia en la sesión actual
  static DateTime horaLimiteRegistro(Materia materia, DateTime inicioFlujo) {
    final inicio = materia.inicioSesion ?? inicioFlujo;
    return inicio.add(Duration(minutes: materia.toleranciaMinutos));
  }

  // ---------------------------------------------------------------------------
  // Tokens y códigos
  // ---------------------------------------------------------------------------

  static String _hash(String texto) =>
      sha256.convert(utf8.encode(texto)).toString().toUpperCase();

  /// Genera el token individual e inmutable del estudiante para esta sesión
  static TokenSesion generarToken({
    required String uid,
    required String materiaId,
  }) {
    final ahora = DateTime.now();
    final semilla = Random.secure().nextInt(1 << 32);
    final firma = _hash('$uid|$materiaId|${ahora.microsecondsSinceEpoch}|$semilla');
    return TokenSesion(
      valor: 'TKN-${firma.substring(0, 4)}-${firma.substring(4, 8)}',
      firma: firma,
      emitido: ahora,
      expira: ahora.add(vigenciaToken),
    );
  }

  /// Valida el contenido del QR institucional escaneado en el aula.
  /// Devuelve null si es válido o el motivo del rechazo.
  static String? validarQrAula(String? contenido, Materia materia) {
    if (contenido == null || contenido.trim().isEmpty) {
      return 'No se pudo leer el código QR.';
    }
    final partes = contenido.trim().toUpperCase().split(':');
    if (partes.length < 2 || partes[0] != prefijoQrAula) {
      return 'Este QR no pertenece a GeoCheck Campus.';
    }
    if (partes[1] != materia.codigo.toUpperCase()) {
      return 'El QR corresponde a otra asignatura (${partes[1]}).';
    }
    // QR dinámico: el docente lo regenera cada minuto; se acepta un desfase de 2 min
    if (partes.length >= 3) {
      final minutoQr = int.tryParse(partes[2]);
      final minutoActual = DateTime.now().millisecondsSinceEpoch ~/ 60000;
      if (minutoQr == null || (minutoActual - minutoQr).abs() > 2) {
        return 'El código QR del aula expiró. Pide al docente que lo actualice.';
      }
    }
    return null;
  }

  /// Contenido del QR dinámico que muestra el docente en el aula
  static String contenidoQrAula(String codigoMateria) {
    final minuto = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    return '$prefijoQrAula:${codigoMateria.toUpperCase()}:$minuto';
  }

  /// Código criptográfico del comprobante. Ej: GEO-8291-B7F9-OK
  static String generarCodigoComprobante(String uid, String materiaId, String token) {
    final h = _hash('$uid|$materiaId|$token|${DateTime.now().millisecondsSinceEpoch}');
    return 'GEO-${h.substring(0, 4)}-${h.substring(4, 8)}-OK';
  }

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> _registros(String uid) =>
      _db.collection('usuarios').doc(uid).collection('asistencias');

  /// Verifica si el estudiante ya registró asistencia hoy en esa materia
  static Future<bool> yaRegistroHoy(String uid, String materiaId) async {
    final query = await _registros(uid).where('materiaId', isEqualTo: materiaId).get();
    final hoy = DateTime.now();
    return query.docs.any((d) {
      final r = RegistroAsistencia.fromMap(d.id, d.data());
      return r.presente &&
          r.fecha.year == hoy.year &&
          r.fecha.month == hoy.month &&
          r.fecha.day == hoy.day;
    });
  }

  /// Guarda el registro de asistencia y aumenta el contador de la materia
  static Future<RegistroAsistencia> registrarAsistencia({
    required String uid,
    required Materia materia,
    required Position posicion,
    required double distancia,
    required TokenSesion token,
  }) async {
    final docRef = _registros(uid).doc();
    final registro = RegistroAsistencia(
      id: docRef.id,
      materiaId: materia.id,
      materiaNombre: materia.nombre,
      materiaCodigo: materia.codigo,
      docente: materia.docente,
      salon: materia.salon,
      fecha: DateTime.now(),
      presente: true,
      distanciaMetros: distancia,
      precisionMetros: posicion.accuracy,
      objetoValidacion: materia.objetoValidacion,
      tokenSesion: token.valor,
      codigoCriptografico: generarCodigoComprobante(uid, materia.id, token.firma),
    );

    final batch = _db.batch();
    batch.set(docRef, {
      ...registro.toMap(),
      'latitud': posicion.latitude,
      'longitud': posicion.longitude,
      'registradoEn': FieldValue.serverTimestamp(),
    });
    batch.update(
      _db.collection('usuarios').doc(uid).collection('materias').doc(materia.id),
      {'sesionesAsistidas': FieldValue.increment(1)},
    );
    await batch.commit();
    return registro;
  }

  /// Historial de registros del estudiante (más recientes primero)
  static Stream<List<RegistroAsistencia>> escucharRegistros(String uid) {
    return _registros(uid).orderBy('fecha', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => RegistroAsistencia.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}
