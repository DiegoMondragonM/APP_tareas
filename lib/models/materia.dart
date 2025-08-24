class Materia {
  final int? id;
  final String nombre;
  final int semestreId;
  final Map<String, String> horario;
  Materia({
    this.id,
    required this.nombre,
    required this.semestreId,
    required this.horario,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'semestreId': semestreId,
      'horario': horario.toString(),
    };
  }

  factory Materia.fromMap(Map<String, dynamic> map) {
    return Materia(
      id: map['id'],
      nombre: map['nombre'],
      semestreId: map['semestreId'],
      horario: Map<String, String>.from(_parseHorario(map['horario'])),
    );
  }

  static Map<String, String> _parseHorario(String data) {
    // convierte de texto a mapa
    data = data.replaceAll(RegExp(r'[\{\}]'), '');
    final pairs = data.split(',');
    return {
      for (var p in pairs) p.split(':')[0].trim(): p.split(':')[1].trim(),
    };
  }
}
