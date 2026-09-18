import 'package:flutter/material.dart';
import 'package:aptar/notificaciones.dart';
import 'package:aptar/screens/Lista_tareas_screen.dart';
import 'package:aptar/screens/registro_usuario_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:aptar/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar zona horaria y notificaciones
  tz.initializeTimeZones();
  await Notificaciones.init();

  // Solo durante pruebas: enviar notificación en 1 minuto
  //await Notificaciones.pruebaNotificacionEnUnMinuto();
  //await Notificaciones.pruebaMixtaNotificacion();
  // Inicializar fecha en español
  await initializeDateFormatting('es', null);

  // Pedir permisos de notificaciones si es Android 13+
  await pedirPermisosNotificaciones();

  // Obtener usuario guardado
  final prefs = await SharedPreferences.getInstance();
  final usuarioId = prefs.getInt('usuarioId');

  runApp(MyApp(usuarioId: usuarioId));
}

Future<void> pedirPermisosNotificaciones() async {
  if (Platform.isAndroid) {
    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt >= 33) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final int? usuarioId;
  const MyApp({super.key, required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Gestor de tareas',

      // Forzamos español de México
      locale: const Locale('es', 'MX'),

      // Incluye es_MX y un fallback a es (por si algún paquete no trae variante MX)
      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('es'),
        Locale('en'), // opcional como respaldo
      ],

      // Delegadas oficiales de Flutter (Material, Widgets y Cupertino)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.light,
      home:
          usuarioId == null
              ? const RegistroUsuarioScreen()
              : const ListaTareasScreen(),
    );
  }
}
