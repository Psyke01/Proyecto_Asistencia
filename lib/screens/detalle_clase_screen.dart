import 'package:flutter/material.dart';

/// Pantalla de Detalle y Parámetros de una Clase Programada.
/// Permite configurar la geocerca perimetral GPS y la tolerancia de retraso.
class DetalleClaseScreen extends StatefulWidget {
  final String tituloClase;
  final String horario;
  final String aula;
  final String radio;

  const DetalleClaseScreen({
    super.key,
    this.tituloClase = 'Clase Programada',
    this.horario = 'Horario no definido',
    this.aula = 'Aula Asignada',
    this.radio = '±30m',
  });

  @override
  State<DetalleClaseScreen> createState() => _DetalleClaseScreenState();
}

class _DetalleClaseScreenState extends State<DetalleClaseScreen> {
  static const Color colorPrimario = Color(0xFF0A192F);

  int _toleranciaMinutos = 15;

  void _configurarParametros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Parámetros de la Clase',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimario),
              ),
              const SizedBox(height: 14),
              Text(
                'Tolerancia de ingreso: $_toleranciaMinutos minutos',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _toleranciaMinutos.toDouble(),
                min: 5,
                max: 30,
                divisions: 5,
                label: '$_toleranciaMinutos min',
                activeColor: colorPrimario,
                onChanged: (val) {
                  setModalState(() => _toleranciaMinutos = val.round());
                  setState(() => _toleranciaMinutos = val.round());
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: colorPrimario),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Guardar Parámetros', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
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
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text('Seguro', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
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
        child: Column(
          children: [
            // Área de mapa / radar ilustrado
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 8),
                      ),
                      child: const Icon(Icons.location_searching, size: 54, color: colorPrimario),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Geocerca Perimetral Activa',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorPrimario),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Radio configurado a ${widget.radio} para ${widget.aula}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // Tarjeta Inferior de Parámetros de Sesión
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(widget.horario, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        ),
                      ),
                      const Icon(Icons.desktop_windows_outlined, size: 20, color: colorPrimario),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.tituloClase,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimario),
                  ),
                  Text('📍 ${widget.aula}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),

                  // Mini Tarjetas de Geocerca y Objeto
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: Colors.teal),
                                  SizedBox(width: 4),
                                  Text('Geocerca', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Radio ${widget.radio}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const Text('Calibrado', style: TextStyle(fontSize: 9, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.gps_fixed, size: 14, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('Validación GPS', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text('Alta Precisión', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Sincronizado', style: TextStyle(fontSize: 9, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fila Parámetros y Tolerancia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _configurarParametros,
                        icon: const Icon(Icons.tune, size: 14, color: colorPrimario),
                        label: const Text('Parámetros de clase', style: TextStyle(fontSize: 11, color: colorPrimario)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      Text('Tolerancia: $_toleranciaMinutos min', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Botón Programar Nueva Clase
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.add_circle_outline, color: colorPrimario),
                      label: const Text(
                        'Programar Nueva Clase para Asignatura',
                        style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEEF2FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
