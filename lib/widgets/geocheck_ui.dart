import 'package:flutter/material.dart';

/// Paleta compartida por las pantallas del flujo de asistencia del estudiante.
class GeoColores {
  static const Color primario = Color(0xFF0A192F);
  static const Color azulBoton = Color(0xFF0B2A6F);
  static const Color azulProfundo = Color(0xFF001E6C);
  static const Color verdeOscuro = Color(0xFF006B45);
  static const Color menta = Color(0xFF6EE7B7);
  static const Color mentaSuave = Color(0xFFD1FAE5);
  static const Color fondo = Color(0xFFF7F9FC);
  static const Color lavanda = Color(0xFFEEF2FF);
  static const Color lavandaFondo = Color(0xFFF1F3FD);
  static const Color rojoSuave = Color(0xFFFEE2E2);
  static const Color naranjaSuave = Color(0xFFFFE4CC);
}

/// Iniciales del usuario para el avatar (ej: "Camila Suárez" → "CS")
String inicialesDe(String nombre) {
  final partes = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
}

/// Formatea una hora como 6:08 PM
String formatearHora(DateTime f, {bool conSegundos = false}) {
  final h = f.hour % 12 == 0 ? 12 : f.hour % 12;
  final m = f.minute.toString().padLeft(2, '0');
  final s = f.second.toString().padLeft(2, '0');
  final sufijo = f.hour < 12 ? 'AM' : 'PM';
  return conSegundos ? '$h:$m:$s $sufijo' : '$h:$m $sufijo';
}

const List<String> _mesesCortos = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
];

/// Formatea una fecha como 30 Sep, 2026 (o 30 Sep sin año)
String formatearFecha(DateTime f, {bool conAnio = true}) {
  final base = '${f.day} ${_mesesCortos[f.month - 1]}';
  return conAnio ? '$base, ${f.year}' : base;
}

/// Logo de GeoCheck (mismo estilo que el de la pantalla de inicio del estudiante)
class LogoGeoCheck extends StatelessWidget {
  const LogoGeoCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: GeoColores.primario,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.location_on, color: Colors.greenAccent, size: 18),
    );
  }
}

/// Avatar circular con borde, usado en la esquina superior derecha
class AvatarUsuario extends StatelessWidget {
  final String nombre;

  const AvatarUsuario({super.key, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: GeoColores.lavanda,
        child: Text(
          inicialesDe(nombre),
          style: const TextStyle(
            color: GeoColores.primario,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Insignia redondeada (ej: "Seguro", "En horario", "Presente")
class InsigniaGeo extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final Color color;
  final Color fondo;
  final double tamano;

  const InsigniaGeo({
    super.key,
    required this.texto,
    this.icono,
    this.color = GeoColores.verdeOscuro,
    this.fondo = GeoColores.mentaSuave,
    this.tamano = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: tamano + 3, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: tamano,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra superior común: atrás + logo + título + insignia + avatar
class GeoCheckAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final String nombreUsuario;
  final bool mostrarAtras;
  final Widget? insignia;
  final VoidCallback? alPresionarAtras;

  const GeoCheckAppBar({
    super.key,
    required this.titulo,
    required this.nombreUsuario,
    this.mostrarAtras = true,
    this.insignia,
    this.alPresionarAtras,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      titleSpacing: mostrarAtras ? 0 : 16,
      leading: mostrarAtras
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: GeoColores.primario),
              onPressed: alPresionarAtras ?? () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          const LogoGeoCheck(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GeoColores.primario,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      actions: [
        insignia ??
            const InsigniaGeo(
              texto: 'Seguro',
              icono: Icons.shield_outlined,
              fondo: GeoColores.menta,
            ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AvatarUsuario(nombre: nombreUsuario),
        ),
      ],
    );
  }
}

/// Indicador de los pasos del registro: 1. Presencia GPS · 2. Escaneo QR Aula
class IndicadorPasos extends StatelessWidget {
  final int pasoActual; // 1 o 2
  final int totalPasos;
  final bool conEtiquetas;
  final Widget? accionDerecha;

  const IndicadorPasos({
    super.key,
    required this.pasoActual,
    this.totalPasos = 2,
    this.conEtiquetas = false,
    this.accionDerecha,
  });

  static const _etiquetas = ['1. Presencia GPS', '2. Escaneo QR Aula'];
  static const _iconos = [Icons.check, Icons.qr_code_scanner];

  Widget _circulo(int paso) {
    final completado = paso < pasoActual;
    final actual = paso == pasoActual;

    Color fondo;
    Widget contenido;
    if (conEtiquetas) {
      // Variante con iconos (Paso 1): los pasos alcanzados se pintan en verde
      final alcanzado = paso <= pasoActual;
      fondo = alcanzado ? GeoColores.verdeOscuro : GeoColores.lavanda;
      contenido = Icon(
        alcanzado ? Icons.check : _iconos[paso - 1],
        size: 18,
        color: alcanzado ? Colors.white : Colors.grey[600],
      );
    } else if (completado) {
      fondo = GeoColores.menta;
      contenido = const Icon(Icons.check, size: 16, color: GeoColores.verdeOscuro);
    } else if (actual) {
      fondo = GeoColores.azulProfundo;
      contenido = Text('$paso',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13));
    } else {
      fondo = GeoColores.lavanda;
      contenido = Text('$paso',
          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13));
    }

    final double tam = conEtiquetas ? 34 : 30;
    return Container(
      width: tam,
      height: tam,
      decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: contenido,
    );
  }

  Widget _linea(int pasoIzquierdo) {
    // En la variante con etiquetas, la línea que sale del paso actual ya se muestra en progreso
    final activa = conEtiquetas ? pasoIzquierdo <= pasoActual : pasoIzquierdo < pasoActual;
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: activa ? GeoColores.verdeOscuro : GeoColores.lavanda,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (conEtiquetas) {
      return Column(
        children: [
          Row(
            children: [
              _circulo(1),
              _linea(1),
              _circulo(2),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(2, (i) {
              final activo = i + 1 <= pasoActual;
              return Text(
                _etiquetas[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: activo ? GeoColores.verdeOscuro : Colors.grey[600],
                ),
              );
            }),
          ),
        ],
      );
    }

    // Variante compacta (Paso 2)
    return Row(
      children: [
        _circulo(1),
        SizedBox(width: 36, child: Row(children: [_linea(1)])),
        _circulo(2),
        const Spacer(),
        accionDerecha ??
            Text(
              'PASO $pasoActual DE 2',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.grey[600],
              ),
            ),
      ],
    );
  }
}

/// Tarjeta blanca redondeada estándar del proyecto
class TarjetaGeo extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borde;

  const TarjetaGeo({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borde,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: borde != null ? Border.all(color: borde!) : null,
        boxShadow: color == Colors.white
            ? const [BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2))]
            : null,
      ),
      child: child,
    );
  }
}

/// Barra inferior del estudiante (Inicio · Cursos · Asistencia · Perfil)
class BarraInferiorEstudiante extends StatelessWidget {
  final int indiceActual;
  final ValueChanged<int> alSeleccionar;

  const BarraInferiorEstudiante({
    super.key,
    required this.indiceActual,
    required this.alSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indiceActual,
      onTap: alSeleccionar,
      selectedItemColor: GeoColores.primario,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: 'Cursos'),
        BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Asistencia'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
      ],
    );
  }
}
