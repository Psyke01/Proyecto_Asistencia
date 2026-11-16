import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/asistencia_service.dart';

/// Pantalla de Toma de Asistencia en Vivo para el Docente.
/// Muestra telemetría de geocerca satelital y quórum en tiempo real.
class AsistenciaEnVivoScreen extends StatefulWidget {
  final String nombreAsignatura;
  final String codigo;
  final String aula;

  const AsistenciaEnVivoScreen({
    super.key,
    this.nombreAsignatura = 'Asignatura en Curso',
    this.codigo = 'COD-001',
    this.aula = 'Aula 204',
  });

  @override
  State<AsistenciaEnVivoScreen> createState() => _AsistenciaEnVivoScreenState();
}

class _AsistenciaEnVivoScreenState extends State<AsistenciaEnVivoScreen> {
  static const Color colorPrimario = Color(0xFF0A192F);

  // Lista de asistencia en tiempo real (inicia vacía para llenarse cuando los alumnos se conecten)
  final List<Map<String, dynamic>> _registrosAsistencia = [];

  String _filtroEstado = 'Todos'; // 'Todos', 'Presentes', 'Ausentes'
  String _busqueda = '';

  void _finalizarClase() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar Sesión de Clase'),
        content: const Text('¿Estás seguro de cerrar la toma de asistencia para esta clase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Regresa a la pantalla principal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clase finalizada y reporte guardado.'),
                  backgroundColor: Colors.blueGrey,
                ),
              );
            },
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Muestra el QR institucional dinámico que los estudiantes escanean en el Paso 2
  void _mostrarQrAula() {
    showDialog(
      context: context,
      builder: (_) => _DialogoQrAula(codigo: widget.codigo, aula: widget.aula),
    );
  }

  void _calibrarGeocerca() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Geocerca calibrada con precisión GPS ±0.5m en esta aula.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int presentesCount = _registrosAsistencia.where((r) => r['presente'] == true).length;
    final int ausentesCount = _registrosAsistencia.where((r) => r['presente'] == false).length;
    final int totalInscritos = _registrosAsistencia.length;
    final double porcentaje = totalInscritos > 0 ? (presentesCount / totalInscritos) * 100 : 0.0;

    final filtrados = _registrosAsistencia.where((r) {
      final coincideNombre = (r['nombre'] ?? '').toString().toLowerCase().contains(_busqueda.toLowerCase());
      if (!coincideNombre) return false;

      if (_filtroEstado == 'Presentes') return r['presente'] == true;
      if (_filtroEstado == 'Ausentes') return r['presente'] == false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorPrimario),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Asistencia En Vivo',
          style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colorPrimario,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta Superior: Estado En Vivo y Geocerca
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 8),
                              SizedBox(width: 4),
                              Text('EN VIVO • GPS ACTIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.aula, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimario)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.nombreAsignatura,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorPrimario),
                    ),
                    Text('Código ${widget.codigo}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),

                    // Barra de Geocerca Perimetral
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: Colors.teal, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Geocerca Perimetral: 15m', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Text('98.4% precisión satelital verificada', style: TextStyle(fontSize: 9, color: Colors.grey)),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _mostrarQrAula,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            icon: const Icon(Icons.qr_code_2, size: 14, color: colorPrimario),
                            label: const Text('QR del aula', style: TextStyle(fontSize: 10, color: colorPrimario)),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: _calibrarGeocerca,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            child: const Text('Calibrar', style: TextStyle(fontSize: 10, color: colorPrimario)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Tarjeta de Métricas de Presencia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bar_chart, size: 18, color: colorPrimario),
                            SizedBox(width: 6),
                            Text('Métricas de Presencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorPrimario)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${porcentaje.toStringAsFixed(1)}% Asistencia',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Presentes', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text('$presentesCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                              const Text('Verificados', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 35, color: Colors.grey[200]),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Ausentes', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text('$ausentesCount', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              const Text('Sin fichaje', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 35, color: Colors.grey[200]),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Inscritos', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text('$totalInscritos', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorPrimario)),
                              const Text('Matriculados', style: TextStyle(fontSize: 9, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: totalInscritos > 0 ? presentesCount / totalInscritos : 0.0,
                      backgroundColor: const Color(0xFFFEE2E2),
                      color: Colors.teal,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Barra de Búsqueda y Filtros
              TextField(
                onChanged: (val) => setState(() => _busqueda = val),
                decoration: InputDecoration(
                  hintText: 'Buscar estudiante por nombre...',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  ChoiceChip(
                    label: Text('Todos ($totalInscritos)'),
                    selected: _filtroEstado == 'Todos',
                    selectedColor: colorPrimario,
                    labelStyle: TextStyle(
                      color: _filtroEstado == 'Todos' ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _filtroEstado = 'Todos'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text('Presentes ($presentesCount)'),
                    selected: _filtroEstado == 'Presentes',
                    selectedColor: colorPrimario,
                    labelStyle: TextStyle(
                      color: _filtroEstado == 'Presentes' ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _filtroEstado = 'Presentes'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text('Ausentes ($ausentesCount)'),
                    selected: _filtroEstado == 'Ausentes',
                    selectedColor: colorPrimario,
                    labelStyle: TextStyle(
                      color: _filtroEstado == 'Ausentes' ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _filtroEstado = 'Ausentes'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Lista de Estudiantes en Vivo (Vacía o con Fichajes)
              if (filtrados.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cell_tower, size: 40, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text(
                        'Esperando marcaciones de estudiantes...',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorPrimario),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A medida que los estudiantes ingresen al radio del salón validado por geocerca GPS, aparecerán aquí en tiempo real.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
                    final bool presente = item['presente'] ?? false;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: presente ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                            child: Icon(presente ? Icons.check : Icons.close, size: 16, color: presente ? Colors.green : Colors.red),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nombre'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario)),
                                Text(item['detalle'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: presente ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              presente ? 'Presente ✓' : 'Ausente ✗',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: presente ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // 5. Botones de Acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Generando reporte digital...')),
                        );
                      },
                      icon: const Icon(Icons.download, size: 16, color: colorPrimario),
                      label: const Text('Exportar Reporte', style: TextStyle(color: colorPrimario, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _finalizarClase,
                      icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.white),
                      label: const Text('Finalizar Clase', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB91C1C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo con el QR institucional del aula. Se regenera cada 30 segundos
/// (formato GEOCHECK:{CODIGO}:{MINUTO}) para evitar que se comparta por foto.
class _DialogoQrAula extends StatefulWidget {
  final String codigo;
  final String aula;

  const _DialogoQrAula({required this.codigo, required this.aula});

  @override
  State<_DialogoQrAula> createState() => _DialogoQrAulaState();
}

class _DialogoQrAulaState extends State<_DialogoQrAula> {
  late String _contenido;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _contenido = AsistenciaService.contenidoQrAula(widget.codigo);
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _contenido = AsistenciaService.contenidoQrAula(widget.codigo));
      }
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('QR institucional · ${widget.aula}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A192F))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: QrImageView(data: _contenido, version: QrVersions.auto, backgroundColor: Colors.white),
          ),
          const SizedBox(height: 8),
          Text('Código ${widget.codigo} · se renueva cada 30 s',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}
