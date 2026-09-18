import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/image_picker_helper.dart';
import '../models/actividad_proyecto.dart';
import '../models/proyecto_personal.dart';
import '../models/tarea.dart';

class DbHelper {
  static Database? _db;
  static Future<Database> getDatabase() async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tareas.db');

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _crearTablasBase(db);
        await _crearTablasProyectos(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _crearTablasProyectos(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE tareas ADD COLUMN imagenRuta TEXT',
          );
          await db.execute(
            'ALTER TABLE proyectos_personales ADD COLUMN imagenRuta TEXT',
          );
        }
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

  static Future<void> _crearTablasBase(Database db) async {
    await db.execute('''
        CREATE TABLE tareas
        (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        descripcion TEXT,
        materia TEXT,
        fechadeentrega TEXT,
        completada INTEGER,
        imagenRuta TEXT
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
        dia TEXT,
        horaInicio TEXT,
        horaFin TEXT,
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
  }

  static Future<void> _crearTablasProyectos(Database db) async {
    await db.execute('''
      CREATE TABLE proyectos_personales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        prioridad TEXT NOT NULL,
        fechaInicio TEXT NOT NULL,
        fechaFin TEXT,
        usuarioId INTEGER NOT NULL,
        imagenRuta TEXT,
        FOREIGN KEY(usuarioId) REFERENCES usuarios(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE actividades_proyecto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        proyectoId INTEGER NOT NULL,
        titulo TEXT NOT NULL,
        completada INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(proyectoId) REFERENCES proyectos_personales(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<int> insertProyecto(ProyectoPersonal proyecto) async {
    final db = await getDatabase();
    return await db.insert('proyectos_personales', proyecto.toMap());
  }

  static Future<List<ProyectoPersonal>> getProyectos(int usuarioId) async {
    final db = await getDatabase();
    final maps = await db.query(
      'proyectos_personales',
      where: 'usuarioId = ?',
      whereArgs: [usuarioId],
      orderBy: 'fechaInicio DESC',
    );
    return maps.map(ProyectoPersonal.fromMap).toList();
  }

  static Future<int> updateProyecto(ProyectoPersonal proyecto) async {
    final db = await getDatabase();
    return await db.update(
      'proyectos_personales',
      proyecto.toMap(),
      where: 'id = ?',
      whereArgs: [proyecto.id],
    );
  }

  static Future<int> deleteProyecto(int id) async {
    final db = await getDatabase();
    final rows = await db.query(
      'proyectos_personales',
      columns: ['imagenRuta'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await ImagePickerHelper.deleteImageIfExists(
        rows.first['imagenRuta'] as String?,
      );
    }
    await db.delete(
      'actividades_proyecto',
      where: 'proyectoId = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'proyectos_personales',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> insertActividad(ActividadProyecto actividad) async {
    final db = await getDatabase();
    return await db.insert('actividades_proyecto', actividad.toMap());
  }

  static Future<List<ActividadProyecto>> getActividadesPorProyecto(
    int proyectoId,
  ) async {
    final db = await getDatabase();
    final maps = await db.query(
      'actividades_proyecto',
      where: 'proyectoId = ?',
      whereArgs: [proyectoId],
      orderBy: 'completada ASC, id ASC',
    );
    return maps.map(ActividadProyecto.fromMap).toList();
  }

  static Future<int> updateActividad(ActividadProyecto actividad) async {
    final db = await getDatabase();
    return await db.update(
      'actividades_proyecto',
      actividad.toMap(),
      where: 'id = ?',
      whereArgs: [actividad.id],
    );
  }

  static Future<int> deleteActividad(int id) async {
    final db = await getDatabase();
    return await db.delete(
      'actividades_proyecto',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<Map<String, int>> getProgresoProyecto(int proyectoId) async {
    final db = await getDatabase();
    final total = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM actividades_proyecto WHERE proyectoId = ?',
            [proyectoId],
          ),
        ) ??
        0;
    final completadas = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM actividades_proyecto WHERE proyectoId = ? AND completada = 1',
            [proyectoId],
          ),
        ) ??
        0;
    return {'total': total, 'completadas': completadas};
  }
}
