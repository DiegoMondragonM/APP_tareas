import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aptar/DataBase/db_helper.dart';
import 'package:aptar/screens/Lista_tareas_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _nombre = '';
  int? _usuarioId;
  String? _pinGuardado;

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('usuarioId');
    if (id != null) {
      final usuario = await DbHelper.getUsuario(id);
      if (usuario != null) {
        setState(() {
          _usuarioId = id;
          _nombre = usuario['nombre'];
          _pinGuardado = usuario['pin'];
        });
      }
    }
  }

  void _verificarPIN() {
    if (_pinController.text == _pinGuardado) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListaTareasScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN incorrecto')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_nombre.isNotEmpty) ...[
              Text(
                'Bienvenido, $_nombre',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
            ],
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Ingresa tu PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _verificarPIN,
                child: const Text('Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
