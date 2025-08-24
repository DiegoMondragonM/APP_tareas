import 'dart:async';

enum AppEvent { materiasActualizadas }

class AppEvents {
  static final _controller = StreamController<AppEvent>.broadcast();
  static Stream<AppEvent> get stream => _controller.stream;
  static void emit(AppEvent e) => _controller.add(e);
}
