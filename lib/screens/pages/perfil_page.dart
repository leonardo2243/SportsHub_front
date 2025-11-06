import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sesion_provider.dart';
import '../login_page.dart';
import '../signup_page.dart';
import '../../widgets/logo.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PerfilPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const PerfilPage({super.key, this.onLoginSuccess});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _mostrarLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool cargando = true;

  Future<void> cargarDatosDesdeBackend(String rol, String id) async {
    try {
      print("rol $rol, id $id");
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/$rol/$id'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nombreCtrl.text = data['nombre'] ?? '';
          _correoCtrl.text = data['correo'] ?? '';
          _telefonoCtrl.text = data['telefono'] ?? '';
          cargando = false;
        });
      } else {
        throw Exception('No se pudo cargar la información del usuario');
      }
    } catch (e) {
      debugPrint('Error al obtener datos: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener datos del servidor')));
      setState(() => cargando = false);
    }
  }

  void _toggleVistaAuth() {
    setState(() => _mostrarLogin = !_mostrarLogin);
  }

  void _mostrarPopupCambioContrasena() {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final confirmarCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Cambiar contraseña'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: actualCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña actual'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nuevaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmarCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nueva = nuevaCtrl.text.trim();
                  final confirmacion = confirmarCtrl.text.trim();
                  final actual = actualCtrl.text.trim();

                  if (nueva.isEmpty || confirmacion.isEmpty || actual.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Completa todos los campos.')),
                    );
                    return;
                  }

                  if (nueva != confirmacion) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Las contraseñas no coinciden.')),
                    );
                    return;
                  }

                  final sesion = Provider.of<SesionProvider>(context, listen: false);
                  final id = sesion.id;
                  final rol = sesion.rol;

                  if (id == null || rol == null) return;

                  final url = 'http://10.0.2.2:8000/cambiar_contrasena/$rol';

                  try {
                    final response = await http.post(
                      Uri.parse(url),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'id': id,
                        'actual': actual,
                        'nueva1': nueva,
                        'nueva2': confirmacion,
                      }),
                    );

                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña actualizada correctamente.'),
                        ),
                      );
                    } else {
                      final body = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(body['detail'] ?? 'Error al cambiar contraseña'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al conectar con el servidor: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Provider.of<SesionProvider>(context);
    final rol = sesion.rol;
    final id = sesion.id;

    if (id == null || rol == null) {
      return Scaffold(
        body: Center(
          child:
              _mostrarLogin
                  ? LoginPage(
                    onLoginSuccess: () {
                      widget.onLoginSuccess?.call();
                      setState(() {});
                    },
                    onCambiarVista: _toggleVistaAuth,
                  )
                  : SignupPage(
                    onRegistroSuccess: () {
                      widget.onLoginSuccess?.call();
                      setState(() {});
                    },
                    onCambiarVista: _toggleVistaAuth,
                  ),
        ),
      );
    }

    // solo se ejecuta una vez al cargar
    if (cargando) {
      cargarDatosDesdeBackend(rol, id);
    }

    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Logo(),
              const Icon(Icons.account_circle, size: 100),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correoCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              if (rol != 'usuario') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Información actualizada.')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar cambios'),
                ),
              ),
              //
              TextButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text('Cambiar contraseña'),
                onPressed: _mostrarPopupCambioContrasena,
              ),

              //
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Provider.of<SesionProvider>(context, listen: false).cerrarSesion();
          setState(() {});
        },
        child: const Icon(Icons.logout),
      ),
    );
  }
}
