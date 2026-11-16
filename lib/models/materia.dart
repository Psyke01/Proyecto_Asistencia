class Materia {
  final String id;
  final String nombre;
  final String codigo;
  final String docente;
  final String salon;
  final String horario;
  final int sesionesAsistidas;
  final int sesionesFaltas;
  final bool enCurso;

  // Parámetros de geocerca (los define el docente al calibrar el aula)
  final double? latitud;
  final double? longitud;
  final double radioGeocerca; // en metros
  final int toleranciaMinutos; // ventana de registro desde el inicio de la sesión
  final DateTime? inicioSesion; // momento en que el docente abrió la clase
  final String objetoValidacion; // objeto físico de referencia del aula

  Materia({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.docente,
    required this.salon,
    required this.horario,
    this.sesionesAsistidas = 0,
    this.sesionesFaltas = 0,
    this.enCurso = false,
    this.latitud,
    this.longitud,
    this.radioGeocerca = 30,
    this.toleranciaMinutos = 15,
    this.inicioSesion,
    this.objetoValidacion = 'QR institucional',
  });

  /// Indica si el docente ya calibró la geocerca del aula
  bool get tieneGeocerca => latitud != null && longitud != null;

  int get totalSesiones => sesionesAsistidas + sesionesFaltas;

  double get porcentajeAsistencia {
    if (totalSesiones == 0) return 0.0;
    return (sesionesAsistidas / totalSesiones) * 100.0;
  }

  double get progresoRatio {
    if (totalSesiones == 0) return 0.0;
    return sesionesAsistidas / totalSesiones;
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'codigo': codigo,
      'docente': docente,
      'salon': salon,
      'horario': horario,
      'sesionesAsistidas': sesionesAsistidas,
      'sesionesFaltas': sesionesFaltas,
      'enCurso': enCurso,
      'latitud': latitud,
      'longitud': longitud,
      'radioGeocerca': radioGeocerca,
      'toleranciaMinutos': toleranciaMinutos,
      'inicioSesion': inicioSesion,
      'objetoValidacion': objetoValidacion,
    };
  }

  factory Materia.fromMap(String id, Map<String, dynamic> map) {
    return Materia(
      id: id,
      nombre: map['nombre'] ?? '',
      codigo: map['codigo'] ?? '',
      docente: map['docente'] ?? '',
      salon: map['salon'] ?? '',
      horario: map['horario'] ?? '',
      sesionesAsistidas: (map['sesionesAsistidas'] as num?)?.toInt() ?? 0,
      sesionesFaltas: (map['sesionesFaltas'] as num?)?.toInt() ?? 0,
      enCurso: map['enCurso'] as bool? ?? false,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      radioGeocerca: (map['radioGeocerca'] as num?)?.toDouble() ?? 30,
      toleranciaMinutos: (map['toleranciaMinutos'] as num?)?.toInt() ?? 15,
      inicioSesion: _leerFecha(map['inicioSesion']),
      objetoValidacion: map['objetoValidacion'] ?? 'QR institucional',
    );
  }

  /// Convierte un Timestamp de Firestore (o DateTime) a DateTime sin importar cloud_firestore
  static DateTime? _leerFecha(dynamic valor) {
    if (valor == null) return null;
    if (valor is DateTime) return valor;
    try {
      return (valor as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
