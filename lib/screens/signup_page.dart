import 'package:flutter/material.dart';
import '../../widgets/logo.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  final VoidCallback? onCambiarVista;
  final VoidCallback? onRegistroSuccess;

  const SignupPage({super.key, this.onCambiarVista, this.onRegistroSuccess});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _contrasenaCtrl = TextEditingController();

  bool cargando = false;

  void _registrarse() async {
    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final contrasena = _contrasenaCtrl.text.trim();

    if (nombre.isEmpty || correo.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios.'),
        ),
      );
      return;
    }

    if (!correo.contains('@')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El correo ingresado no es válido.')));
      return;
    }

    if (contrasena.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 4 caracteres.')),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/registrar/usuario'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': correo,
          'contrasena': contrasena,
          'rol': 'usuario',
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registro exitoso')));
        widget.onCambiarVista?.call(); // Volver al login
      } else {
        final body = jsonDecode(response.body);
        final mensaje = body['mensaje'] ?? 'Error al registrar usuario.';
        print(body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión con el servidor: $e')));
    }
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Logo(),
              const SizedBox(height: 8),
              const Text(
                'Crea una cuenta',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _correoCtrl,
                decoration: InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _contrasenaCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cargando ? null : _registrarse,
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
                  'Ya tengo una cuenta',
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
        if (cargando)
          Container(
            color: Colors.black.withAlpha(50),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
