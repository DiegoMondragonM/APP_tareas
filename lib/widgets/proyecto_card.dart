import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aptar/models/proyecto_personal.dart';
import 'package:aptar/theme/app_theme.dart';
import 'package:aptar/widgets/dashboard/dashboard_card.dart';
import 'package:aptar/widgets/local_image.dart';

class ProyectoCard extends StatelessWidget {
  final ProyectoPersonal proyecto;
  final int totalActividades;
  final int actividadesCompletadas;
  final VoidCallback? onTap;

  const ProyectoCard({
    super.key,
    required this.proyecto,
    required this.totalActividades,
    required this.actividadesCompletadas,
    this.onTap,
  });

  Color get _colorPrioridad {
    switch (proyecto.prioridad) {
      case 'Alta':
        return AppColors.error;
      case 'Media':
        return AppColors.warning;
      default:
        return AppColors.accent;
    }
  }

  double get _progreso {
    if (totalActividades == 0) return 0;
    return actividadesCompletadas / totalActividades;
  }

  @override
  Widget build(BuildContext context) {
    final porcentaje = (_progreso * 100).round();
    final tienePortada =
        proyecto.imagenRuta != null && proyecto.imagenRuta!.isNotEmpty;

    String fmt(DateTime? d) {
      if (d == null) return 'Sin fecha';
      return DateFormat('d MMM yyyy', 'es_MX').format(d);
    }

    return DashboardCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tienePortada)
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalImage(
                    path: proyecto.imagenRuta,
                    fit: BoxFit.cover,
                    placeholder: Container(color: AppColors.navySoft),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.navy.withValues(alpha: 0.65),
                          ],
                          stops: const [0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Text(
                      proyecto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!tienePortada) ...[
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _colorPrioridad.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.folder_open_rounded,
                          color: _colorPrioridad,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          proyecto.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PrioridadChip(
                      prioridad: proyecto.prioridad,
                      color: _colorPrioridad,
                    ),
                    _MetaRow(
                      icon: Icons.calendar_today_outlined,
                      text: '${fmt(proyecto.fechaInicio)} – ${fmt(proyecto.fechaFin)}',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progreso,
                          minHeight: 8,
                          backgroundColor: AppColors.navySoft,
                          color: _colorPrioridad,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$porcentaje%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  totalActividades == 0
                      ? 'Sin actividades'
                      : '$actividadesCompletadas de $totalActividades actividades',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioridadChip extends StatelessWidget {
  final String prioridad;
  final Color color;

  const _PrioridadChip({required this.prioridad, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        prioridad,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
