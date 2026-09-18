import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/models/tarea.dart';

import 'package:aptar/screens/Horario_Screen.dart';
import 'package:aptar/screens/agregar_proyecto_screen.dart';
import 'package:aptar/screens/agregar_tarea_screen.dart';
import 'package:aptar/screens/nuevo_semestre_screen.dart';
import 'package:aptar/screens/proyecto_detalle_screen.dart';
import 'package:aptar/screens/tareas_completadas_screen.dart';

import 'package:aptar/notificaciones.dart';
import 'package:aptar/models/proyecto_personal.dart';
import 'package:aptar/widgets/proyecto_card.dart';
import 'package:aptar/widgets/task_card.dart';
import 'package:aptar/widgets/local_image.dart';
import 'package:aptar/widgets/image_viewer.dart';
import 'package:aptar/widgets/dashboard/custom_header.dart';
import 'package:aptar/widgets/dashboard/dashboard_bottom_nav.dart';
import 'package:aptar/widgets/dashboard/dashboard_fab.dart';
import 'package:aptar/widgets/dashboard/empty_state.dart';
import 'package:aptar/widgets/dashboard/section_header.dart';
import 'package:aptar/theme/app_theme.dart';

class ListaTareasScreen extends StatefulWidget {
  const ListaTareasScreen({Key? key}) : super(key: key);

  @override
  State<ListaTareasScreen> createState() => _ListaTareasScreenState();
}

class _ListaTareasScreenState extends State<ListaTareasScreen>
    with WidgetsBindingObserver {
  List<Tarea> _tareas = [];
  List<ProyectoPersonal> _proyectos = [];
  final Map<int, Map<String, int>> _progresoProyectos = {};
  bool _cargando = true;
  bool _haySemestreActivo = false;
  Map<String, dynamic>? _semestreActivo;
  String? _nombreUsuario;
  int _navIndex = 0;

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
    _cargarProyectos();
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

    final semestre = await DbHelper.getSemestreActivo(usuarioId);
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

  Future<void> _cargarProyectos() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');
    if (usuarioId == null) return;

    final proyectos = await DbHelper.getProyectos(usuarioId);
    final progreso = <int, Map<String, int>>{};
    for (final p in proyectos) {
      if (p.id != null) {
        progreso[p.id!] = await DbHelper.getProgresoProyecto(p.id!);
      }
    }

    if (mounted) {
      setState(() {
        _proyectos = proyectos;
        _progresoProyectos
          ..clear()
          ..addAll(progreso);
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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
      );
    }

    final enTabEscolar = _navIndex == 0;
    final showFab = enTabEscolar ? _haySemestreActivo : true;
    final nombreCorto =
        _nombreUsuario != null ? _firstName(_nombreUsuario!) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomHeader(
              saludo: _saludoSegunHora(),
              nombreUsuario: nombreCorto,
              showMenu: enTabEscolar,
              onMenuSelected: enTabEscolar ? _onMenuSelected : null,
              menuItems: const [
                PopupMenuItem(
                  value: 'completadas',
                  child: Text('Tareas completadas'),
                ),
                PopupMenuItem(
                  value: 'horario',
                  child: Text('Horario de clases'),
                ),
                PopupMenuItem(
                  value: 'reset_semestre',
                  child: Text('Cerrar semestre e iniciar uno nuevo'),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: enTabEscolar ? _buildTabEscolar() : _buildTabPersonal(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          showFab
              ? DashboardFab(
                tooltip: enTabEscolar ? 'Nueva tarea' : 'Nuevo proyecto',
                onPressed: () => _onFabPressed(enTabEscolar),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: DashboardBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Future<void> _onMenuSelected(String value) async {
    if (value == 'completadas') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TareasCompletadasScreen()),
      );
      await _cargarTareas();
    } else if (value == 'horario') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HorarioScreen()),
      );
    } else if (value == 'reset_semestre') {
      await _confirmarYReiniciarSemestre();
    }
  }

  Future<void> _onFabPressed(bool enTabEscolar) async {
    if (enTabEscolar) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AgregarTareaScreen()),
      );
      await _cargarTareas();
    } else {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AgregarProyectoScreen()),
      );
      if (ok == true) await _cargarProyectos();
    }
  }

  Widget _buildTabEscolar() {
    if (!_haySemestreActivo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                icon: Icons.school_outlined,
                title: 'Sin semestre activo',
                subtitle:
                    'Inicia un nuevo semestre para registrar materias y tareas escolares.',
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NuevoSemestreScreen(),
                    ),
                  );
                  if (result == true) await _verificarSemestre();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Iniciar nuevo semestre'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSemestreInfo(),
        const SectionHeader(
          title: 'Tareas pendientes',
          subtitle: 'Ordenadas por fecha de entrega',
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.navy,
            onRefresh: _cargarTareas,
            child:
                _tareas.isEmpty
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      children: const [
                        EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'No hay tareas registradas',
                          subtitle:
                              'Usa el botón central para agregar tu primera tarea.',
                        ),
                      ],
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _tareas.length,
                      itemBuilder: (context, index) {
                        final tarea = _tareas[index];
                        return TaskCard(
                          tarea: tarea,
                          onTap: () => _mostrarDetallesTarea(context, tarea),
                          onCheck: () => _marcarCompletada(tarea),
                          onLongPress:
                              () => _mostrarDetallesTarea(context, tarea),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabPersonal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Proyectos personales',
          subtitle: 'Tus metas y actividades fuera de lo escolar',
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.navy,
            onRefresh: _cargarProyectos,
            child:
                _proyectos.isEmpty
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      children: const [
                        EmptyState(
                          icon: Icons.folder_open_outlined,
                          title: 'No hay proyectos personales',
                          subtitle:
                              'Usa el botón central para crear tu primer proyecto.',
                        ),
                      ],
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _proyectos.length,
                      itemBuilder: (context, index) {
                        final proyecto = _proyectos[index];
                        final progreso =
                            proyecto.id != null
                                ? _progresoProyectos[proyecto.id!]
                                : null;
                        return ProyectoCard(
                          proyecto: proyecto,
                          totalActividades: progreso?['total'] ?? 0,
                          actividadesCompletadas:
                              progreso?['completadas'] ?? 0,
                          onTap: () async {
                            await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        ProyectoDetalleScreen(proyecto: proyecto),
                              ),
                            );
                            await _cargarProyectos();
                          },
                        );
                      },
                    ),
          ),
        ),
      ],
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

    final maxDialogHeight = MediaQuery.of(context).size.height * 0.85;
    final tieneImagen =
        tarea.imagenRuta != null && tarea.imagenRuta!.isNotEmpty;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxDialogHeight),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título fijo
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

                    // Contenido scrolleable
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (tieneImagen) ...[
                              GestureDetector(
                                onTap:
                                    () => showImageViewer(
                                      context,
                                      tarea.imagenRuta!,
                                    ),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: LocalImage(
                                        path: tarea.imagenRuta,
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botones fijos
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
    final inicioIso = _semestreActivo?['fechaInicio'] as String?;
    final finIso = _semestreActivo?['fechaFin'] as String?;

    String fmt(String? iso) {
      if (iso == null || iso.isEmpty) return '—';
      final d = DateTime.tryParse(iso);
      if (d == null) return iso;
      return DateFormat('d MMM yyyy', 'es_MX').format(d);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        boxShadow: AppDecorations.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          onTap: () async {
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
              await _cargarTareas();
              setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Semestre activo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${fmt(inicioIso)} – ${fmt(finIso)}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para agregar materias',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarYReiniciarSemestre() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');

    if (usuarioId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró usuarioId. Inicia sesión otra vez.'),
        ),
      );
      return;
    }

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Iniciar nuevo semestre?'),
            content: const Text(
              'Esto borrará tus tareas, materias y horario del semestre actual.\n'
              'También se cancelarán las notificaciones programadas.\n\n'
              '¿Quieres continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí, reiniciar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      // 1) Cancelar notificaciones existentes de TODAS las tareas
      final tareas = await DbHelper.getTareas();
      for (final t in tareas) {
        if (t.id != null) {
          await Notificaciones.cancelarNotificacionesTarea(t.id!);
        }
      }

      // 2) Reset del semestre (borra materias, horarios, semestres y tareas)
      await DbHelper.resetSemestre(usuarioId);

      if (!mounted) return;

      // 3) Ir a crear semestre nuevo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NuevoSemestreScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reiniciando semestre: $e')));
    }
  }
}
