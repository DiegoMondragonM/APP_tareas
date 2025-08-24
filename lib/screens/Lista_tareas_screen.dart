import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/models/tarea.dart';

import 'package:aptar/screens/Horario_Screen.dart';
import 'package:aptar/screens/agregar_tarea_screen.dart';
import 'package:aptar/screens/nuevo_semestre_screen.dart';
import 'package:aptar/screens/tareas_completadas_screen.dart';

import 'package:aptar/notificaciones.dart';
import 'package:aptar/widgets/task_card.dart';

class ListaTareasScreen extends StatefulWidget {
  const ListaTareasScreen({Key? key}) : super(key: key);

  @override
  State<ListaTareasScreen> createState() => _ListaTareasScreenState();
}

class _ListaTareasScreenState extends State<ListaTareasScreen>
    with WidgetsBindingObserver {
  List<Tarea> _tareas = [];
  bool _cargando = true;
  bool _haySemestreActivo = false;
  Map<String, dynamic>? _semestreActivo;
  String? _nombreUsuario;

  String _saludoSegunHora() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _firstName(String full) => full.trim().split(' ').first;

  @override
  void initState() {
    super.initState();
    _verificarSemestre();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final nombrePrefs = prefs.getString('nombreUsuario');
    if (nombrePrefs != null && nombrePrefs.isNotEmpty) {
      setState(() => _nombreUsuario = nombrePrefs);
      return;
    }
    // Fallback por si no está en prefs: intenta DB (ignora si no tienes ese método)
    try {
      final id = prefs.getInt('usuarioId');
      if (id != null) {
        final u = await DbHelper.getUsuario(
          id,
        ); // si no existe, comenta esta línea
        final nombre = u?['nombre'] as String?;
        if (nombre != null && nombre.isNotEmpty) {
          _nombreUsuario = nombre;
          await prefs.setString('nombreUsuario', nombre);
          if (mounted) setState(() {});
        }
      }
    } catch (_) {
      /* opcional: silencia si tu DbHelper no tiene ese método */
    }
  }

  Future<void> _verificarSemestre() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');
    if (usuarioId == null) {
      setState(() {
        _cargando = false;
        _haySemestreActivo = false;
        _semestreActivo = null;
      });
      return;
    }

    final semestre = await DbHelper.getSemestreActivo();
    if (semestre != null) {
      setState(() {
        _haySemestreActivo = true;
        _semestreActivo = semestre;
      });
      await _cargarTareas();
    } else {
      setState(() {
        _cargando = false;
        _haySemestreActivo = false;
        _semestreActivo = null;
      });
    }
  }

  Future<void> _cargarTareas() async {
    final tareas = await DbHelper.getTareas();

    // Solo pendientes
    final pendientes = tareas.where((t) => !t.completada).toList();

    // Orden: 1) vencidas primero, 2) luego las futuras más próximas, 3) sin fecha al final
    pendientes.sort((a, b) {
      final fa = a.fechadeentrega;
      final fb = b.fechadeentrega;

      // Nulos al final
      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;

      final now = DateTime.now();
      final aVencida = fa.isBefore(now);
      final bVencida = fb.isBefore(now);

      // Vencidas primero
      if (aVencida != bVencida) return aVencida ? -1 : 1;

      // Ambas vencidas o ambas futuras: la más próxima primero
      return fa.compareTo(fb);
    });

    setState(() {
      _tareas = pendientes;
      _cargando = false;
    });
  }

  Future<void> _marcarCompletada(Tarea tarea) async {
    tarea.completada = true;
    await DbHelper.actualizarTarea(tarea);
    if (tarea.id != null) {
      await Notificaciones.cancelarNotificacionesTarea(tarea.id!);
    }
    await _cargarTareas();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarea marcada como completada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final showFab = _haySemestreActivo;

    return Scaffold(
      appBar: AppBar(
        // quita el espacio reservado para el leading
        automaticallyImplyLeading: false,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),

        centerTitle: false,
        // ponlo bien pegado a la izquierda (ajusta 0–16 a tu gusto)
        titleSpacing: 12,
        toolbarHeight: 72,
        elevation: 0,

        title: Builder(
          builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreUsuario == null
                      ? '${_saludoSegunHora()} 👋'
                      : '${_saludoSegunHora()}, ${_firstName(_nombreUsuario!)} 👋',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: cs.onSurface, // ✅ color fuerte (visible)
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEE d MMM', 'es_MX').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant, // ✅ subtítulo más tenue
                  ),
                ),
              ],
            );
          },
        ),

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'completadas') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TareasCompletadasScreen(),
                  ),
                );
                await _cargarTareas();
              } else if (value == 'horario') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HorarioScreen()),
                );
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: 'completadas',
                    child: Text('Tareas completadas'),
                  ),
                  PopupMenuItem(
                    value: 'horario',
                    child: Text('Horario de clases'),
                  ),
                ],
          ),
        ],
      ),

      floatingActionButton:
          showFab
              ? FloatingActionButton.extended(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AgregarTareaScreen(),
                    ),
                  );
                  await _cargarTareas();
                },
                icon: const Icon(Icons.add),
                label: const Text('Nueva tarea'),
              )
              : null,

      body: Padding(
        padding: const EdgeInsets.all(12),
        child:
            _haySemestreActivo
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSemestreInfo(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _cargarTareas,
                        child:
                            _tareas.isEmpty
                                ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 48),
                                    Icon(Icons.inbox_outlined, size: 56),
                                    SizedBox(height: 12),
                                    Center(
                                      child: Text('No hay tareas registradas.'),
                                    ),
                                    SizedBox(height: 4),
                                    Center(
                                      child: Text(
                                        'Toca “Nueva tarea” para agregar la primera.',
                                      ),
                                    ),
                                  ],
                                )
                                : ListView.builder(
                                  itemCount: _tareas.length,
                                  itemBuilder: (context, index) {
                                    final tarea = _tareas[index];
                                    return TaskCard(
                                      tarea: tarea,
                                      onTap:
                                          () => _mostrarDetallesTarea(
                                            context,
                                            tarea,
                                          ),
                                      onCheck: () => _marcarCompletada(tarea),
                                      onLongPress:
                                          () => _mostrarDetallesTarea(
                                            context,
                                            tarea,
                                          ),
                                    );
                                  },
                                ),
                      ),
                    ),
                  ],
                )
                : Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NuevoSemestreScreen(),
                        ),
                      );
                      if (result == true) await _verificarSemestre();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Iniciar nuevo semestre'),
                  ),
                ),
      ),
    );
  }

  void _mostrarDetallesTarea(BuildContext context, Tarea tarea) {
    final ahora = DateTime.now();
    final fechaEntrega = tarea.fechadeentrega;

    if (fechaEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La tarea no tiene fecha de entrega')),
      );
      return;
    }

    final diferencia = fechaEntrega.difference(ahora);
    final vencida = diferencia.isNegative;

    String tiempoRestante;
    Color colorTiempo;

    if (vencida) {
      tiempoRestante = '¡Entrega vencida!';
      colorTiempo = Theme.of(context).colorScheme.error;
    } else {
      final dias = diferencia.inDays;
      final horas = diferencia.inHours % 24;
      final minutos = diferencia.inMinutes % 60;
      tiempoRestante = '$dias días $horas horas $minutos minutos';
      colorTiempo = dias <= 1 ? Colors.orange : Colors.green;
    }

    final textoFecha = DateFormat(
      'EEE d MMM • HH:mm',
      'es_MX',
    ).format(fechaEntrega);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tarea.titulo,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Descripción
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.description_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tarea.descripcion,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fecha
                    Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(textoFecha),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Tiempo restante
                    Row(
                      children: [
                        const Icon(Icons.hourglass_bottom_rounded),
                        const SizedBox(width: 8),
                        Text(
                          tiempoRestante,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: colorTiempo,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _marcarCompletada(tarea);
                            if (mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Finalizar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSemestreInfo() {
    final cs = Theme.of(context).colorScheme;
    final inicioIso = _semestreActivo?['fechaInicio'] as String?;
    final finIso = _semestreActivo?['fechaFin'] as String?;

    String fmt(String? iso) {
      if (iso == null || iso.isEmpty) return '—';
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      return DateFormat('EEE d MMM yyyy', 'es_MX').format(d);
    }

    return Card(
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Abre en modo “agregar materias” (fechas bloqueadas / prellenadas)
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => NuevoSemestreScreen(
                    appendMode: true,
                    fechaInicioPrefill: DateTime.tryParse(inicioIso ?? ''),
                    fechaFinPrefill: DateTime.tryParse(finIso ?? ''),
                  ),
            ),
          );

          if (ok == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Materias agregadas al semestre')),
            );
            await _cargarTareas(); // refresca la lista por si afecta algo
            setState(() {}); // refresca el card si cambia algo visual
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.school, color: cs.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Semestre activo',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: cs.onPrimaryContainer,
                        ), // hint visual
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Inicio: ${fmt(inicioIso)}',
                      style: TextStyle(color: cs.onPrimaryContainer),
                    ),
                    Text(
                      'Fin: ${fmt(finIso)}',
                      style: TextStyle(color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toca para agregar más materias',
                      style: TextStyle(
                        color: cs.onPrimaryContainer.withOpacity(0.9),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
