import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
//import 'dart:io';
//import 'package:flutter/services.dart';

class Notificaciones {
  static final _notificaciones = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();
    final settings = InitializationSettings(android: android, iOS: ios);

    tz.initializeTimeZones(); // Inicializar zona horaria

    await _notificaciones.initialize(settings);
  }

  static Future<void> programarNotificacion({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fecha,
  }) async {
    try {
      await _notificaciones.zonedSchedule(
        id,
        titulo,
        cuerpo,
        tz.TZDateTime.from(fecha, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_tareas',
            'Tareas',
            channelDescription: 'Recordatorios de tareas',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );

      print(
        '✅ Notificación programada para ${fecha.toIso8601String()} - $titulo',
      );
    } catch (e) {
      print('❌ Error programando notificación: $e');
    }
  }

  static Future<void> programarRecordatoriosTarea({
    required int idBase,
    required String tituloTarea,
    required DateTime fechaEntrega,
  }) async {
    final ahora = DateTime.now();

    final List<Duration> anticipos = [
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
      999, // ID único para esta prueba
      '¡Hola!',
      'Esta es una notificación de prueba 🔔',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_tareas',
          'Tareas',
          channelDescription: 'Recordatorios de tareas',
          importance: Importance.max,
          priority: Priority.high,
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
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$dia $hora:$min';
  }

  static Future<void> pruebaNotificacionEnUnMinuto() async {
    final ahora = DateTime.now();
    final enUnMinuto = ahora.add(const Duration(minutes: 1));

    await programarNotificacion(
      id: 1010,
      titulo: '⏰ Noti simple',
      cuerpo: 'Hola broo, llegó en 1 minuto sin alarmas exactas 😎',
      fecha: enUnMinuto,
    );
  }

  static Future<void> pruebaMixtaNotificacion() async {
    // Inmediata
    await _notificaciones.show(
      123,
      '🔔 Prueba inmediata',
      'Esta notificación se muestra al instante',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_tareas',
          'Tareas',
          channelDescription: 'Recordatorios de tareas',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );

    // Programada en 1 minuto
    final ahora = DateTime.now();
    final enUnMinuto = ahora.add(const Duration(minutes: 1));

    try {
      await _notificaciones.zonedSchedule(
        124,
        '📅 Programada (no exacta)',
        'Esta debería llegar aprox. en 1 minuto',
        tz.TZDateTime.from(enUnMinuto, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_tareas',
            'Tareas',
            channelDescription: 'Recordatorios de tareas',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null, // <- Muy importante
      );

      print('✅ Programada notificación aproximada (sin alarma exacta)');
    } catch (e) {
      print('❌ Error al programar programada: $e');
    }
  }
}
