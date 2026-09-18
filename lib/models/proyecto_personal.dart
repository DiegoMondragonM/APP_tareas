class ProyectoPersonal {
  int? id;
  String nombre;
  String prioridad;
  DateTime fechaInicio;
  DateTime? fechaFin;
  int usuarioId;
  String? imagenRuta;

  ProyectoPersonal({
    this.id,
    required this.nombre,
    required this.prioridad,
    required this.fechaInicio,
    this.fechaFin,
    required this.usuarioId,
    this.imagenRuta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'prioridad': prioridad,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'usuarioId': usuarioId,
      'imagenRuta': imagenRuta,
    };
  }

  factory ProyectoPersonal.fromMap(Map<String, dynamic> map) {
    return ProyectoPersonal(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      prioridad: map['prioridad'] as String,
      fechaInicio: DateTime.parse(map['fechaInicio'] as String),
      fechaFin:
          map['fechaFin'] != null
              ? DateTime.tryParse(map['fechaFin'] as String)
              : null,
      usuarioId: map['usuarioId'] as int,
      imagenRuta: map['imagenRuta'] as String?,
    );
  }
}
