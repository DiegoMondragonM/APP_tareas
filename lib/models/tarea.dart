class Tarea {
  int? id;
  String titulo;
  String descripcion;
  String materia;
  DateTime? fechadeentrega;
  bool completada;

  Tarea({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.materia,
    required this.fechadeentrega,
    this.completada = false,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'materia': materia,
      'fechadeentrega': fechadeentrega?.toIso8601String(),
      'completada': completada ? 1 : 0,
    };
  }

  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'],
      titulo: map['titulo'],
      descripcion: map['descripcion'],
      materia: map['materia'],
      fechadeentrega: DateTime.tryParse(map['fechadeentrega']),
      completada: map['completada'] == 1,
    );
  }
}
