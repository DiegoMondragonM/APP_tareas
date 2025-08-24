import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/screens/Lista_tareas_screen.dart';

class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({Key? key}) : super(key: key);

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _carreraCtrl = TextEditingController();
  final _institucionCtrl = TextEditingController();

  final _focusNombre = FocusNode();
  final _focusCarrera = FocusNode();
  final _focusInstitucion = FocusNode();

  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _carreraCtrl.dispose();
    _institucionCtrl.dispose();
    _focusNombre.dispose();
    _focusCarrera.dispose();
    _focusInstitucion.dispose();
    super.dispose();
  }

  String? _required(String? v, {String campo = 'Este campo'}) {
    if (v == null || v.trim().isEmpty) return '$campo es obligatorio';
    if (v.trim().length < 2) return '$campo es demasiado corto';
    return null;
  }

  Future<void> _guardarUsuario() async {
    // cierra teclado
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final usuario = {
        'nombre': _nombreCtrl.text.trim(),
        'carrera': _carreraCtrl.text.trim(),
        'institucion': _institucionCtrl.text.trim(),
      };

      final id = await DbHelper.insertUsuario(usuario);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuarioId', id);
      await prefs.setString('nombreUsuario', usuario['nombre'] ?? '');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ListaTareasScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
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
          'Registro de usuario',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header bonito
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¡Bienvenido! Completa tus datos para personalizar tu experiencia.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Form
              Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nombreCtrl,
                            focusNode: _focusNombre,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              hintText: 'Ej. Juan Pérez',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) => _required(v, campo: 'Nombre'),
                            onFieldSubmitted:
                                (_) => _focusCarrera.requestFocus(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _carreraCtrl,
                            focusNode: _focusCarrera,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.sentences,
                            autofillHints: const [AutofillHints.jobTitle],
                            decoration: const InputDecoration(
                              labelText: 'Carrera',
                              hintText: 'Ej. Ingeniería en Sistemas',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            validator: (v) => _required(v, campo: 'Carrera'),
                            onFieldSubmitted:
                                (_) => _focusInstitucion.requestFocus(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _institucionCtrl,
                            focusNode: _focusInstitucion,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [
                              AutofillHints.organizationName,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Institución',
                              hintText: 'Ej. Universidad de…',
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                            validator:
                                (v) => _required(v, campo: 'Institución'),
                            onFieldSubmitted: (_) => _guardarUsuario(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
            onPressed: _guardando ? null : _guardarUsuario,
            icon:
                _guardando
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.check),
            label: Text(_guardando ? 'Guardando…' : 'Registrar'),
          ),
        ),
      ),
    );
  }
}
