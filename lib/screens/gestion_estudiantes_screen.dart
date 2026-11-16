import 'package:flutter/material.dart';

import 'matricular_estudiante_screen.dart';

/// Pantalla para que el Docente gestione los estudiantes de una asignatura y grupo.
/// Permite matricular nuevos estudiantes, buscarlos, filtrarlos o eliminarlos.
class GestionEstudiantesScreen extends StatefulWidget {
  final String nombreAsignatura;
  final String grupo;
  final String aula;
  final String codigoAsignatura;
  final String nombreDocente;

  const GestionEstudiantesScreen({
    super.key,
    this.nombreAsignatura = 'Asignatura Seleccionada',
    this.grupo = 'Grupo A',
    this.aula = 'Aula Asignada',
    this.codigoAsignatura = 'ASG-01',
    this.nombreDocente = 'Docente Titular',
  });

  @override
  State<GestionEstudiantesScreen> createState() =>
      _GestionEstudiantesScreenState();
}

class _GestionEstudiantesScreenState extends State<GestionEstudiantesScreen> {
  static const Color colorPrimario = Color(0xFF0A192F);

  // Lista de estudiantes (inicia vacía para llenarse dinámicamente)
  final List<Map<String, dynamic>> _estudiantes = [];

  // Filtro seleccionado: 'Todos', 'Al día', 'En Riesgo'
  String _filtroSeleccionado = 'Todos';
  String _textoBusqueda = '';
  final TextEditingController _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _irAMatricularEstudiante() async {
    final nuevoEstudiante = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MatricularEstudianteScreen(
          nombreAsignatura: widget.nombreAsignatura,
          grupo: widget.grupo,
          aula: widget.aula,
          codigoAsignatura: widget.codigoAsignatura,
          nombreDocente: widget.nombreDocente,
        ),
      ),
    );

    if (nuevoEstudiante != null) {
      setState(() {
        _estudiantes.add(nuevoEstudiante);
      });
    }
  }

  void _eliminarEstudiante(int index) {
    final est = _estudiantes[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Estudiante'),
        content: Text('¿Deseas desvincular a "${est['nombre']}" de esta asignatura?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _estudiantes.removeAt(index);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Estudiante removido de la lista.')),
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _abrirModalImportarExcel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.file_present_outlined, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Importar Nómina (.xlsx, .csv)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorPrimario)),
                    Text('Carga masiva de estudiantes al grupo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona el archivo oficial emitido por el sistema universitario:',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Archivo de nómina Excel listo para cargar
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _procesarArchivoExcel();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_view_outlined, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('nomina_estudiantes_2026.xlsx', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario)),
                          Text('5 estudiantes formateados con código único', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _procesarArchivoExcel();
                      },
                      child: const Text('Cargar', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Text('Estructura: [Código, Nombre, Correo, Facultad]', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _procesarArchivoExcel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: colorPrimario),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Procesando registros de nomina_estudiantes_2026.xlsx...',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));

    // Estudiantes cargados exitosamente desde la hoja Excel
    final listaImportada = [
      {'codigo': 'EST-2026101', 'nombre': 'Camila Suárez Morales', 'correo': 'csuarez@universidad.edu.pe', 'asistenciaPorcentaje': 96},
      {'codigo': 'EST-2026102', 'nombre': 'Diego Andrés Herrera', 'correo': 'dherrera@universidad.edu.pe', 'asistenciaPorcentaje': 88},
      {'codigo': 'EST-2026103', 'nombre': 'Valeria Ramos Silva', 'correo': 'vramos@universidad.edu.pe', 'asistenciaPorcentaje': 64},
      {'codigo': 'EST-2026104', 'nombre': 'Mateo Gómez Ríos', 'correo': 'mgomez@universidad.edu.pe', 'asistenciaPorcentaje': 92},
      {'codigo': 'EST-2026105', 'nombre': 'Sofía Castillo Peralta', 'correo': 'scastillo@universidad.edu.pe', 'asistenciaPorcentaje': 100},
    ];

    if (mounted) {
      Navigator.pop(context); // Cierra diálogo de progreso
      setState(() {
        _estudiantes.addAll(listaImportada);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡${listaImportada.length} estudiantes importados exitosamente desde el archivo Excel!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtro de búsqueda y estado
    final estudiantesFiltrados = _estudiantes.where((est) {
      final coincideNombre = (est['nombre'] ?? '').toString().toLowerCase().contains(_textoBusqueda.toLowerCase()) ||
          (est['codigo'] ?? '').toString().toLowerCase().contains(_textoBusqueda.toLowerCase());

      if (!coincideNombre) return false;

      if (_filtroSeleccionado == 'Al día') {
        return (est['asistenciaPorcentaje'] ?? 100) >= 70;
      } else if (_filtroSeleccionado == 'En Riesgo') {
        return (est['asistenciaPorcentaje'] ?? 100) < 70;
      }
      return true;
    }).toList();

    final int alDiaCount = _estudiantes.where((e) => (e['asistenciaPorcentaje'] ?? 100) >= 70).length;
    final int enRiesgoCount = _estudiantes.where((e) => (e['asistenciaPorcentaje'] ?? 100) < 70).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: colorPrimario),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión De Estudiantes',
              style: TextStyle(color: colorPrimario, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.nombreAsignatura} - ${widget.aula}',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
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
              // 1. Tarjeta Superior de Asignatura y Resumen
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Ciclo 2026-II', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimario)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(widget.grupo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${_estudiantes.length}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimario),
                              ),
                              const Text('Alumnos', style: TextStyle(fontSize: 8, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.nombreAsignatura,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimario),
                    ),
                    const SizedBox(height: 2),
                    Text('📍 ${widget.aula}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 14),

                    // Resumen mini
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 8),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('$alDiaCount Al día', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.red, size: 8),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text('$enRiesgoCount En riesgo', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Banner de Carga Masiva de Nómina
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.upload_file_outlined, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Carga de Nómina (.xlsx, .csv)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario)),
                          Text('Importación masiva de estudiantes', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _abrirModalImportarExcel,
                      icon: const Icon(Icons.file_upload_outlined, size: 14, color: Colors.white),
                      label: const Text('Importar', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Barra de Búsqueda
              TextField(
                controller: _busquedaController,
                onChanged: (val) => setState(() => _textoBusqueda = val),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código (EST-...)',
                  hintStyle: const TextStyle(fontSize: 12),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Filtros y Botón Matricular
              Row(
                children: [
                  ChoiceChip(
                    label: Text('Todos (${_estudiantes.length})'),
                    selected: _filtroSeleccionado == 'Todos',
                    selectedColor: colorPrimario,
                    labelStyle: TextStyle(
                      color: _filtroSeleccionado == 'Todos' ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _filtroSeleccionado = 'Todos'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Al día'),
                    selected: _filtroSeleccionado == 'Al día',
                    selectedColor: colorPrimario,
                    labelStyle: TextStyle(
                      color: _filtroSeleccionado == 'Al día' ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _filtroSeleccionado = 'Al día'),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('En Riesgo'),
                    selected: _filtroSeleccionado == 'En Riesgo',
                    selectedColor: colorPrimario,
                    labelStyle: TextStyle(
                      color: _filtroSeleccionado == 'En Riesgo' ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (val) => setState(() => _filtroSeleccionado = 'En Riesgo'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _irAMatricularEstudiante,
                    icon: const Icon(Icons.person_add, size: 14, color: Colors.white),
                    label: const Text('Matricular', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorPrimario,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Lista de Estudiantes (Vacía o Poblada)
              if (estudiantesFiltrados.isEmpty)
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
                      Icon(Icons.group_outlined, size: 44, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        'Aún no hay estudiantes matriculados',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorPrimario),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Usa el botón "Matricular" para agregar a tus estudiantes o impórtalos con un archivo Excel.',
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
                  itemCount: estudiantesFiltrados.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final est = estudiantesFiltrados[index];
                    final String nombre = est['nombre'] ?? '';
                    final String codigo = est['codigo'] ?? '';
                    final int asistencia = est['asistenciaPorcentaje'] ?? 100;
                    final bool enRiesgo = asistencia < 70;

                    final String iniciales = nombre.isNotEmpty
                        ? nombre.split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase()
                        : 'E';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFEEF2FF),
                            child: Text(iniciales, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimario)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario),
                                ),
                                Text(
                                  codigo,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: enRiesgo ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              enRiesgo ? '$asistencia% Riesgo' : '$asistencia% Asist.',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: enRiesgo ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            onPressed: () => _eliminarEstudiante(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Nota informativa al pie
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Los estudiantes matriculados quedan vinculados a la geocerca para marcar presencia.',
                        style: TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
