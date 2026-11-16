import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/registro_asistencia.dart';
import '../models/usuario.dart';
import '../widgets/geocheck_ui.dart';

/// Genera el Certificado de Cumplimiento de asistencia en PDF y abre el diálogo para compartirlo/guardarlo.
class CertificadoService {
  static Future<void> generarYCompartir({
    required Usuario usuario,
    required List<RegistroAsistencia> registros,
    required int asistidas,
    required int faltas,
    required double porcentaje,
  }) async {
    // Fuente con soporte de tildes; si no hay internet se usa la fuente por defecto
    pw.ThemeData tema;
    try {
      tema = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.interRegular(),
        bold: await PdfGoogleFonts.interBold(),
      );
    } catch (e) {
      debugPrint('No se pudo descargar la fuente del PDF: $e');
      tema = pw.ThemeData.base();
    }

    const azul = PdfColor.fromInt(0xFF001E6C);
    const verde = PdfColor.fromInt(0xFF006B45);
    final ahora = DateTime.now();
    final doc = pw.Document(title: 'Certificado de Asistencia - ${usuario.nombre}');

    doc.addPage(
      pw.MultiPage(
        theme: tema,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: const pw.BoxDecoration(
              color: azul,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('GeoCheck Campus',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
                pw.SizedBox(height: 4),
                pw.Text('Certificado de Cumplimiento de Asistencia',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text('Estudiante: ${usuario.nombre}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.Text('Código institucional: ${usuario.codigoMatricula.isNotEmpty ? usuario.codigoMatricula : '-'}'),
          pw.Text('Facultad: ${usuario.facultad.isNotEmpty ? usuario.facultad : '-'}'),
          pw.Text('Correo: ${usuario.correo}'),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              _resumen('Porcentaje global', '${porcentaje.toStringAsFixed(0)}%', verde),
              pw.SizedBox(width: 10),
              _resumen('Asistencias', '$asistidas', verde),
              pw.SizedBox(width: 10),
              _resumen('Inasistencias', '$faltas', PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text('Detalle de registros', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (registros.isEmpty)
            pw.Text('No hay registros de asistencia.')
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: azul),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['Fecha', 'Hora', 'Asignatura', 'Salón', 'Estado', 'Código'],
              data: registros
                  .map((r) => [
                        formatearFecha(r.fecha),
                        r.presente ? formatearHora(r.fecha) : '--:--',
                        '${r.materiaNombre} (${r.materiaCodigo})',
                        r.salon,
                        r.presente ? 'Presente' : 'Ausente',
                        r.codigoCriptografico.isNotEmpty ? r.codigoCriptografico : '-',
                      ])
                  .toList(),
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Documento generado el ${formatearFecha(ahora)} a las ${formatearHora(ahora)}. '
            'Cada registro presente incluye un código criptográfico verificable en GeoCheck Campus.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final nombreArchivo =
        'certificado_asistencia_${usuario.codigoMatricula.isNotEmpty ? usuario.codigoMatricula : usuario.uid}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: nombreArchivo);
  }

  static pw.Widget _resumen(String titulo, String valor, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(titulo, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(valor, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
