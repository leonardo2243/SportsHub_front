import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sesion_provider.dart';
import '../../widgets/logo.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onCambiarVista;

  const LoginPage({super.key, this.onLoginSuccess, this.onCambiarVista});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usuarioCtrl = TextEditingController();
  final TextEditingController _contrasenaCtrl = TextEditingController();
  bool _recordarme = false;
  bool cargando = false;

  void _login() async {
    final usuario = _usuarioCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    // Validación campos vacíos
    if (usuario.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos.')),
      );
      return;
    }

    // Validación simulada: correo debe contener "@"
    if (!usuario.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El correo ingresado no es válido.')));
      return;
    }

    setState(() => cargando = true);

    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:8000/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'correo': usuario, 'contrasena': contrasena}),
          )
          .timeout(Duration(seconds: 10));

      print('Código de estado: ${response.statusCode}');
      print('Respuesta completa: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rol = data['rol'] ?? 'usuario';
        final id = data['id'];
        final sesion = Provider.of<SesionProvider>(context, listen: false);
        await sesion.iniciarSesion(id, recordar: _recordarme, rol: rol);
        widget.onLoginSuccess?.call();
      } else {
        setState(() => cargando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Correo o contraseña incorrectos.')));
        return;
      }
    } on TimeoutException {
      setState(() => cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tiempo de espera superado')));
      return;
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al conectar con el servidor: $e')));
      return;
    }

    setState(() => cargando = false);
    widget.onLoginSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Logo(),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 32),

                  // Campo de correo o usuario
                  TextField(
                    controller: _usuarioCtrl,
                    decoration: InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo de contraseña
                  TextField(
                    controller: _contrasenaCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Checkbox Recordarme
                  Row(
                    children: [
                      Checkbox(
                        value: _recordarme,
                        onChanged: (v) => setState(() => _recordarme = v!),
                      ),
                      const Text('Recordarme'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Botón Entrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cargando ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onCambiarVista,
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Indicador de carga superpuesto
          if (cargando)
            Container(
              color: Colors.black.withAlpha(50),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
