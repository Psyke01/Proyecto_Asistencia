import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/registro_asistencia.dart';
import '../models/usuario.dart';
import '../services/asistencia_service.dart';
import '../services/certificado_service.dart';
import '../widgets/geocheck_ui.dart';

/// Pestaña "Asistencia" del Estudiante.
/// Muestra el porcentaje global, el historial de registros filtrable por asignatura,
/// la guía de mensajes de validación y la descarga del certificado en PDF.
/// Se usa como cuerpo dentro de StudentHomeScreen (no tiene Scaffold propio).
class MiAsistenciaScreen extends StatefulWidget {
  final Usuario usuario;

  const MiAsistenciaScreen({super.key, required this.usuario});

  @override
  State<MiAsistenciaScreen> createState() => _MiAsistenciaScreenState();
}

class _MiAsistenciaScreenState extends State<MiAsistenciaScreen> {
  static const double minimoAprobacion = 80;

  String? _materiaFiltro; // null = Todos los cursos
  bool _generandoPdf = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _streamMaterias;
  late final Stream<List<RegistroAsistencia>> _streamRegistros;

  @override
  void initState() {
    super.initState();
    _streamMaterias = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.usuario.uid)
        .collection('materias')
        .snapshots();
    _streamRegistros = AsistenciaService.escucharRegistros(widget.usuario.uid);
  }

  String get _semestreActual {
    final ahora = DateTime.now();
    return '${ahora.year}-${ahora.month <= 6 ? 'I' : 'II'}';
  }

  Future<void> _descargarCertificado(
    List<RegistroAsistencia> registros,
    int asistidas,
    int faltas,
    double porcentaje,
  ) async {
    setState(() => _generandoPdf = true);
    try {
      await CertificadoService.generarYCompartir(
        usuario: widget.usuario,
        registros: registros,
        asistidas: asistidas,
        faltas: faltas,
        porcentaje: porcentaje,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo generar el certificado: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _generandoPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _streamMaterias,
      builder: (context, snapMaterias) {
        final materias = snapMaterias.hasData
            ? snapMaterias.data!.docs.map((d) => Materia.fromMap(d.id, d.data())).toList()
            : <Materia>[];

        return StreamBuilder<List<RegistroAsistencia>>(
          stream: _streamRegistros,
          builder: (context, snapRegistros) {
            final registros = snapRegistros.data ?? <RegistroAsistencia>[];
            final cargando = snapRegistros.connectionState == ConnectionState.waiting && !snapRegistros.hasData;

            // Métricas globales (misma fuente que la pantalla de Inicio)
            final asistidas = materias.fold<int>(0, (acc, m) => acc + m.sesionesAsistidas);
            final faltas = materias.fold<int>(0, (acc, m) => acc + m.sesionesFaltas);
            final total = asistidas + faltas;
            final porcentaje = total > 0 ? asistidas / total * 100 : 0.0;

            final filtrados = _materiaFiltro == null
                ? registros
                : registros.where((r) => r.materiaId == _materiaFiltro).toList();

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezado(),
                    const SizedBox(height: 16),
                    _tarjetaPorcentaje(porcentaje, asistidas, total),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _tarjetaContador(
                            'Asistencias',
                            '$asistidas',
                            'de $total clases',
                            Icons.check_circle,
                            GeoColores.verdeOscuro,
                            GeoColores.menta,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _tarjetaContador(
                            'Inasistencias',
                            '$faltas',
                            'faltas acumuladas',
                            Icons.cancel,
                            Colors.red[700]!,
                            GeoColores.rojoSuave,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _filtros(materias, filtrados.length),
                    const SizedBox(height: 14),
                    if (cargando)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (filtrados.isEmpty)
                      _estadoVacio()
                    else
                      ..._listaRegistros(filtrados),
                    const SizedBox(height: 24),
                    _casosValidacion(),
                    const SizedBox(height: 24),
                    _tarjetaCertificado(registros, asistidas, faltas, porcentaje),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 1. Encabezado
  Widget _encabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFFF1F3FD), Color(0xFFE3E8FB)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InsigniaGeo(texto: '● Semestre $_semestreActual', fondo: GeoColores.menta, tamano: 10),
              const Spacer(),
              Icon(Icons.published_with_changes, size: 14, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text('Actualizado hoy', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Mi Asistencia y Registro Académico',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: GeoColores.azulProfundo),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitorea tu porcentaje de permanencia y consulta la telemetría de tus registros espaciales.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  /// 2. Porcentaje global con anillo de progreso
  Widget _tarjetaPorcentaje(double porcentaje, int asistidas, int total) {
    String estado;
    Color color;
    Color fondo;
    if (total == 0) {
      estado = 'Sin registros';
      color = Colors.grey[700]!;
      fondo = GeoColores.lavanda;
    } else if (porcentaje >= 85) {
      estado = 'Excelente';
      color = GeoColores.verdeOscuro;
      fondo = GeoColores.menta;
    } else if (porcentaje >= minimoAprobacion) {
      estado = 'Regular';
      color = Colors.orange[800]!;
      fondo = const Color(0xFFFEF3C7);
    } else {
      estado = 'En riesgo';
      color = Colors.red[700]!;
      fondo = GeoColores.rojoSuave;
    }

    return TarjetaGeo(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Porcentaje Global', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${porcentaje.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: GeoColores.azulProfundo),
                    ),
                    const SizedBox(width: 8),
                    InsigniaGeo(texto: estado, color: color, fondo: fondo),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Mínimo para aprobar: ${minimoAprobacion.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: total > 0 ? asistidas / total : 0,
                    strokeWidth: 6,
                    backgroundColor: GeoColores.lavanda,
                    color: GeoColores.verdeOscuro,
                  ),
                ),
                Text('$asistidas/$total',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GeoColores.azulProfundo)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Contadores
  Widget _tarjetaContador(String titulo, String valor, String sub, IconData icono, Color color, Color fondo) {
    return TarjetaGeo(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
                child: Icon(icono, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(valor, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  /// 4. Filtros por asignatura
  Widget _filtros(List<Materia> materias, int cantidad) {
    Widget chip(String texto, String? id) {
      final seleccionado = _materiaFiltro == id;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(texto),
          selected: seleccionado,
          showCheckmark: false,
          onSelected: (_) => setState(() => _materiaFiltro = id),
          selectedColor: GeoColores.azulProfundo,
          backgroundColor: GeoColores.lavandaFondo,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: seleccionado ? Colors.white : Colors.grey[800],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Filtrar por Asignatura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: GeoColores.primario),
              ),
            ),
            Text(
              '$cantidad registros',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GeoColores.azulProfundo),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('Todos los cursos', null),
              ...materias.map((m) => chip(m.nombre, m.id)),
            ],
          ),
        ),
      ],
    );
  }

  /// 5. Historial de registros
  List<Widget> _listaRegistros(List<RegistroAsistencia> registros) {
    // Número de falta por materia (en orden cronológico)
    final numeroFalta = <String, int>{};
    final conteo = <String, int>{};
    for (final r in registros.reversed) {
      if (!r.presente) {
        conteo[r.materiaId] = (conteo[r.materiaId] ?? 0) + 1;
        numeroFalta[r.id] = conteo[r.materiaId]!;
      }
    }

    return registros
        .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _tarjetaRegistro(r, numeroFalta[r.id]),
            ))
        .toList();
  }

  Widget _tarjetaRegistro(RegistroAsistencia r, int? numeroFalta) {
    final presente = r.presente;
    return TarjetaGeo(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: presente ? GeoColores.menta : GeoColores.rojoSuave,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  presente ? Icons.check : Icons.close,
                  color: presente ? GeoColores.verdeOscuro : Colors.red[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.materiaNombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: GeoColores.primario),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatearFecha(r.fecha, conAnio: false)}  •  ${r.salon}  •  '
                      '${presente ? formatearHora(r.fecha) : '--:--'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              presente
                  ? const InsigniaGeo(texto: 'Presente', fondo: GeoColores.menta)
                  : InsigniaGeo(texto: 'Ausente', color: Colors.red[700]!, fondo: GeoColores.rojoSuave),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: presente ? GeoColores.lavandaFondo : const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: presente
                ? Row(
                    children: [
                      const Icon(Icons.key, size: 14, color: GeoColores.azulProfundo),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.codigoCriptografico.isNotEmpty ? r.codigoCriptografico : 'Registro manual',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'GPS ±${r.precisionMetros.toStringAsFixed(0)}m • ${r.distanciaMetros.toStringAsFixed(0)}m',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(Icons.info_outline, size: 15, color: Colors.red[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.observacion.isNotEmpty ? r.observacion : 'Sin marcación registrada dentro del horario',
                          style: TextStyle(fontSize: 11.5, color: Colors.red[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (numeroFalta != null)
                        Text('Falta #$numeroFalta',
                            style: TextStyle(fontSize: 11.5, color: Colors.red[800], fontWeight: FontWeight.w600)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _estadoVacio() {
    return TarjetaGeo(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: Column(
        children: [
          Icon(Icons.event_note_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          const Text('Aún no tienes registros', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Cuando marques asistencia en una clase activa aparecerá aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 6. Guía de casos de validación
  Widget _casosValidacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: GeoColores.naranjaSuave, borderRadius: BorderRadius.circular(6)),
              child: Icon(Icons.quiz_outlined, size: 18, color: Colors.brown[700]),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Casos y Mensajes de Validación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: GeoColores.primario),
              ),
            ),
            Text('Guía\ninteractiva', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Toca cualquier situación para comprender las causas y resoluciones del motor de validación espacial de GeoCheck.',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        const SizedBox(height: 12),
        _caso(
          Icons.wrong_location_outlined,
          Colors.red[700]!,
          GeoColores.rojoSuave,
          '1. Ubicación no válida',
          'Fuera del radio de cobertura',
          'Tu GPS te ubica fuera del radio configurado por el docente. Acércate al aula, '
              'activa el modo de alta precisión y espera a que el radar se actualice.',
        ),
        _caso(
          Icons.qr_code_2,
          Colors.orange[800]!,
          GeoColores.naranjaSuave,
          '2. Código QR expirado o inválido',
          'Token dinámico no sincronizado',
          'El código QR proyectado por el docente en el aula se renueva dinámicamente cada minuto '
              'por seguridad. Asegúrate de escanear el QR vigente mostrado por el docente.',
        ),
        _caso(
          Icons.schedule,
          GeoColores.azulProfundo,
          GeoColores.lavanda,
          '3. Ventana de tiempo cerrada',
          'Tiempo reglamentario excedido',
          'El registro solo se permite durante la tolerancia definida tras el inicio de la clase. '
              'Pasado ese tiempo queda como inasistencia; habla con tu docente si hubo un inconveniente.',
        ),
        _caso(
          Icons.verified_user_outlined,
          GeoColores.verdeOscuro,
          GeoColores.menta,
          '4. Permisos requeridos',
          'Cámara y GPS activo',
          'GeoCheck necesita permiso de ubicación precisa y de cámara. Si los negaste, '
              'habilítalos desde Ajustes > Aplicaciones > GeoCheck > Permisos.',
        ),
      ],
    );
  }

  Widget _caso(IconData icono, Color color, Color fondo, String titulo, String sub, String detalle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
            child: Icon(icono, size: 18, color: color),
          ),
          title: Text(titulo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(sub, style: TextStyle(fontSize: 12, color: color)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detalle, style: TextStyle(fontSize: 12.5, color: Colors.grey[800], height: 1.4)),
          ],
        ),
      ),
    );
  }

  /// 7. Certificado PDF
  Widget _tarjetaCertificado(List<RegistroAsistencia> registros, int asistidas, int faltas, double porcentaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: GeoColores.azulProfundo, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium, color: GeoColores.menta),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Certificación de Cumplimiento',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Emisión con el código criptográfico de cada asistencia registrada.',
                      style: TextStyle(color: Color(0xFF9DB4F5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generandoPdf ? null : () => _descargarCertificado(registros, asistidas, faltas, porcentaje),
              style: ElevatedButton.styleFrom(
                backgroundColor: GeoColores.verdeOscuro,
                disabledBackgroundColor: GeoColores.verdeOscuro.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _generandoPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download, color: Colors.white),
              label: const Text(
                'Descargar Certificado de Asistencia en PDF',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
