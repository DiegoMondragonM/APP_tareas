import 'package:flutter/material.dart';
import 'package:aptar/DataBase/db_helper.dart';
import 'dart:async';
import 'package:aptar/core/app_events.dart';

class HorarioScreen extends StatefulWidget {
  const HorarioScreen({super.key});

  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  StreamSubscription<AppEvent>? _sub;
  final List<String> _dias = const [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  // Clases estructuradas por día (para UI más bonita)
  final Map<String, List<_Clase>> _clasesPorDia = {
    'Lunes': [],
    'Martes': [],
    'Miércoles': [],
    'Jueves': [],
    'Viernes': [],
  };

  late final PageController _pageController;
  int _indexDia = 0;
  @override
  void initState() {
    super.initState();
    _indexDia = _indiceSeguroDeHoy();
    _pageController = PageController(initialPage: _indexDia);
    _cargarHorario();

    _sub = AppEvents.stream.listen((e) {
      if (e == AppEvent.materiasActualizadas) {
        _cargarHorario();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Horario actualizado')));
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  int _indiceSeguroDeHoy() {
    // Mapea hoy (1=Mon..7=Sun) a índice 0..4; si es sábado/domingo → Lunes (0)
    final wd = DateTime.now().weekday;
    return (wd >= 1 && wd <= 5) ? wd - 1 : 0;
  }

  Future<void> _cargarHorario() async {
    // Limpia
    for (final d in _dias) {
      _clasesPorDia[d] = [];
    }

    final materias = await DbHelper.getMaterias();
    for (var materia in materias) {
      final String nombre = (materia['nombre'] ?? '').toString();
      final String? aula = materia['aula']?.toString();
      final horarios = await DbHelper.getHorariosPorMateria(materia['id']);

      for (var h in horarios) {
        final String dia = (h['dia'] ?? '').toString();
        final String hi = (h['horaInicio'] ?? '').toString(); // "HH:mm"
        final String hf = (h['horaFin'] ?? '').toString(); // "HH:mm"

        // Valida día soportado
        if (!_clasesPorDia.containsKey(dia)) continue;

        final start = _parseTimeOfDay(hi);
        final end = _parseTimeOfDay(hf);
        if (start == null || end == null) continue;

        _clasesPorDia[dia]!.add(
          _Clase(
            materia: nombre,
            horaInicio: hi,
            horaFin: hf,
            aula: aula,
            start: start,
            end: end,
          ),
        );
      }
    }

    // Ordena por hora de inicio
    for (final d in _dias) {
      _clasesPorDia[d]!.sort((a, b) {
        final diffH = a.start.hour.compareTo(b.start.hour);
        return diffH != 0 ? diffH : a.start.minute.compareTo(b.start.minute);
      });
    }

    if (mounted) setState(() {});
  }

  TimeOfDay? _parseTimeOfDay(String hhmm) {
    try {
      final parts = hhmm.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  bool _esHoy(String dia) {
    final nombres7 = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    final hoyNombre = nombres7[DateTime.now().weekday - 1];
    return dia == hoyNombre;
  }

  bool _enCursoHoy(_Clase c, String dia) {
    if (!_esHoy(dia)) return false;
    final now = TimeOfDay.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = c.start.hour * 60 + c.start.minute;
    final endMin = c.end.hour * 60 + c.end.minute;
    return nowMin >= startMin && nowMin <= endMin;
    // (Si quieres “próxima clase” podrías checar nowMin < startMin y delta < X)
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Horario de clases',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          IconButton(
            tooltip: 'Ir a hoy',
            onPressed: () {
              final idx = _indiceSeguroDeHoy();
              _pageController.animateToPage(
                idx,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() => _indexDia = idx);
            },
            icon: const Icon(Icons.today),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: _cargarHorario,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          // Chips de días
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _dias.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = _dias[i];
                final selected = i == _indexDia;
                final esHoy = _esHoy(d);
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(d),
                      if (esHoy) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, size: 16),
                      ],
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                    setState(() => _indexDia = i);
                  },
                );
              },
            ),
          ),

          // Contenido
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarHorario,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _dias.length,
                onPageChanged: (i) => setState(() => _indexDia = i),
                itemBuilder: (context, index) {
                  final dia = _dias[index];
                  final clases = _clasesPorDia[dia] ?? [];
                  final esHoy = _esHoy(dia);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // Header del día
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dia.toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: esHoy ? cs.primary : cs.onSurface,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if (esHoy) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'HOY',
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (clases.isEmpty) ...[
                        const SizedBox(height: 48),
                        Icon(
                          Icons.event_busy,
                          size: 56,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        const Center(child: Text('No hay clases registradas.')),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Agrega materias y horarios desde “Nuevo semestre”.',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ] else ...[
                        for (final c in clases)
                          _ClaseCard(c: c, destacar: _enCursoHoy(c, dia)),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Widgets & Model internos ======

class _Clase {
  final String materia;
  final String horaInicio; // "HH:mm"
  final String horaFin; // "HH:mm"
  final String? aula;
  final TimeOfDay start;
  final TimeOfDay end;

  _Clase({
    required this.materia,
    required this.horaInicio,
    required this.horaFin,
    required this.aula,
    required this.start,
    required this.end,
  });
}

class _ClaseCard extends StatelessWidget {
  final _Clase c;
  final bool destacar;

  const _ClaseCard({required this.c, required this.destacar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Row(
          // ✅ Evita STRETCH dentro de ListView
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Barra con altura fija
            Container(
              width: 6,
              height: 72, // o 80 si te gusta más alta
              decoration: BoxDecoration(
                color: destacar ? cs.primary : cs.primaryContainer,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Materia + chip "En curso"
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.materia,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: destacar ? cs.primary : cs.onSurface,
                            ),
                          ),
                        ),
                        if (destacar)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'En curso',
                              style: TextStyle(
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Hora
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '${c.horaInicio} – ${c.horaFin}',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),

                    // Aula (si hay)
                    if ((c.aula ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              c.aula!.trim(),
                              style: TextStyle(color: cs.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
