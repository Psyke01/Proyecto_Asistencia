import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Pantalla para que el Docente matricule a un estudiante en su clase.
/// Permite buscar al estudiante por su código institucional O por su nombre completo,
/// validándolo en la base de datos de Firebase.
class MatricularEstudianteScreen extends StatefulWidget {
  final String nombreAsignatura;
  final String grupo;
  final String aula;
  final String codigoAsignatura;
  final String nombreDocente;

  const MatricularEstudianteScreen({
    super.key,
    this.nombreAsignatura = 'Asignatura Seleccionada',
    this.grupo = 'Grupo A',
    this.aula = 'Aula Asignada',
    this.codigoAsignatura = 'ASG-01',
    this.nombreDocente = 'Docente Titular',
  });

  @override
  State<MatricularEstudianteScreen> createState() =>
      _MatricularEstudianteScreenState();
}

class _MatricularEstudianteScreenState
    extends State<MatricularEstudianteScreen> {
  static const Color colorPrimario = Color(0xFF0A192F);

  final TextEditingController _busquedaController = TextEditingController();

  // Estados de búsqueda
  bool _buscando = false;
  bool _busquedaRealizada = false;
  String _ultimoTerminoBuscado = '';
  List<Usuario> _candidatosEncontrados = [];
  Usuario? _estudianteSeleccionado;

  // Configuración de telemetría para el aula
  bool _vincularGeocerca = true;
  bool _enviarInvitacionQR = true;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Busca estudiantes en Firestore por código (EST-...) o por nombre
  void _buscarEstudiante() async {
    final termino = _busquedaController.text.trim();

    if (termino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el código o nombre del estudiante.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _buscando = true;
      _busquedaRealizada = true;
      _ultimoTerminoBuscado = termino;
      _estudianteSeleccionado = null;
      _candidatosEncontrados = [];
    });

    final resultados = await AuthService.buscarEstudiantes(termino);

    setState(() {
      _buscando = false;
      _candidatosEncontrados = resultados;
      if (resultados.length == 1) {
        _estudianteSeleccionado = resultados.first;
      }
    });
  }

  /// Registra al estudiante seleccionado en la clase y sincroniza Firestore
  void _confirmarMatricula() async {
    if (_estudianteSeleccionado == null) return;

    final est = _estudianteSeleccionado!;

    // Sincronizamos la materia en la subcolección del estudiante en Firestore
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(est.uid)
          .collection('materias')
          .add({
        'nombre': widget.nombreAsignatura,
        'codigo': widget.codigoAsignatura,
        'docente': widget.nombreDocente,
        'radioGeocerca': 30,
        'toleranciaMinutos': 15,
        'salon': widget.aula,
        'horario': 'Horario Regular (${widget.grupo})',
        'sesionesAsistidas': 0,
        'sesionesFaltas': 0,
        'enCurso': false,
      });
    } catch (e) {
      debugPrint('Error al vincular materia al estudiante en Firestore: $e');
    }

    if (mounted) {
      Navigator.pop(context, {
        'codigo': est.codigoMatricula,
        'nombre': est.nombre,
        'correo': est.correo,
        'facultad': est.facultad,
        'asistenciaPorcentaje': 100, // Inicia al 100%
        'vincularGeocerca': _vincularGeocerca,
        'enviarQR': _enviarInvitacionQR,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡${est.nombre} matriculado exitosamente en ${widget.nombreAsignatura}!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Matricular Estudiante',
              style: TextStyle(
                color: colorPrimario,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.nombreAsignatura} (${widget.grupo})',
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Tarjeta informativa de la Asignatura y Aula
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
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_outlined, color: colorPrimario, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nombreAsignatura,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorPrimario),
                          ),
                          Text(
                            '📍 ${widget.aula} • ${widget.grupo}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Campo para buscar por Código o por Nombre
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
                    const Text(
                      'Buscar por Código o por Nombre',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Escribe el código oficial (ej: EST-20261234) o el nombre del alumno.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _busquedaController,
                            decoration: InputDecoration(
                              hintText: 'Ej: EST-20261234 o Carlos Pérez',
                              hintStyle: const TextStyle(fontSize: 12),
                              prefixIcon: const Icon(Icons.search, color: Colors.teal),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            onSubmitted: (_) => _buscarEstudiante(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _buscando ? null : _buscarEstudiante,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorPrimario,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _buscando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Buscar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Resultado de la Búsqueda
              if (_buscando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: colorPrimario),
                        SizedBox(height: 12),
                        Text('Buscando en la base de datos...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else if (_busquedaRealizada && _candidatosEncontrados.isEmpty)
                // Caso: Ningún estudiante encontrado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Estudiante no encontrado',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.brown),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No encontramos ninguna cuenta con "$_ultimoTerminoBuscado". Verifica el código o nombre y asegúrate de que el alumno ya se haya registrado en la app.',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (_candidatosEncontrados.length > 1 && _estudianteSeleccionado == null)
                // Caso: Varios resultados coincidentes para seleccionar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona el estudiante a matricular:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _candidatosEncontrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final est = _candidatosEncontrados[index];
                        return ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEEF2FF),
                            child: Text(
                              est.nombre.isNotEmpty ? est.nombre[0].toUpperCase() : 'E',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: colorPrimario),
                            ),
                          ),
                          title: Text(est.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${est.codigoMatricula} • ${est.correo}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: colorPrimario),
                          onTap: () => setState(() => _estudianteSeleccionado = est),
                        );
                      },
                    ),
                  ],
                )
              else if (_estudianteSeleccionado != null)
                // Caso: Estudiante seleccionado / encontrado listo para matricular
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de Estudiante Verificado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 12, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Estudiante Verificado en Base de Datos',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _estudianteSeleccionado!.codigoMatricula,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorPrimario),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFFEEF2FF),
                                child: Text(
                                  _estudianteSeleccionado!.nombre.isNotEmpty
                                      ? _estudianteSeleccionado!.nombre.split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase()
                                      : 'E',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorPrimario),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _estudianteSeleccionado!.nombre,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorPrimario),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _estudianteSeleccionado!.correo,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      _estudianteSeleccionado!.facultad.isNotEmpty
                                          ? _estudianteSeleccionado!.facultad
                                          : 'Facultad no especificada',
                                      style: const TextStyle(fontSize: 11, color: Colors.teal),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Opciones de Geocerca
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            activeColor: Colors.teal,
                            title: const Text('Vincular a geocerca Aula', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text('Valida marcación exclusivamente dentro de ${widget.aula}.', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            value: _vincularGeocerca,
                            onChanged: (val) => setState(() => _vincularGeocerca = val),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            activeColor: colorPrimario,
                            title: const Text('Emitir credencial y QR de acceso', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Permite autenticación institucional.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            value: _enviarInvitacionQR,
                            onChanged: (val) => setState(() => _enviarInvitacionQR = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botón para Confirmar la Matrícula
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _confirmarMatricula,
                        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                        label: Text(
                          'Matricular en ${widget.nombreAsignatura}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
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
