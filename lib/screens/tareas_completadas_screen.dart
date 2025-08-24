import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/models/tarea.dart';
import 'package:aptar/notificaciones.dart';

class TareasCompletadasScreen extends StatefulWidget {
  const TareasCompletadasScreen({super.key});

  @override
  State<TareasCompletadasScreen> createState() =>
      _TareasCompletadasScreenState();
}

class _TareasCompletadasScreenState extends State<TareasCompletadasScreen> {
  List<Tarea> _tareasCompletadas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTareasCompletadas();
  }

  Future<void> _cargarTareasCompletadas() async {
    final tareas = await DbHelper.getTareas();
    final completadas =
        tareas.where((t) => t.completada).toList()..sort((a, b) {
          final da = a.fechadeentrega;
          final db = b.fechadeentrega;
          // Más recientes primero; nulos al final
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });

    setState(() {
      _tareasCompletadas = completadas;
      _cargando = false;
    });
  }

  Future<void> _restaurarTarea(Tarea tarea) async {
    final ahora = DateTime.now();
    tarea.completada = false;
    await DbHelper.actualizarTarea(tarea);

    // Reprograma recordatorios solo si tiene fecha futura
    final f = tarea.fechadeentrega;
    if (tarea.id != null && f != null && f.isAfter(ahora)) {
      await Notificaciones.programarRecordatoriosTarea(
        idBase: tarea.id!,
        tituloTarea: tarea.titulo,
        fechaEntrega: f,
      );
    }

    // Quita de la lista y refresca UI
    _tareasCompletadas.removeWhere((t) => t.id == tarea.id);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            f != null && f.isAfter(ahora)
                ? 'Tarea restaurada y recordatorios reprogramados.'
                : 'Tarea restaurada (sin recordatorios porque la fecha ya pasó).',
          ),
        ),
      );
    }
  }

  Future<void> _restaurarTodas() async {
    if (_tareasCompletadas.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Restaurar todas'),
            content: const Text(
              '¿Quieres restaurar todas las tareas completadas?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restaurar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    // Copia para evitar modificar la lista mientras iteramos sobre ella
    final copia = List<Tarea>.from(_tareasCompletadas);
    for (final t in copia) {
      await _restaurarTarea(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tareas completadas',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _cargarTareasCompletadas,
            icon: const Icon(Icons.refresh),
          ),
          if (_tareasCompletadas.isNotEmpty)
            IconButton(
              tooltip: 'Restaurar todas',
              onPressed: _restaurarTodas,
              icon: const Icon(Icons.settings_backup_restore),
            ),
        ],
      ),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _cargarTareasCompletadas,
                child:
                    _tareasCompletadas.isEmpty
                        ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Center(
                              child: Text('No hay tareas completadas.'),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                'Cuando marques tareas como finalizadas, aparecerán aquí.',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          itemCount: _tareasCompletadas.length,
                          itemBuilder: (context, index) {
                            final tarea = _tareasCompletadas[index];
                            return Dismissible(
                              key: ValueKey(
                                tarea.id ?? '${tarea.titulo}-$index',
                              ),
                              direction: DismissDirection.startToEnd,
                              background: _restoreBg(cs),
                              onDismissed: (_) => _restaurarTarea(tarea),
                              child: _CompletedTaskCard(
                                tarea: tarea,
                                onRestore: () => _restaurarTarea(tarea),
                              ),
                            );
                          },
                        ),
              ),
    );
  }

  Widget _restoreBg(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.settings_backup_restore, color: cs.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            'Restaurar',
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Tarjeta elegante para completadas ----------

class _CompletedTaskCard extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback onRestore;

  const _CompletedTaskCard({required this.tarea, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = tarea.fechadeentrega;
    final fechaTexto =
        f == null
            ? 'Sin fecha'
            : DateFormat('EEE d MMM • HH:mm', 'es_MX').format(f);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onRestore, // tap rápido para restaurar si quieres
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra lateral
            Container(
              width: 6,
              height: 72,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título tachado
                    Text(
                      tarea.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: cs.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Fecha
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Entrega: $fechaTexto',
                            style: TextStyle(color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Botón restaurar
            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: FilledButton.tonalIcon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.settings_backup_restore),
                    label: const Text('Restaurar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
