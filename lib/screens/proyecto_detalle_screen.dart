import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/models/actividad_proyecto.dart';
import 'package:aptar/models/proyecto_personal.dart';
import 'package:aptar/core/image_picker_helper.dart';
import 'package:aptar/widgets/local_image.dart';

class ProyectoDetalleScreen extends StatefulWidget {
  final ProyectoPersonal proyecto;

  const ProyectoDetalleScreen({super.key, required this.proyecto});

  @override
  State<ProyectoDetalleScreen> createState() => _ProyectoDetalleScreenState();
}

class _ProyectoDetalleScreenState extends State<ProyectoDetalleScreen> {
  late ProyectoPersonal _proyecto;
  List<ActividadProyecto> _actividades = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _proyecto = widget.proyecto;
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    if (_proyecto.id == null) return;
    final lista = await DbHelper.getActividadesPorProyecto(_proyecto.id!);
    if (mounted) {
      setState(() {
        _actividades = lista;
        _cargando = false;
      });
    }
  }

  int get _completadas => _actividades.where((a) => a.completada).length;

  double get _progreso {
    if (_actividades.isEmpty) return 0;
    return _completadas / _actividades.length;
  }

  Future<void> _agregarActividad() async {
    final controller = TextEditingController();
    final titulo = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nueva actividad'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Descripción de la actividad',
                hintText: 'Ej. Instalar Flutter SDK',
              ),
              maxLength: 120,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final t = controller.text.trim();
                  if (t.length >= 2) Navigator.pop(ctx, t);
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
    );

    if (titulo == null || titulo.isEmpty || _proyecto.id == null) return;

    final actividad = ActividadProyecto(
      proyectoId: _proyecto.id!,
      titulo: titulo,
    );
    await DbHelper.insertActividad(actividad);
    await _cargarActividades();
  }

  Future<void> _toggleActividad(ActividadProyecto actividad) async {
    actividad.completada = !actividad.completada;
    await DbHelper.updateActividad(actividad);
    await _cargarActividades();
  }

  Future<void> _eliminarActividad(ActividadProyecto actividad) async {
    if (actividad.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar actividad'),
            content: Text('¿Eliminar "${actividad.titulo}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (confirmar != true) return;
    await DbHelper.deleteActividad(actividad.id!);
    await _cargarActividades();
  }

  Future<void> _eliminarProyecto() async {
    if (_proyecto.id == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar proyecto'),
            content: Text(
              '¿Eliminar "${_proyecto.nombre}" y todas sus actividades?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (confirmar != true) return;
    await DbHelper.deleteProyecto(_proyecto.id!);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('EEE d MMM yyyy', 'es_MX').format(d);
  }

  Future<void> _cambiarPortada() async {
    final ruta = await ImagePickerHelper.pickAndSaveImage(
      context,
      prefix: 'proyecto',
    );
    if (ruta == null || _proyecto.id == null) return;

    final anterior = _proyecto.imagenRuta;
    _proyecto.imagenRuta = ruta;
    await DbHelper.updateProyecto(_proyecto);
    await ImagePickerHelper.deleteImageIfExists(anterior);

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final porcentaje = (_progreso * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(_proyecto.nombre),
        actions: [
          IconButton(
            onPressed: _eliminarProyecto,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar proyecto',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarActividad,
        icon: const Icon(Icons.add),
        label: const Text('Actividad'),
      ),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _cargarActividades,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InkWell(
                            onTap: _cambiarPortada,
                            child: SizedBox(
                              height: 160,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  LocalImage(
                                    path: _proyecto.imagenRuta,
                                    fit: BoxFit.cover,
                                    placeholder: Container(
                                      color: cs.surfaceContainerHighest,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 40,
                                            color: cs.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Agregar portada',
                                            style: TextStyle(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: FilledButton.tonalIcon(
                                      onPressed: _cambiarPortada,
                                      icon: const Icon(Icons.edit, size: 18),
                                      label: Text(
                                        _proyecto.imagenRuta == null
                                            ? 'Portada'
                                            : 'Cambiar',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.flag, color: cs.primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Prioridad: ${_proyecto.prioridad}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: cs.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Inicio: ${_fmt(_proyecto.fechaInicio)}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event,
                                      color: cs.onSurfaceVariant,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Fin: ${_fmt(_proyecto.fechaFin)}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: _progreso,
                                          minHeight: 10,
                                          backgroundColor:
                                              cs.surfaceContainerHighest,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$porcentaje%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _actividades.isEmpty
                                      ? 'Sin actividades aún'
                                      : '$_completadas de ${_actividades.length} completadas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Actividades',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_actividades.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.checklist,
                              size: 48,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay actividades',
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Toca "Actividad" para agregar la primera.',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._actividades.map(
                        (a) => Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: a.completada,
                              onChanged: (_) => _toggleActividad(a),
                            ),
                            title: Text(
                              a.titulo,
                              style: TextStyle(
                                decoration:
                                    a.completada
                                        ? TextDecoration.lineThrough
                                        : null,
                                color:
                                    a.completada
                                        ? cs.onSurfaceVariant
                                        : null,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _eliminarActividad(a),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
    );
  }
}
