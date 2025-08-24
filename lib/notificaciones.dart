import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Notificaciones {
  static final _notificaciones = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    tz.initializeTimeZones();
    await _notificaciones.initialize(settings);
  }

  // Detalles “seguros” (sin opciones raras)
  static NotificationDetails _details({StyleInformation? style}) {
    final android = AndroidNotificationDetails(
      'canal_tareas',
      'Tareas',
      channelDescription: 'Recordatorios de tareas',
      importance: Importance.max,
      priority: Priority.high,
      // Solo mejoras visuales que no rompen compatibilidad:
      color: const Color(0xFF4568DC),
      styleInformation: style, // BigText opcional
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    return NotificationDetails(android: android, iOS: ios);
  }

  static Future<void> programarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fecha,
  }) async {
    try {
      final style = BigTextStyleInformation(
        cuerpo,
        contentTitle: titulo,
        summaryText: 'Recordatorio',
      );

      await _notificaciones.zonedSchedule(
        id,
        titulo,
        cuerpo,
        tz.TZDateTime.from(fecha, tz.local),
        _details(style: style),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );

      // print('✅ Notificación programada ${fecha.toIso8601String()}');
    } catch (e) {
      // Si algo falla, intenta con una noti simple como fallback:
      try {
        await _notificaciones.show(id, titulo, cuerpo, _details());
      } catch (_) {}
      // ignore: avoid_print
      print('❌ Error programando notificación: $e');
    }
  }

  static Future<void> programarRecordatoriosTarea({
    required int idBase,
    required String tituloTarea,
    required DateTime fechaEntrega,
  }) async {
    final ahora = DateTime.now();

    final anticipos = <Duration>[
      const Duration(hours: 24),
      const Duration(hours: 12),
      const Duration(hours: 6),
      const Duration(hours: 2),
      const Duration(minutes: 30),
      const Duration(minutes: 10),
    ];

    for (int i = 0; i < anticipos.length; i++) {
      final fechaNoti = fechaEntrega.subtract(anticipos[i]);
      if (fechaNoti.isBefore(ahora)) continue;

      final permitirFueraDeHorario = i >= anticipos.length - 3;
      final hora = fechaNoti.hour;
      final enHorario = hora >= 7 && hora <= 22;

      if (permitirFueraDeHorario || enHorario) {
        await programarNotificacion(
          id: idBase * 10 + i,
          titulo: 'Tarea próxima',
          cuerpo: 'Tarea "$tituloTarea" para ${_formatoDiaHora(fechaEntrega)}',
          fecha: fechaNoti,
        );
      }
    }
  }

  static Future<void> notificacionPrueba() async {
    await _notificaciones.show(
      999,
      '¡Hola!',
      'Esta es una notificación de prueba 🔔',
      _details(
        style: const BigTextStyleInformation(
          'Esta es una notificación de prueba 🔔',
          contentTitle: '¡Hola!',
          summaryText: 'Recordatorio',
        ),
      ),
    );
  }

  static Future<void> cancelarNotificacionesTarea(int idBase) async {
    for (int i = 0; i < 6; i++) {
      await _notificaciones.cancel(idBase * 10 + i);
    }
  }

  static String _formatoDiaHora(DateTime fecha) {
    final dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final dia = dias[fecha.weekday - 1];
    final hh = fecha.hour.toString().padLeft(2, '0');
    final mm = fecha.minute.toString().padLeft(2, '0');
    return '$dia $hh:$mm';
  }

  static Future<void> pruebaNotificacionEnUnMinuto() async {
    final enUnMinuto = DateTime.now().add(const Duration(minutes: 1));
    await programarNotificacion(
      id: 1010,
      titulo: '⏰ Noti simple',
      cuerpo: 'Hola broo, llegó en 1 minuto 😎',
      fecha: enUnMinuto,
    );
  }

  static Future<void> pruebaMixtaNotificacion() async {
    await notificacionPrueba();

    final enUnMinuto = DateTime.now().add(const Duration(minutes: 1));
    try {
      await _notificaciones.zonedSchedule(
        124,
        '📅 Programada (no exacta)',
        'Esta debería llegar aprox. en 1 minuto',
        tz.TZDateTime.from(enUnMinuto, tz.local),
        _details(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error al programar programada: $e');
    }
  }
}
