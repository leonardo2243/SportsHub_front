import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../clases.dart';
import '../../providers/sesion_provider.dart';

class CreateLeaguePage extends StatefulWidget {
  const CreateLeaguePage({super.key});

  @override
  State<CreateLeaguePage> createState() => _CreateLeaguePageState();
}

class _CreateLeaguePageState extends State<CreateLeaguePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();

  Reglas? _reglaSeleccionada;
  List<Reglas> _reglasDisponibles = [];
  String _tipoLiga = 'liga';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarReglasDesdeBackend();
  }

  Future<void> _cargarReglasDesdeBackend() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/reglas'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final reglas = data.map((r) => Reglas.fromJson(r)).toList();

        print('Código de estado: ${response.statusCode}');
        print('Respuesta completa: ${response.body}');

        setState(() {
          _reglasDisponibles = reglas;
        });
      } else {
        throw Exception('Error al cargar reglas');
      }
    } catch (e) {
      debugPrint('Error al cargar reglas: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudieron cargar las reglas')));
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime? seleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (seleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = seleccionada;
        } else {
          _fechaFin = seleccionada;
        }
      });
    }
  }

  Future<void> _crearLiga() async {
    if (!_formKey.currentState!.validate() ||
        _reglaSeleccionada == null ||
        _fechaInicio == null ||
        _fechaFin == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Completa todos los campos.')));
      return;
    }

    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final adminId = sesion.id;

    if (adminId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No hay sesión activa')));
      return;
    }

    setState(() => _cargando = true);

    try {
      final ligaBody = {
        "nombre": _nombreCtrl.text.trim(),
        "reglas_id": _reglaSeleccionada!.id,
        "temporada": [
          {
            "hora_inicio": _fechaInicio!.toIso8601String(),
            "hora_fin": _fechaFin!.toIso8601String(),
          },
        ],
        "fase": _tipoLiga,
        "partidos": [],
        "equipos": [],
        "arbitros": [],
        "directores": [],
      };

      final ligaRes = await http.post(
        Uri.parse('http://10.0.2.2:8000/ligas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ligaBody),
      );
      print('Código de estado: ${ligaRes.statusCode}');
      print('Respuesta completa: ${ligaRes.body}');

      if (ligaRes.statusCode != 200) {
        throw Exception('No se pudo crear la liga');
      }

      final ligaId = jsonDecode(ligaRes.body)['id'];

      final asignarRes = await http.post(
        Uri.parse('http://10.0.2.2:8000/admin/agregar_liga'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"id_admin": adminId, "id_liga": ligaId}),
      );

      if (asignarRes.statusCode != 200) {
        throw Exception('No se pudo asignar liga al administrador');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error al crear liga: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al crear liga')));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Liga')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre de la liga'),
                    validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Reglas>(
                    value: _reglaSeleccionada,
                    items:
                        _reglasDisponibles
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r.deporte)),
                            )
                            .toList(),
                    decoration: const InputDecoration(labelText: 'Deporte'),
                    onChanged: (val) => setState(() => _reglaSeleccionada = val),
                    validator: (v) => v == null ? 'Selecciona una regla' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipoLiga,
                    items: const [
                      DropdownMenuItem(value: 'liga', child: Text('Liga')),
                      DropdownMenuItem(value: 'torneo', child: Text('Torneo')),
                    ],
                    decoration: const InputDecoration(labelText: 'Tipo de formato'),
                    onChanged: (val) => setState(() => _tipoLiga = val!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                _fechaInicio != null
                                    ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                                    : '',
                          ),
                          decoration: const InputDecoration(labelText: 'Fecha de inicio'),
                          onTap: () => _seleccionarFecha(context, true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text:
                                _fechaFin != null
                                    ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                                    : '',
                          ),
                          decoration: const InputDecoration(labelText: 'Fecha de fin'),
                          onTap: () => _seleccionarFecha(context, false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _crearLiga,
                      icon: const Icon(Icons.save),
                      label: const Text('Crear liga'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_cargando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
