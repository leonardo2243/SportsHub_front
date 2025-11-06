import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateAccountPage extends StatefulWidget {
  final String ligaId;
  const CreateAccountPage({super.key, required this.ligaId});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();

  String? tipoCuenta;
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _certificacionesCtrl = TextEditingController();

  Future<void> _registrarCuenta() async {
    if (!_formKey.currentState!.validate()) return;

    final url =
        tipoCuenta == 'arbitro'
            ? 'http://10.0.2.2:8000/ligas/registrar_arbitro_en_liga'
            : 'http://10.0.2.2:8000/ligas/registrar_director_en_liga';

    final data = {
      'id_liga': widget.ligaId,
      if (tipoCuenta == 'director')
        'director': {
          'nombre': _nombreCtrl.text,
          'correo': _correoCtrl.text,
          'telefono': _telefonoCtrl.text,
          'contrasena': _contrasenaCtrl.text,
          'rol': 'director',
        },
      if (tipoCuenta == 'arbitro')
        'arbitro': {
          'nombre': _nombreCtrl.text,
          'correo': _correoCtrl.text,
          'telefono': _telefonoCtrl.text,
          'contrasena': _contrasenaCtrl.text,
          'certificacion': _certificacionesCtrl.text,
          'rol': 'arbitro',
        },
    };

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    print('Código de estado: ${res.statusCode}');
    print('Respuesta completa: ${res.body}');

    if (res.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al registrar la cuenta')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar nueva cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: tipoCuenta,
                decoration: const InputDecoration(labelText: 'Tipo de cuenta'),
                items: const [
                  DropdownMenuItem(value: 'director', child: Text('Director')),
                  DropdownMenuItem(value: 'arbitro', child: Text('Árbitro')),
                ],
                onChanged: (val) => setState(() => tipoCuenta = val),
                validator: (v) => v == null ? 'Selecciona un tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator:
                    (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contrasenaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator:
                    (v) => v != null && v.length < 4 ? 'Mínimo 4 caracteres' : null,
              ),
              if (tipoCuenta == 'arbitro') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _certificacionesCtrl,
                  decoration: const InputDecoration(labelText: 'Certificaciones'),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _registrarCuenta,
                  child: const Text('Crear'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
