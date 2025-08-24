import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/core/app_events.dart';

class NuevoSemestreScreen extends StatefulWidget {
  // ← NUEVO: modo "agregar materias" sin crear semestre
  final bool appendMode;
  final DateTime? fechaInicioPrefill;
  final DateTime? fechaFinPrefill;

  const NuevoSemestreScreen({
    super.key,
    this.appendMode = false,
    this.fechaInicioPrefill,
    this.fechaFinPrefill,
  });

  @override
  State<NuevoSemestreScreen> createState() => _NuevoSemestreScreenState();
}

class _NuevoSemestreScreenState extends State<NuevoSemestreScreen> {
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Cada item: {
  //   'nombre': String,
  //   'aula': String,
  //   'horarios': Map<String, {'inicio': TimeOfDay?, 'fin': TimeOfDay?}>
  // }
  final List<Map<String, dynamic>> _materiasConHorario = [];

  final _diasOrden = const [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.appendMode) {
      // Prellenar fechas del semestre activo (solo lectura)
      _fechaInicio = widget.fechaInicioPrefill;
      _fechaFin = widget.fechaFinPrefill;
    }
  }

  String _fmtFecha(DateTime d) =>
      DateFormat('EEE d MMM yyyy', 'es_MX').format(d);

  bool get _formOk {
    final okMaterias = _materiasConHorario.any(_tieneAlMenosUnHorarioValido);

    if (widget.appendMode) {
      // En modo agregar: basta con que haya al menos una materia válida
      return okMaterias;
    }

    // Modo crear semestre (normal)
    final okFechas =
        _fechaInicio != null &&
        _fechaFin != null &&
        !_fechaFin!.isBefore(_fechaInicio!);
    return okFechas && okMaterias;
  }

  bool _tieneAlMenosUnHorarioValido(Map<String, dynamic> m) {
    final horarios = m['horarios'] as Map<String, Map<String, TimeOfDay?>>;
    for (final d in _diasOrden) {
      final inicio = horarios[d]?['inicio'];
      final fin = horarios[d]?['fin'];
      if (inicio != null && fin != null && _tdAfter(fin, inicio)) return true;
    }
    return false;
  }

  bool _tdAfter(TimeOfDay a, TimeOfDay b) {
    final aMin = a.hour * 60 + a.minute;
    final bMin = b.hour * 60 + b.minute;
    return aMin > bMin;
  }

  String _fmtTD(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickInicio() async {
    if (widget.appendMode) return; // deshabilitado en modo agregar
    final sel = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2035),
      helpText: 'Fecha de inicio',
    );
    if (sel != null) {
      setState(() {
        _fechaInicio = sel;
        if (_fechaFin != null && _fechaFin!.isBefore(sel)) {
          _fechaFin = sel;
        }
      });
    }
  }

  Future<void> _pickFin() async {
    if (widget.appendMode) return; // deshabilitado en modo agregar
    final base = _fechaInicio ?? DateTime.now();
    final sel = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? base,
      firstDate: base,
      lastDate: DateTime(2035),
      helpText: 'Fecha de fin',
    );
    if (sel != null) setState(() => _fechaFin = sel);
  }

  Future<void> _guardarSemestre() async {
    if (!_formOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.appendMode
                ? 'Agrega al menos una materia con horario válido'
                : 'Completa fechas y al menos una materia con horario válido',
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');
    if (usuarioId == null) return;

    try {
      // --- MODO "AGREGAR MATERIAS" (no crea semestre nuevo) ---
      if (widget.appendMode) {
        await _insertarMaterias(usuarioId);
        // Si NO usas EventBus, puedes borrar la siguiente línea:
        AppEvents.emit(AppEvent.materiasActualizadas);
        if (mounted) Navigator.pop(context, true);
        return;
      }

      // --- MODO "CREAR SEMESTRE" (flujo normal) ---
      final semestreId = await DbHelper.insertSemestre({
        'usuarioId': usuarioId,
        'fechaInicio': _fechaInicio!.toIso8601String().substring(0, 10),
        'fechaFin': _fechaFin!.toIso8601String().substring(0, 10),
      });
      assert(semestreId > 0);

      await _insertarMaterias(usuarioId);
      // Si NO usas EventBus, puedes borrar la siguiente línea:
      AppEvents.emit(AppEvent.materiasActualizadas);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  Future<void> _insertarMaterias(int usuarioId) async {
    for (final materia in _materiasConHorario) {
      final materiaId = await DbHelper.insertMateria({
        'nombre': materia['nombre'],
        'usuarioId': usuarioId,
        'aula': (materia['aula'] as String?)?.trim(),
      });

      final horarios =
          materia['horarios'] as Map<String, Map<String, TimeOfDay?>>;
      for (final dia in _diasOrden) {
        final inicio = horarios[dia]?['inicio'];
        final fin = horarios[dia]?['fin'];
        if (inicio != null && fin != null && _tdAfter(fin, inicio)) {
          await DbHelper.insertHorario({
            'materiaId': materiaId,
            'dia': dia,
            'horaInicio': _fmtTD(inicio),
            'horaFin': _fmtTD(fin),
          });
        }
      }
    }
  }

  Future<void> _agregarMateriaDialog() async {
    final nombreCtrl = TextEditingController();
    final aulaCtrl = TextEditingController();

    Map<String, Map<String, TimeOfDay?>> horarios = {
      for (final d in _diasOrden) d: {'inicio': null, 'fin': null},
    };

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> pickHora(String dia, String key) async {
              final TimeOfDay? h = await showTimePicker(
                context: ctx,
                initialTime: TimeOfDay.now(),
                helpText: key == 'inicio' ? 'Hora de inicio' : 'Hora de fin',
              );
              if (h != null) setLocal(() => horarios[dia]![key] = h);
            }

            bool tieneAlgunoValido() {
              for (final d in _diasOrden) {
                final i = horarios[d]!['inicio'];
                final f = horarios[d]!['fin'];
                if (i != null && f != null && _tdAfter(f, i)) return true;
              }
              return false;
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: const Text('Agregar materia'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextField(
                          controller: nombreCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la materia',
                            prefixIcon: Icon(Icons.menu_book_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: aulaCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Aula (opcional)',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children:
                              _diasOrden.map((dia) {
                                final i = horarios[dia]!['inicio'];
                                final f = horarios[dia]!['fin'];
                                final invalido =
                                    (i != null && f != null && !_tdAfter(f, i));

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 92,
                                          child: Text(
                                            dia,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (ctx, c) {
                                              final i2 =
                                                  horarios[dia]!['inicio'];
                                              final f2 = horarios[dia]!['fin'];
                                              final invalido2 =
                                                  (i2 != null &&
                                                      f2 != null &&
                                                      !_tdAfter(f2, i2));
                                              final isNarrow = c.maxWidth < 320;

                                              return Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                alignment: WrapAlignment.end,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    height: 40,
                                                    child: FilledButton.tonal(
                                                      onPressed:
                                                          () => pickHora(
                                                            dia,
                                                            'inicio',
                                                          ),
                                                      child: Text(
                                                        i2 == null
                                                            ? (isNarrow
                                                                ? 'Ini'
                                                                : 'Inicio')
                                                            : _fmtTD(i2),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 40,
                                                    child: FilledButton.tonal(
                                                      onPressed:
                                                          () => pickHora(
                                                            dia,
                                                            'fin',
                                                          ),
                                                      child: Text(
                                                        f2 == null
                                                            ? 'Fin'
                                                            : _fmtTD(f2),
                                                      ),
                                                    ),
                                                  ),
                                                  if (i2 != null || f2 != null)
                                                    FittedBox(
                                                      child: IconButton(
                                                        tooltip: 'Limpiar',
                                                        onPressed:
                                                            () => setLocal(() {
                                                              horarios[dia]!['inicio'] =
                                                                  null;
                                                              horarios[dia]!['fin'] =
                                                                  null;
                                                            }),
                                                        icon: const Icon(
                                                          Icons.close,
                                                        ),
                                                      ),
                                                    ),
                                                  if (invalido2)
                                                    const Icon(
                                                      Icons.error_outline,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final nombre = nombreCtrl.text.trim();
                    if (nombre.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Escribe un nombre de materia'),
                        ),
                      );
                      return;
                    }
                    if (!tieneAlgunoValido()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Configura al menos un día con horario válido',
                          ),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _materiasConHorario.add({
                        'nombre': nombre,
                        'aula': aulaCtrl.text.trim(),
                        'horarios': horarios,
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fechasSoloLectura = widget.appendMode;
    final isAppend = widget.appendMode;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appendMode ? 'Agregar materias' : 'Nuevo semestre',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fechas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // INICIO
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range),
                        title: Text(
                          _fechaInicio == null
                              ? 'Inicio'
                              : 'Inicio: ${_fmtFecha(_fechaInicio!)}',
                        ),
                        subtitle:
                            widget.appendMode
                                ? const Text('Tomado del semestre activo')
                                : null,
                        trailing:
                            widget.appendMode
                                ? null
                                : FilledButton.tonal(
                                  onPressed: _pickInicio,
                                  child: Text(
                                    _fechaInicio == null ? 'Elegir' : 'Cambiar',
                                  ),
                                ),
                      ),
                      const SizedBox(height: 6),

                      // FIN
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(
                          _fechaFin == null
                              ? 'Fin'
                              : 'Fin: ${_fmtFecha(_fechaFin!)}',
                        ),
                        subtitle:
                            (!widget.appendMode &&
                                    _fechaInicio != null &&
                                    _fechaFin != null &&
                                    _fechaFin!.isBefore(_fechaInicio!))
                                ? const Text(
                                  'La fecha de fin debe ser posterior o igual al inicio',
                                  style: TextStyle(color: Colors.red),
                                )
                                : null,
                        trailing:
                            widget.appendMode
                                ? null
                                : FilledButton.tonal(
                                  onPressed: _pickFin,
                                  child: Text(
                                    _fechaFin == null ? 'Elegir' : 'Cambiar',
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Materias
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.appendMode
                        ? 'Nuevas materias'
                        : 'Materias agregadas',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _agregarMateriaDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_materiasConHorario.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.appendMode
                        ? 'No has agregado materias nuevas. Presiona “Agregar”.'
                        : 'Aún no agregas materias. Presiona “Agregar” para empezar.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              else
                Column(
                  children:
                      _materiasConHorario.map((m) {
                        final horarios =
                            m['horarios']
                                as Map<String, Map<String, TimeOfDay?>>;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Columna texto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m['nombre'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if ((m['aula'] as String?)
                                              ?.trim()
                                              .isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              (m['aula'] as String).trim(),
                                              style: TextStyle(
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children:
                                            _diasOrden.map((d) {
                                              final i = horarios[d]!['inicio'];
                                              final f = horarios[d]!['fin'];
                                              if (i == null ||
                                                  f == null ||
                                                  !_tdAfter(f, i)) {
                                                return const SizedBox.shrink();
                                              }
                                              return Chip(
                                                label: Text(
                                                  '$d ${_fmtTD(i)}–${_fmtTD(f)}',
                                                ),
                                                avatar: const Icon(
                                                  Icons.schedule,
                                                  size: 16,
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Eliminar',
                                  onPressed:
                                      () => setState(
                                        () => _materiasConHorario.remove(m),
                                      ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
            ],
          ),
        ),
      ),

      // Botón guardar fijo
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _formOk ? _guardarSemestre : null,
            icon: const Icon(Icons.save),
            label: Text(
              widget.appendMode ? 'Guardar materias' : 'Guardar semestre',
            ),
          ),
        ),
      ),
    );
  }
}
