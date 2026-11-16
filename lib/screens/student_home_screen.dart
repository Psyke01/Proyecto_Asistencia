import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'mi_asistencia_screen.dart';
import 'radar_activo_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final Usuario usuario;

  const StudentHomeScreen({super.key, required this.usuario});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _indiceBottomNav = 0;
  static const Color colorPrimario = Color(0xFF0A192F);

  /// Inicia el flujo de registro de asistencia en 2 pasos (GPS → Escaneo del QR del docente)
  void _marcarAsistencia(Materia materia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RadarActivoScreen(
          usuario: widget.usuario,
          materia: materia,
          alIrAPestana: (indice) {
            if (mounted) setState(() => _indiceBottomNav = indice);
          },
        ),
      ),
    );
  }

  Future<void> _eliminarMateria(String materiaId, String nombreMateria) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Asignatura'),
        content: Text('¿Deseas remover "$nombreMateria" de tu lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuario.uid)
          .collection('materias')
          .doc(materiaId)
          .delete();
    }
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
              child: const Icon(
                Icons.location_on,
                color: Colors.greenAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GeoCheck',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                Text(
                  'Inicio',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ESTUDIANTE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        actions: [
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
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFEEF2FF),
              child: Icon(Icons.person, color: colorPrimario, size: 22),
            ),
          ),
        ],
      ),
      body: _indiceBottomNav == 2
          ? MiAsistenciaScreen(usuario: widget.usuario)
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.usuario.uid)
            .collection('materias')
            .snapshots(),
        builder: (context, snapshot) {
          final List<Materia> materias = snapshot.hasData
              ? snapshot.data!.docs
                  .map(
                    (d) => Materia.fromMap(
                      d.id,
                      d.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList()
              : [];

          // Cálculos dinámicos de métricas
          final int totalAsistidas =
              materias.fold(0, (acc, m) => acc + m.sesionesAsistidas);
          final int totalFaltas =
              materias.fold(0, (acc, m) => acc + m.sesionesFaltas);
          final int totalSesiones = totalAsistidas + totalFaltas;
          final double promedioGlobal =
              totalSesiones > 0 ? (totalAsistidas / totalSesiones) * 100 : 0.0;

          // Estado dinámico
          String estadoTexto;
          Color estadoColor;
          Color estadoBg;
          if (materias.isEmpty || totalSesiones == 0) {
            estadoTexto = 'Sin registros';
            estadoColor = Colors.grey[700]!;
            estadoBg = const Color(0xFFF0F3F9);
          } else if (promedioGlobal >= 85) {
            estadoTexto = 'Excelente estado';
            estadoColor = Colors.green;
            estadoBg = const Color(0xFFD1FAE5);
          } else if (promedioGlobal >= 70) {
            estadoTexto = 'Regular';
            estadoColor = Colors.orange;
            estadoBg = const Color(0xFFFEF3C7);
          } else {
            estadoTexto = 'En riesgo';
            estadoColor = Colors.red;
            estadoBg = const Color(0xFFFEE2E2);
          }

          // Materia en curso (si existe alguna marcada como enCurso)
          final Materia? materiaActiva = materias
              .where((m) => m.enCurso)
              .firstOrNull;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tarjeta de Perfil / Saludo
                  _construirTarjetaPerfil(),
                  const SizedBox(height: 16),

                  // 2. Tarjeta Principal de Clase de Hoy (Dinámica / Vacía)
                  _construirTarjetaClaseHoy(materiaActiva, materias.isEmpty),
                  const SizedBox(height: 20),

                  // 3. Rendimiento de Presencia (Estadísticas Dinámicas)
                  _construirRendimientoPresencia(
                    estadoTexto,
                    estadoColor,
                    estadoBg,
                    totalAsistidas,
                    totalFaltas,
                    promedioGlobal,
                    materias.isEmpty,
                  ),
                  const SizedBox(height: 20),

                  // 4. Mis Asignaturas Matriculadas (Lista Dinámica / Vacía)
                  _construirSeccionAsignaturas(materias),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceBottomNav,
        onTap: (index) => setState(() => _indiceBottomNav = index),
        selectedItemColor: colorPrimario,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'Cursos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Asistencia',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  /// 1. Tarjeta con datos reales del usuario
  Widget _construirTarjetaPerfil() {
    final primerNombre = widget.usuario.nombre.isNotEmpty
        ? widget.usuario.nombre.split(' ')[0]
        : 'Estudiante';
    final facultad = widget.usuario.facultad.isNotEmpty
        ? widget.usuario.facultad
        : 'Facultad no especificada';
    final matricula = widget.usuario.codigoMatricula.isNotEmpty
        ? widget.usuario.codigoMatricula
        : 'Sin código asignado';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEEF2FF),
            child: Icon(Icons.person, color: colorPrimario, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, $primerNombre! 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                ),
                Text(
                  facultad,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  matricula,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                Text(
                  'ESTADO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'ACTIVO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Tarjeta principal: muestra clase en curso si existe, o estado limpio si no hay
  Widget _construirTarjetaClaseHoy(Materia? materiaActiva, bool sinMaterias) {
    if (materiaActiva != null) {
      // Caso 1: Hay una materia en curso en este momento
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF132A53),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '● Clase de Hoy para Asistir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'En sesión',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${materiaActiva.nombre.toUpperCase()} (${materiaActiva.codigo})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Clase Activa',
                    style: TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              materiaActiva.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  materiaActiva.docente.isNotEmpty
                      ? materiaActiva.docente
                      : 'Docente titular',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Salón',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              materiaActiva.salon.isNotEmpty
                                  ? materiaActiva.salon
                                  : 'Aula asignada',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Horario',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              materiaActiva.horario.isNotEmpty
                                  ? materiaActiva.horario
                                  : 'Horario regular',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.my_location,
                    color: Colors.tealAccent,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Radio de geocerca activo para validar asistencia en el aula.',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _marcarAsistencia(materiaActiva),
                icon: const Icon(Icons.touch_app, color: Colors.white),
                label: const Text(
                  'MARCAR ASISTENCIA A ESTA CLASE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Caso 2: No hay clase activa en este momento (Limpio y profesional)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF132A53),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.tealAccent),
                    SizedBox(width: 4),
                    Text(
                      'Sin clases activas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'GeoCheck Campus',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'No tienes clases en curso hoy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sinMaterias
                ? 'Aún no estás matriculado en ninguna materia. Cuando tu docente o facultad te asigne a un grupo, tus clases aparecerán aquí.'
                : 'No hay ninguna sesión en desarrollo en este horario. Cuando inicie tu siguiente clase, podrás marcar asistencia automáticamente.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.tealAccent,
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La validación GPS institucional se activará al comenzar tu próxima sesión.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Rendimiento de Presencia dinámico
  Widget _construirRendimientoPresencia(
    String estadoTexto,
    Color estadoColor,
    Color estadoBg,
    int totalAsistidas,
    int totalFaltas,
    double promedioGlobal,
    bool sinMaterias,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rendimiento de Presencia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: estadoBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                estadoTexto,
                style: TextStyle(
                  fontSize: 10,
                  color: estadoColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _tarjetaMetrica(
                Icons.check_circle_outline,
                Colors.teal,
                'Asistidas',
                sinMaterias ? '0' : totalAsistidas.toString(),
                'sesiones',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _tarjetaMetrica(
                Icons.cancel_outlined,
                Colors.redAccent,
                'Faltas',
                sinMaterias ? '0' : totalFaltas.toString(),
                'registradas',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorPrimario,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_graph,
                          color: Colors.lightBlueAccent,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Global',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sinMaterias
                          ? '0%'
                          : '${promedioGlobal.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'promedio',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 4. Asignaturas: si está vacía muestra ilustración de espera, si tiene materias las lista
  Widget _construirSeccionAsignaturas(List<Materia> materias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Asignaturas Matriculadas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorPrimario,
              ),
            ),
            Text(
              materias.isEmpty
                  ? '0 asignaturas'
                  : '${materias.length} asignatura${materias.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (materias.isEmpty)
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 36,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aún no tienes asignaturas matriculadas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorPrimario,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Tus materias, horarios, salones y estadísticas de presencia se cargarán aquí automáticamente en tiempo real cuando seas matriculado.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: materias.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final materia = materias[index];
              return _tarjetaAsignatura(materia);
            },
          ),
      ],
    );
  }

  Widget _tarjetaMetrica(
    IconData icono,
    Color colorIcono,
    String titulo,
    String valor,
    String subtitulo,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: colorIcono, size: 14),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: TextStyle(color: Colors.grey[700], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colorPrimario,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaAsignatura(Materia materia) {
    return InkWell(
      onLongPress: () => _eliminarMateria(materia.id, materia.nombre),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${materia.nombre} (${materia.codigo})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colorPrimario,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (materia.enCurso) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'En curso',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      materia.totalSesiones > 0
                          ? '${materia.porcentajeAsistencia.toStringAsFixed(0)}%'
                          : '0%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: colorPrimario,
                      ),
                    ),
                    const Text(
                      'Asistencia',
                      style: TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${materia.horario} • ${materia.salon}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: materia.progresoRatio,
              backgroundColor: const Color(0xFFEEF2FF),
              color: colorPrimario,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
