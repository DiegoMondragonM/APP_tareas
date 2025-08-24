import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aptar/models/tarea.dart';

class TaskCard extends StatelessWidget {
  final Tarea tarea;
  final VoidCallback? onCheck;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TaskCard({
    super.key,
    required this.tarea,
    this.onCheck,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fecha = tarea.fechadeentrega;
    final vencida = fecha != null && fecha.isBefore(DateTime.now());
    final textoFecha =
        fecha == null
            ? 'Sin fecha'
            : DateFormat('EEE d MMM • HH:mm', 'es_MX').format(fecha);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          children: [
            // Franja de color
            Container(
              width: 6,
              height: 88,
              decoration: BoxDecoration(
                color: vencida ? cs.error : cs.primary,
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
                    // Título
                    Text(
                      tarea.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration:
                            tarea.completada
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Materia + fecha
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MateriaChip(text: tarea.materia),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              textoFecha,
                              style: TextStyle(
                                color: vencida ? cs.error : cs.onSurfaceVariant,
                                fontWeight:
                                    vencida ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        if (vencida)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Vencida',
                              style: TextStyle(
                                color: cs.onErrorContainer,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Botón check
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                onPressed: onCheck,
                icon: Icon(
                  tarea.completada
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                tooltip:
                    tarea.completada ? 'Completada' : 'Marcar como completada',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MateriaChip extends StatelessWidget {
  final String text;
  const _MateriaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
