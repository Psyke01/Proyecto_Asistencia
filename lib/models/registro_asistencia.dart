import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro individual de asistencia de un estudiante.
/// Se guarda en Firestore en: usuarios/{uid}/asistencias/{id}
class RegistroAsistencia {
  final String id;
  final String materiaId;
  final String materiaNombre;
  final String materiaCodigo;
  final String docente;
  final String salon;
  final DateTime fecha;
  final bool presente;
  final double distanciaMetros;
  final double precisionMetros;
  final String objetoValidacion;
  final String tokenSesion;
  final String codigoCriptografico;
  final String observacion;

  RegistroAsistencia({
    required this.id,
    required this.materiaId,
    required this.materiaNombre,
    required this.materiaCodigo,
    required this.docente,
    required this.salon,
    required this.fecha,
    required this.presente,
    this.distanciaMetros = 0,
    this.precisionMetros = 0,
    this.objetoValidacion = '',
    this.tokenSesion = '',
    this.codigoCriptografico = '',
    this.observacion = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'materiaId': materiaId,
      'materiaNombre': materiaNombre,
      'materiaCodigo': materiaCodigo,
      'docente': docente,
      'salon': salon,
      'fecha': Timestamp.fromDate(fecha),
      'presente': presente,
      'distanciaMetros': distanciaMetros,
      'precisionMetros': precisionMetros,
      'objetoValidacion': objetoValidacion,
      'tokenSesion': tokenSesion,
      'codigoCriptografico': codigoCriptografico,
      'observacion': observacion,
    };
  }

  factory RegistroAsistencia.fromMap(String id, Map<String, dynamic> map) {
    final fechaCruda = map['fecha'];
    return RegistroAsistencia(
      id: id,
      materiaId: map['materiaId'] ?? '',
      materiaNombre: map['materiaNombre'] ?? '',
      materiaCodigo: map['materiaCodigo'] ?? '',
      docente: map['docente'] ?? '',
      salon: map['salon'] ?? '',
      fecha: fechaCruda is Timestamp ? fechaCruda.toDate() : DateTime.now(),
      presente: map['presente'] as bool? ?? false,
      distanciaMetros: (map['distanciaMetros'] as num?)?.toDouble() ?? 0,
      precisionMetros: (map['precisionMetros'] as num?)?.toDouble() ?? 0,
      objetoValidacion: map['objetoValidacion'] ?? '',
      tokenSesion: map['tokenSesion'] ?? '',
      codigoCriptografico: map['codigoCriptografico'] ?? '',
      observacion: map['observacion'] ?? '',
    );
  }
}
