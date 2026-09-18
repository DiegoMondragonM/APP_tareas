import 'package:flutter/material.dart';
import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/models/tarea.dart';
import 'package:intl/intl.dart';
import 'package:aptar/notificaciones.dart';
import 'package:aptar/widgets/imagen_selector_widget.dart';

class AgregarTareaScreen extends StatefulWidget {
  const AgregarTareaScreen({Key? key}) : super(key: key);

  @override
  State<AgregarTareaScreen> createState() => _AgregarTareaScreenState();
}

class _AgregarTareaScreenState extends State<AgregarTareaScreen> {
  final _formKey = GlobalKey<FormState>();

  String _titulo = '';
  String _descripcion = '';
  String _materia = '';
  List<String> _materias = [];
  String? _materiaSeleccionada;
  DateTime? _fechaHoraEntrega;
  String? _imagenRuta;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
  }

  Future<void> _cargarMaterias() async {
    final materias = await DbHelper.getMaterias();
    setState(() {
      _materias = materias.map<String>((m) => m['nombre'] as String).toList();
      if (_materias.isNotEmpty) {
        _materiaSeleccionada ??= _materias.first;
      }
    });
  }

  Future<DateTime?> _seleccionarFechaHora(BuildContext context) async {
    final ahora = DateTime.now();
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHoraEntrega ?? ahora,
      firstDate: DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
      ), // no fechas pasadas
      lastDate: DateTime(2030),
      helpText: 'Selecciona la fecha de entrega',
    );
    if (fecha == null) return null;

    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime:
          _fechaHoraEntrega != null
              ? TimeOfDay.fromDateTime(_fechaHoraEntrega!)
              : TimeOfDay.now(),
      helpText: 'Selecciona la hora de entrega',
    );
    if (hora == null) return null;

    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  String _formateaFecha(DateTime dt) =>
      DateFormat('EEE d MMM yyyy • HH:mm', 'es_MX').format(dt);

  Future<void> _guardarTarea() async {
    if (_fechaHoraEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha y hora de entrega')),
      );
      return;
    }
    if (_materiaSeleccionada == null || _materiaSeleccionada!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una materia')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final nuevaTarea = Tarea(
      titulo: _titulo.trim(),
      descripcion: _descripcion.trim(),
      materia: _materia.trim(),
      fechadeentrega: _fechaHoraEntrega,
      imagenRuta: _imagenRuta,
    );

    setState(() => _guardando = true);
    try {
      final id = await DbHelper.insertTarea(nuevaTarea);

      await Notificaciones.programarRecordatoriosTarea(
        idBase: id,
        tituloTarea: nuevaTarea.titulo,
        fechaEntrega: nuevaTarea.fechadeentrega!,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarea guardada')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agregar tarea',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sección: Datos principales
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          hintText: 'Ej. Exposición de telecom',
                          prefixIcon: Icon(Icons.title),
                        ),
                        maxLength: 60,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa un título';
                          }
                          if (v.trim().length < 3) {
                            return 'El título es muy corto';
                          }
                          return null;
                        },
                        onSaved: (v) => _titulo = v!.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Descripción (opcional)',
                          hintText: 'Puntos clave, links, indicaciones…',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        maxLines: null,
                        maxLength: 800,
                                                validator: (v) {
                          if (v == null) return null;
                          if (v.length > 800) return 'Máximo 800 caracteres';
                          return null;
                        },
onSaved: (v) => _descripcion = v?.trim() ?? '',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              ImagenSelectorWidget(
                imagenRuta: _imagenRuta,
                prefix: 'tarea',
                height: 140,
                etiqueta: 'Imagen de la tarea (opcional)',
                onChanged: (ruta) => setState(() => _imagenRuta = ruta),
              ),

              const SizedBox(height: 12),

              // Sección: Materia
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _materiaSeleccionada,
                        items:
                            _materias
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        decoration: const InputDecoration(
                          labelText: 'Materia',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                        ),
                        onChanged: (value) {
                          setState(() => _materiaSeleccionada = value);
                        },
                        validator:
                            (v) =>
                                (v == null || v.isEmpty)
                                    ? 'Selecciona una materia'
                                    : null,
                        onSaved: (v) => _materia = v ?? '',
                      ),
                      if (_materias.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'No tienes materias registradas. Ve a “Nuevo semestre” para agregarlas.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Sección: Fecha y hora
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(
                          _fechaHoraEntrega == null
                              ? 'Entrega: sin fecha'
                              : 'Entrega: ${_formateaFecha(_fechaHoraEntrega!)}',
                        ),
                        subtitle: Text(
                          _fechaHoraEntrega == null
                              ? 'Selecciona fecha y hora'
                              : 'Se programarán recordatorios',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        trailing: FilledButton.tonalIcon(
                          onPressed: () async {
                            final resultado = await _seleccionarFechaHora(
                              context,
                            );
                            if (resultado != null) {
                              setState(() => _fechaHoraEntrega = resultado);
                            }
                          },
                          icon: const Icon(Icons.edit_calendar),
                          label: Text(
                            _fechaHoraEntrega == null ? 'Elegir' : 'Cambiar',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 90), // espacio para el botón inferior
            ],
          ),
        ),
      ),

      // Botón fijo inferior
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardarTarea,
            icon:
                _guardando
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            label: Text(_guardando ? 'Guardando…' : 'Guardar tarea'),
          ),
        ),
      ),
    );
  }
}
