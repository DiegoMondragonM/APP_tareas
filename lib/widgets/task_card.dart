import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aptar/models/tarea.dart';
import 'package:aptar/theme/app_theme.dart';
import 'package:aptar/widgets/dashboard/dashboard_card.dart';
import 'package:aptar/widgets/local_image.dart';

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
    final fecha = tarea.fechadeentrega;
    final vencida = fecha != null && fecha.isBefore(DateTime.now());
    final textoFecha =
        fecha == null
            ? 'Sin fecha'
            : DateFormat('EEE d MMM • HH:mm', 'es_MX').format(fecha);
    final tieneImagen =
        tarea.imagenRuta != null && tarea.imagenRuta!.isNotEmpty;

    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (tieneImagen) ...[
            LocalImage(
              path: tarea.imagenRuta,
              width: 52,
              height: 52,
              borderRadius: BorderRadius.circular(14),
              placeholder: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
          ] else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    vencida
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.navySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: vencida ? AppColors.error : AppColors.navy,
                size: 22,
              ),
            ),
          if (!tieneImagen) const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration:
                        tarea.completada
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MateriaChip(text: tarea.materia),
                    _MetaChip(
                      icon: Icons.schedule_rounded,
                      text: textoFecha,
                      color: vencida ? AppColors.error : AppColors.textSecondary,
                      bold: vencida,
                    ),
                    if (vencida) const _StatusChip(label: 'Vencida'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.navySoft,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onCheck,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  tarea.completada
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  color: tarea.completada ? AppColors.success : AppColors.navy,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MateriaChip extends StatelessWidget {
  final String text;
  const _MateriaChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool bold;

  const _MetaChip({
    required this.icon,
    required this.text,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
