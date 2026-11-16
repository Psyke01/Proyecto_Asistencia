import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

/// Pantalla para que el Docente cree una nueva Asignatura.
/// Pide únicamente los datos generales de la materia y genera su código de forma automática.
class CrearAsignaturaScreen extends StatefulWidget {
  final Usuario usuario;

  const CrearAsignaturaScreen({super.key, required this.usuario});

  @override
  State<CrearAsignaturaScreen> createState() => _CrearAsignaturaScreenState();
}

class _CrearAsignaturaScreenState extends State<CrearAsignaturaScreen> {
  static const Color colorPrimario = Color(0xFF0A192F);

  // Controladores de texto para los datos de la asignatura
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _semestreController =
      TextEditingController(text: '2026-II');
  final TextEditingController _creditosController =
      TextEditingController(text: '4');
  String _modalidadSeleccionada = 'Presencial';

  @override
  void dispose() {
    _nombreController.dispose();
    _semestreController.dispose();
    _creditosController.dispose();
    super.dispose();
  }

  void _guardarAsignatura() {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escribe el nombre de la asignatura.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Generamos automáticamente el código único de la materia (ej: PRG-304)
    final codigoAutomatico = AuthService.generarCodigoAsignatura(nombre);

    // Retorna la asignatura creada a la pantalla principal
    Navigator.pop(context, {
      'nombre': nombre,
      'codigo': codigoAutomatico,
      'semestre': _semestreController.text.trim(),
      'creditos': _creditosController.text.trim(),
      'modalidad': _modalidadSeleccionada,
      'clases': <Map<String, String>>[], // Inicia sin clases; se crean dentro
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Asignatura creada con código oficial: $codigoAutomatico!'),
        backgroundColor: Colors.green,
      ),
    );
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
        title: const Text(
          'Crear Asignatura',
          style: TextStyle(
            color: colorPrimario,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Seguro',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
              // Banner Explicativo Superior
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.school_outlined, color: colorPrimario, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nueva Asignatura Académica',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorPrimario,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Define los datos generales del curso. Luego de crearla, podrás agregarle sus horarios de clase.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Título de la Sección
              const Text(
                'Datos de la Asignatura',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorPrimario,
                ),
              ),
              const SizedBox(height: 12),

              // Tarjeta Blanca de Formulario
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
                      'Nombre de la Asignatura *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorPrimario,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Programación Orientada a Objetos',
                        prefixIcon: const Icon(Icons.book_outlined, size: 20, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Banner de Código Automático
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Código Oficial Automático',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'El código institucional (ej: PRG-304) se generará automáticamente a partir del nombre para garantizar que no se repita.',
                                  style: TextStyle(fontSize: 10, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Semestre / Ciclo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colorPrimario,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _semestreController,
                                decoration: InputDecoration(
                                  hintText: 'Ej: 2026-II',
                                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Créditos',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: colorPrimario,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _creditosController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Ej: 4',
                                  prefixIcon: const Icon(Icons.star_outline, size: 18, color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Modalidad',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: colorPrimario,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _modalidadSeleccionada,
                      items: const [
                        DropdownMenuItem(value: 'Presencial', child: Text('Presencial (Con Geocerca)')),
                        DropdownMenuItem(value: 'Virtual', child: Text('Virtual')),
                        DropdownMenuItem(value: 'Híbrida', child: Text('Híbrida')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _modalidadSeleccionada = val);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón Guardar Asignatura
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardarAsignatura,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text(
                    'Crear Asignatura',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorPrimario,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
