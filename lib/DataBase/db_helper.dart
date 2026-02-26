import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tarea.dart';

class DbHelper {
  static Database? _db;
  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tareas.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
            CREATE TABLE tareas
            (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT,
            descripcion TEXT,
            materia TEXT,
            fechadeentrega TEXT,
            completada INTEGER
            )
          ''');
        await db.execute('''
              CREATE TABLE usuarios
              (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombre TEXT,
              carrera TEXT,
              institucion TEXT,
              pin TEXT
              )     

          ''');
        await db.execute('''
              CREATE TABLE materias
              (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT,
                usuarioId INTEGER,
                aula TEXT,
                FOREIGN KEY(usuarioId) REFERENCES usuarios(id)
              )
          ''');
        await db.execute('''
            CREATE TABLE horarios_materia (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            materiaId INTEGER,
            dia TEXT, -- 'Lunes', 'Martes', etc.
            horaInicio TEXT, -- '07:30'
            horaFin TEXT,    -- '09:30'
            FOREIGN KEY(materiaId) REFERENCES materias(id)
            )
          ''');
        await db.execute('''CREATE TABLE semestres
          (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuarioId INTEGER,
            fechaInicio TEXT,
            fechaFin TEXT,
            FOREIGN KEY(usuarioId) REFERENCES usuarios(id)
          
          )
          ''');
      },
    );
    return _db!;
  }

  static Future<int> insertTarea(Tarea tarea) async {
    final db = await getDatabase();
    return await db.insert('tareas', tarea.toMap());
  }

  static Future<List<Tarea>> getTareas() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('tareas');
    return List.generate(maps.length, (i) => Tarea.fromMap(maps[i]));
  }

  static Future<int> updateTarea(Tarea tarea) async {
    final db = await getDatabase();
    return await db.update(
      'tareas',
      tarea.toMap(),
      where: 'id=?',
      whereArgs: [tarea.id],
    );
  }

  static Future<int> deleteTarea(int id) async {
    final db = await getDatabase();
    return await db.delete('tareas', where: 'id=?', whereArgs: [id]);
  }

  static Future<int> insertUsuario(Map<String, dynamic> usuario) async {
    final db = await getDatabase();
    return await db.insert('usuarios', usuario);
  }

  static Future<Map<String, dynamic>?> getUsuario(int id) async {
    final db = await getDatabase();
    final result = await db.query('usuarios', where: 'id=?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  static Future<int> insertSemestre(Map<String, dynamic> semestre) async {
    final db = await getDatabase();
    return await db.insert('semestres', semestre);
  }

  static Future<Map<String, dynamic>?> getSemestreActivo(int usuarioId) async {
    final db = await DbHelper.getDatabase();
    final result = await db.query(
      'semestres',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final semestre = result.first;
      return {
        'id': semestre['id'],
        'fechaInicio': semestre['fechaInicio'],
        'fechaFin': semestre['fechaFin'],
      };
    } else {
      return null;
    }
  }

  // Borra TODO lo del semestre actual del usuario (materias, horarios, tareas y el registro del semestre).
  // Útil para "cerrar semestre" e iniciar uno nuevo desde cero.
  static Future<void> resetSemestre(int usuarioId) async {
    final db = await getDatabase();
    await db.transaction((txn) async {
      // 1) Horarios de materias del usuario
      final materias = await txn.query(
        'materias',
        columns: ['id'],
        where: 'usuarioId = ?',
        whereArgs: [usuarioId],
      );
      for (final m in materias) {
        final materiaId = m['id'] as int;
        await txn.delete(
          'horarios_materia',
          where: 'materiaId = ?',
          whereArgs: [materiaId],
        );
      }

      // 2) Materias del usuario
      await txn.delete(
        'materias',
        where: 'usuarioId = ?',
        whereArgs: [usuarioId],
      );

      // 3) Semestres del usuario
      await txn.delete(
        'semestres',
        where: 'usuarioId = ?',
        whereArgs: [usuarioId],
      );

      // 4) Tareas (tu tabla no tiene usuarioId, así que se borran todas)
      await txn.delete('tareas');
    });
  }

  static Future<int> insertMateria(Map<String, dynamic> materia) async {
    final db = await getDatabase();
    return await db.insert('materias', materia);
  }

  static Future<int> insertHorario(Map<String, dynamic> horario) async {
    final db = await getDatabase();
    return await db.insert('horarios_materia', horario);
  }

  static Future<List<Map<String, dynamic>>> getHorariosPorMateria(
    int materiaId,
  ) async {
    final db = await getDatabase();
    return await db.query(
      'horarios_materia',
      where: 'materiaId = ?',
      whereArgs: [materiaId],
    );
  }

  static Future<List<Map<String, dynamic>>> getMaterias() async {
    final db = await getDatabase();
    return await db.query('materias');
  }

  static Future<int> actualizarTarea(Tarea tarea) async {
    final db = await getDatabase();
    return await db.update(
      'tareas',
      tarea.toMap(),
      where: 'id = ?',
      whereArgs: [tarea.id],
    );
  }
}
