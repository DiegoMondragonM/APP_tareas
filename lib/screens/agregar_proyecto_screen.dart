import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/models/proyecto_personal.dart';
import 'package:aptar/widgets/imagen_selector_widget.dart';

class AgregarProyectoScreen extends StatefulWidget {
  const AgregarProyectoScreen({super.key});

  @override
  State<AgregarProyectoScreen> createState() => _AgregarProyectoScreenState();
}

class _AgregarProyectoScreenState extends State<AgregarProyectoScreen> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _prioridad = 'Media';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _imagenRuta;
  bool _guardando = false;

  static const _prioridades = ['Alta', 'Media', 'Baja'];

  String _formateaFecha(DateTime dt) =>
      DateFormat('EEE d MMM yyyy', 'es_MX').format(dt);

  Future<DateTime?> _seleccionarFecha(
    BuildContext context, {
    required DateTime? inicial,
    required String titulo,
    DateTime? firstDate,
  }) async {
    final ahora = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: inicial ?? ahora,
      firstDate: firstDate ?? DateTime(ahora.year - 1),
      lastDate: DateTime(2035),
      helpText: titulo,
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de inicio')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuarioId');
    if (usuarioId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el usuario')),
      );
      return;
    }

    _formKey.currentState!.save();

    final proyecto = ProyectoPersonal(
      nombre: _nombre.trim(),
      prioridad: _prioridad,
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin,
      usuarioId: usuarioId,
      imagenRuta: _imagenRuta,
    );

    setState(() => _guardando = true);
    try {
      await DbHelper.insertProyecto(proyecto);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proyecto creado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
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
          'Nuevo proyecto',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Nombre del proyecto',
                          hintText: 'Ej. Aprender Flutter',
                          prefixIcon: Icon(Icons.folder_outlined),
                        ),
                        maxLength: 80,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa un nombre';
                          }
                          if (v.trim().length < 3) {
                            return 'El nombre es muy corto';
                          }
                          return null;
                        },
                        onSaved: (v) => _nombre = v!.trim(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _prioridad,
                        decoration: const InputDecoration(
                          labelText: 'Prioridad',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items:
                            _prioridades
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _prioridad = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.play_arrow),
                        title: Text(
                          _fechaInicio == null
                              ? 'Inicio: sin fecha'
                              : 'Inicio: ${_formateaFecha(_fechaInicio!)}',
                        ),
                        trailing: FilledButton.tonalIcon(
                          onPressed: () async {
                            final f = await _seleccionarFecha(
                              context,
                              inicial: _fechaInicio,
                              titulo: 'Fecha de inicio',
                            );
                            if (f != null) {
                              setState(() {
                                _fechaInicio = f;
                                if (_fechaFin != null && _fechaFin!.isBefore(f)) {
                                  _fechaFin = null;
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_calendar),
                          label: Text(_fechaInicio == null ? 'Elegir' : 'Cambiar'),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.stop),
                        title: Text(
                          _fechaFin == null
                              ? 'Fin: sin fecha (opcional)'
                              : 'Fin: ${_formateaFecha(_fechaFin!)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_fechaFin != null)
                              IconButton(
                                onPressed: () => setState(() => _fechaFin = null),
                                icon: const Icon(Icons.clear),
                                tooltip: 'Quitar fecha fin',
                              ),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                final f = await _seleccionarFecha(
                                  context,
                                  inicial: _fechaFin ?? _fechaInicio,
                                  titulo: 'Fecha de fin (opcional)',
                                  firstDate: _fechaInicio,
                                );
                                if (f != null) setState(() => _fechaFin = f);
                              },
                              icon: const Icon(Icons.edit_calendar),
                              label: Text(_fechaFin == null ? 'Elegir' : 'Cambiar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ImagenSelectorWidget(
                imagenRuta: _imagenRuta,
                prefix: 'proyecto',
                height: 180,
                etiqueta: 'Portada del proyecto (opcional)',
                onChanged: (ruta) => setState(() => _imagenRuta = ruta),
              ),
              const SizedBox(height: 12),
              Text(
                'Podrás agregar actividades después de crear el proyecto.',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _guardando ? null : _guardar,
            icon:
                _guardando
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.save),
            label: Text(_guardando ? 'Guardando…' : 'Crear proyecto'),
          ),
        ),
      ),
    );
  }
}
