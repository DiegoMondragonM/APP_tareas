class ActividadProyecto {
  int? id;
  int proyectoId;
  String titulo;
  bool completada;

  ActividadProyecto({
    this.id,
    required this.proyectoId,
    required this.titulo,
    this.completada = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proyectoId': proyectoId,
      'titulo': titulo,
      'completada': completada ? 1 : 0,
    };
  }

  factory ActividadProyecto.fromMap(Map<String, dynamic> map) {
    return ActividadProyecto(
      id: map['id'] as int?,
      proyectoId: map['proyectoId'] as int,
      titulo: map['titulo'] as String,
      completada: map['completada'] == 1,
    );
  }
}
