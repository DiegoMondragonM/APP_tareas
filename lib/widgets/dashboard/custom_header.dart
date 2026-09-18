import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aptar/theme/app_theme.dart';

class CustomHeader extends StatelessWidget {
  final String saludo;
  final String? nombreUsuario;
  final bool showMenu;
  final void Function(String value)? onMenuSelected;
  final List<PopupMenuEntry<String>> menuItems;

  const CustomHeader({
    super.key,
    required this.saludo,
    this.nombreUsuario,
    this.showMenu = true,
    this.onMenuSelected,
    this.menuItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final titulo =
        nombreUsuario != null && nombreUsuario!.isNotEmpty
            ? '$saludo $nombreUsuario'
            : saludo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE d MMMM', 'es_MX').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child:
                showMenu && onMenuSelected != null
                    ? PopupMenuButton<String>(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppDecorations.cardShadow,
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => menuItems,
                    )
                    : null,
          ),
        ],
      ),
    );
  }
}
