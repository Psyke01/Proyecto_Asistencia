import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'asistencia_en_vivo_screen.dart';
import 'auth_screen.dart';
import 'crear_asignatura_screen.dart';
import 'detalle_clase_screen.dart';
import 'gestion_estudiantes_screen.dart';

/// Pantalla Principal del Docente en GeoCheck Campus.
/// Contiene 4 pestañas de navegación:
/// 1. Inicio (Resumen del día, clase activa y accesos rápidos)
/// 2. Cursos (Listado de asignaturas y grupos asignados)
/// 3. Asistencia (Historial, bitácora de sesiones y auditoría)
/// 4. Perfil (Datos del profesor y cierre de sesión)
class HomeScreen extends StatefulWidget {
  final Usuario usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indicePestana = 0;
  static const Color colorPrimario = Color(0xFF0A192F);

  // Lista de asignaturas del docente (inicia vacía para llenarse dinámicamente)
  final List<Map<String, dynamic>> _asignaturas = [];

  // Navega a la pantalla para crear una nueva asignatura
  void _abrirCrearAsignatura() async {
    final nuevaAsignatura = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => CrearAsignaturaScreen(usuario: widget.usuario),
      ),
    );

    if (nuevaAsignatura != null) {
      setState(() {
        _asignaturas.add(nuevaAsignatura);
      });
    }
  }

  // Navega a la gestión de estudiantes de una materia
  void _abrirGestionEstudiantes(String nombreMateria, String aula, String codigo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GestionEstudiantesScreen(
          nombreAsignatura: nombreMateria,
          grupo: 'Grupo 01',
          aula: aula,
          codigoAsignatura: codigo,
          nombreDocente: widget.usuario.nombre,
        ),
      ),
    );
  }

  // Abre la sesión de toma de asistencia en vivo
  void _abrirAsistenciaEnVivo(String materia, String codigo, String aula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AsistenciaEnVivoScreen(
          nombreAsignatura: materia,
          codigo: codigo,
          aula: aula,
        ),
      ),
    );
  }

  // Abre el detalle de parámetros de una sesión de clase
  void _abrirDetalleClase(String materia, String aula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleClaseScreen(
          tituloClase: 'Clase: $materia',
          aula: aula,
          horario: 'Horario Programado',
          radio: '±30m',
        ),
      ),
    );
  }

  // Permite crear una clase dentro de una asignatura ya creada (sin pedir objeto de validación)
  void _crearClaseParaAsignatura(int indexAsignatura) {
    final asig = _asignaturas[indexAsignatura];
    final TextEditingController tipoCtrl = TextEditingController();
    final TextEditingController horarioCtrl = TextEditingController();
    final TextEditingController aulaCtrl = TextEditingController();
    final TextEditingController geocercaCtrl = TextEditingController(text: '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crear Clase / Horario',
              style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Para: ${asig['nombre']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tipoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Sesión (Ej: Clase Teórica, Lab)',
                  hintText: 'Clase Teórica',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: horarioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Día y Horario (Ej: Lun y Mié 08:00 - 10:00)',
                  hintText: 'Mar y Jue 08:00 - 10:00',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: aulaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Aula / Salón (Ej: Aula 204)',
                  hintText: 'Aula 204',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: geocercaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Radio de Geocerca GPS (metros)',
                  hintText: '30',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorPrimario),
            onPressed: () {
              if (tipoCtrl.text.trim().isNotEmpty && horarioCtrl.text.trim().isNotEmpty) {
                setState(() {
                  final List clases = asig['clases'] as List;
                  clases.add({
                    'tipo': tipoCtrl.text.trim(),
                    'horario': horarioCtrl.text.trim(),
                    'aula': aulaCtrl.text.trim().isNotEmpty ? aulaCtrl.text.trim() : 'Aula 204',
                    'radio': geocercaCtrl.text.trim().isNotEmpty ? geocercaCtrl.text.trim() : '30',
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Clase programada con éxito en la asignatura!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa el tipo y horario de la clase.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Crear Clase', style: TextStyle(color: Colors.white)),
          ),
        ],
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorPrimario,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_on, color: Colors.greenAccent, size: 18),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GeoCheck',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimario),
                ),
                Text('Docente', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'DOCENTE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimario),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: colorPrimario),
            tooltip: 'Notificaciones',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await AuthService.cerrarSesion();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFEEF2FF),
              child: Icon(Icons.person, color: colorPrimario, size: 20),
            ),
          ),
        ],
      ),
      body: _construirCuerpoPestana(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indicePestana,
        onTap: (index) => setState(() => _indicePestana = index),
        selectedItemColor: colorPrimario,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Cursos'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Asistencia'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }

  /// Cambia de pantalla según la pestaña seleccionada en el BottomNavigationBar
  Widget _construirCuerpoPestana() {
    switch (_indicePestana) {
      case 0:
        return _construirPestanaInicio();
      case 1:
        return _construirPestanaCursos();
      case 2:
        return _construirPestanaAsistencia();
      case 3:
        return _construirPestanaPerfil();
      default:
        return _construirPestanaInicio();
    }
  }

  // ===========================================================================
  // PESTAÑA 0: INICIO (Dashboard Principal del Docente)
  // ===========================================================================
  Widget _construirPestanaInicio() {
    final primerNombre = widget.usuario.nombre.isNotEmpty
        ? widget.usuario.nombre.split(' ')[0]
        : 'Docente';
    final facultad = widget.usuario.facultad.isNotEmpty
        ? widget.usuario.facultad
        : 'Facultad no especificada';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo Superior
            Text(
              '¡Hola, Prof. $primerNombre! 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorPrimario),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 12, color: colorPrimario),
                      SizedBox(width: 4),
                      Text('Docente Titular', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimario)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    facultad,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tarjeta de Clase en Curso (Estado Limpio cuando no hay clase activa)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              'Sin clase activa',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      const Text('Radio Geocerca: Inactivo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No tienes clases en curso en este momento',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorPrimario),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cuando llegue el horario de tu sesión académica, podrás iniciar la telemetría perimetral y abrir la toma de lista.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  if (_asignaturas.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final primera = _asignaturas.first;
                          _abrirAsistenciaEnVivo(
                            primera['nombre'] ?? 'Materia',
                            primera['codigo'] ?? 'COD',
                            'Aula 204',
                          );
                        },
                        icon: const Icon(Icons.play_circle_outline, color: Colors.white),
                        label: const Text('Iniciar Asistencia de Clase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorPrimario,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Banner Informativo: Garantía de Presencia Física
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: colorPrimario, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Garantía de Presencia Física',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario),
                        ),
                        SizedBox(height: 2),
                        const Text(
                          'El sistema valida la presencia física del estudiante mediante geocerca GPS perimetral en tiempo real dentro del aula. Cero suplantación.',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Banner Azul: Crear Nuevo Curso Académico
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorPrimario,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Nuevo Curso Académico?',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        const Text(
                          'Configura geofences de aula y asistencia GPS.',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _abrirCrearAsignatura,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Crear Curso', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sección: Mis Asignaturas Asignadas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Asignaturas Asignadas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimario),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Ciclo 2026-II', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimario)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Si no hay asignaturas muestra estado vacío
            if (_asignaturas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.auto_stories_outlined, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 10),
                    const Text(
                      'No tienes asignaturas registradas',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorPrimario),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crea tu primer curso académico con el botón "Crear Curso" para comenzar a gestionar tus clases.',
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
                itemCount: _asignaturas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final asig = _asignaturas[index];
                  final String nombre = asig['nombre'] ?? '';
                  final String codigo = asig['codigo'] ?? 'S/C';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.menu_book, color: colorPrimario, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorPrimario),
                                  ),
                                  Text(
                                    '$codigo • ${(asig['clases'] as List?)?.length ?? 0} clases programadas',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _abrirGestionEstudiantes(nombre, 'Aula 204', codigo),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Gestionar >', style: TextStyle(fontSize: 11, color: colorPrimario, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PESTAÑA 1: CURSOS (Gestión de Asignaturas y Grupos)
  // ===========================================================================
  Widget _construirPestanaCursos() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis Asignaturas y Clases',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimario),
                    ),
                    Text('Semestre 2026-II', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: const Icon(Icons.calendar_month_outlined, size: 20, color: colorPrimario),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra de Búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar asignatura, código o grupo...',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              ),
            ),
            const SizedBox(height: 14),

            // Si no hay asignaturas muestra estado vacío
            if (_asignaturas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 44, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text(
                      'No tienes cursos registrados aún',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorPrimario),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usa el botón de abajo para programar un nuevo grupo o crear una materia académica.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _asignaturas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final asig = _asignaturas[index];
                  final String nombre = asig['nombre'] ?? '';
                  final String codigo = asig['codigo'] ?? '';
                  final List clases = (asig['clases'] as List?) ?? [];

                  return Container(
                    padding: const EdgeInsets.all(14),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(codigo, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorPrimario)),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _abrirGestionEstudiantes(nombre, 'Aula 204', codigo),
                              icon: const Icon(Icons.people_outline, size: 14),
                              label: const Text('Alumnos', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nombre,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimario),
                        ),
                        Text(
                          'Modalidad: ${asig['modalidad'] ?? 'Presencial'} • ${asig['creditos'] ?? '4'} Créditos',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        // Lista de Clases Creadas dentro de esta Asignatura
                        if (clases.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Aún no has creado clases para esta asignatura.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _crearClaseParaAsignatura(index),
                                  icon: const Icon(Icons.add, size: 14, color: colorPrimario),
                                  label: const Text(
                                    'Crear Clase / Horario',
                                    style: TextStyle(fontSize: 11, color: colorPrimario, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: colorPrimario),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          ...clases.map((clase) {
                            final String aulaClase = (clase['aula'] ?? '').toString().isNotEmpty ? clase['aula'] : 'Aula 204';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        clase['tipo'] ?? 'Clase Teórica',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorPrimario),
                                      ),
                                      Text(
                                        clase['horario'] ?? '',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '📍 $aulaClase • 📡 Geocerca: ${clase['radio']}m',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _abrirAsistenciaEnVivo(nombre, codigo, aulaClase),
                                          icon: const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                                          label: const Text('Iniciar Asistencia', style: TextStyle(fontSize: 11, color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _abrirDetalleClase(nombre, aulaClase),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Ver Parámetros', style: TextStyle(fontSize: 11, color: colorPrimario)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _crearClaseParaAsignatura(index),
                              icon: const Icon(Icons.add, size: 14, color: colorPrimario),
                              label: const Text(
                                'Agregar otra Clase a esta Asignatura',
                                style: TextStyle(fontSize: 11, color: colorPrimario, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),

            // Botón Programar Nuevo Grupo / Clase
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _abrirCrearAsignatura,
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: const Text(
                  'Programar Nuevo Grupo / Clase',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PESTAÑA 2: ASISTENCIA (Historial & Auditoría)
  // ===========================================================================
  Widget _construirPestanaAsistencia() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PORTAL DOCENTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                    Text(
                      'Historial & Auditoría',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimario),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Período 2026-II', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorPrimario)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Métricas de Historial (Vacías por defecto)
            Row(
              children: [
                Expanded(
                  child: _tarjetaMetricaHistorial('Sesiones', '0', 'dictadas', Colors.teal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tarjetaMetricaHistorial('Promedio', '0%', 'asistencia', Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tarjetaMetricaHistorial('En Riesgo', '0', '>3 faltas', Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bitácora de Sesiones
            const Text(
              'Bitácora de Sesiones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorPrimario),
            ),
            const SizedBox(height: 10),

            // Estado Vacío de la Bitácora
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
                  Icon(Icons.fact_check_outlined, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text(
                    'No hay sesiones registradas en este período',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorPrimario),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cuando abras una clase y finalices la toma de asistencia, el reporte de telemetría y quórum se archivará aquí automáticamente.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Acciones Administrativas
            const Text(
              'ACCIONES ADMINISTRATIVAS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generando Acta PDF institucional con firma criptográfica...')),
                  );
                },
                icon: const Icon(Icons.verified_user_outlined, color: Colors.white),
                label: const Text('Descargar Acta PDF con Firma Digital', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorPrimario,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exportando datos a CSV / Excel...')),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 16, color: colorPrimario),
                    label: const Text('Exportar CSV / Excel', style: TextStyle(fontSize: 11, color: colorPrimario)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Apertura de formulario de justificación médica/académica.')),
                      );
                    },
                    icon: const Icon(Icons.edit_calendar_outlined, size: 16, color: colorPrimario),
                    label: const Text('Justificar Inasistencia', style: TextStyle(fontSize: 11, color: colorPrimario)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaMetricaHistorial(String titulo, String valor, String subtitulo, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(subtitulo, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }

  // ===========================================================================
  // PESTAÑA 3: PERFIL (Datos del Docente y Ajustes)
  // ===========================================================================
  Widget _construirPestanaPerfil() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(Icons.person, color: colorPrimario, size: 40),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.usuario.nombre,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimario),
                  ),
                  Text(
                    widget.usuario.correo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Docente Acreditado', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  const Divider(height: 30),
                  ListTile(
                    leading: const Icon(Icons.school, color: colorPrimario),
                    title: const Text('Facultad', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(widget.usuario.facultad.isNotEmpty ? widget.usuario.facultad : 'No asignada', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge, color: colorPrimario),
                    title: const Text('Código Docente', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(widget.usuario.codigoMatricula.isNotEmpty ? widget.usuario.codigoMatricula : 'DOC-2026', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await AuthService.cerrarSesion();
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Cerrar Sesión Docente', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
