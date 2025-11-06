import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../clases.dart';

class CreateMatchPage extends StatefulWidget {
  final String ligaId;
  final String ligaReglasId;

  const CreateMatchPage({super.key, required this.ligaId, required this.ligaReglasId});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final _formKey = GlobalKey<FormState>();
  final _lugarCtrl = TextEditingController();

  String? equipoLocal;
  String? equipoVisitante;
  String? arbitroId;
  DateTime? fechaHora;

  List<Equipo> equiposDisponibles = [];
  List<Arbitro> arbitrosDisponibles = [];

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarDatosLiga();
  }

  Future<void> cargarDatosLiga() async {
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:8000/ligas/${widget.ligaId}'),
      );
      if (res.statusCode != 200) throw Exception('Error al cargar liga');

      final data = jsonDecode(res.body);
      final equipoIds = List<String>.from(data['equipos'] ?? []);
      final arbitroIds = List<String>.from(data['arbitros'] ?? []);

      final List<Equipo> eqs = [];
      for (final id in equipoIds) {
        final r = await http.get(Uri.parse('http://10.0.2.2:8000/equipos/$id'));
        if (r.statusCode == 200) eqs.add(Equipo.fromJson(jsonDecode(r.body)));
      }

      final List<Arbitro> arbs = [];
      for (final id in arbitroIds) {
        final r = await http.get(Uri.parse('http://10.0.2.2:8000/arbitro/$id'));
        if (r.statusCode == 200) arbs.add(Arbitro.fromJson(jsonDecode(r.body)));
      }

      setState(() {
        equiposDisponibles = eqs;
        arbitrosDisponibles = arbs;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al cargar equipos o árbitros')));
      setState(() => cargando = false);
    }
  }

  Future<void> _seleccionarFechaHora() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (fecha == null) return;

    final TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (hora == null) return;

    setState(() {
      fechaHora = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
  }

  Future<void> _registrarPartido() async {
    if (!_formKey.currentState!.validate() ||
        equipoLocal == null ||
        equipoVisitante == null ||
        arbitroId == null ||
        fechaHora == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
      return;
    }

    // Obtener duración desde el backend
    final reglasRes = await http.get(
      Uri.parse('http://10.0.2.2:8000/reglas/${widget.ligaReglasId}'),
    );
    if (reglasRes.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener duración de la liga')),
      );
      return;
    }
    final reglas = jsonDecode(reglasRes.body);
    final duracionMin = reglas['duracion_total'] ?? 60;

    final partidoPayload = {
      'arbitro_id': arbitroId,
      'local_id': equipoLocal,
      'visitante_id': equipoVisitante,
      'lugar': _lugarCtrl.text,
      'horario': {
        'hora_inicio': fechaHora!.toIso8601String(),
        'hora_fin': fechaHora!.add(Duration(minutes: duracionMin)).toIso8601String(),
      },
      'resultado': {},
      'notas': [],
      'eventos': {},
    };

    final res = await http.post(
      Uri.parse('http://10.0.2.2:8000/partidos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(partidoPayload),
    );
    print(res.statusCode);
    print(res.body);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final partidoId = data['id'];

      await http.post(
        Uri.parse('http://10.0.2.2:8000/ligas/agregar_partido'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_liga': widget.ligaId, 'id_item': partidoId}),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al crear partido')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Partido')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: equipoLocal,
                items:
                    equiposDisponibles
                        .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                        .toList(),
                onChanged: (val) {
                  setState(() {
                    equipoLocal = val;
                    if (equipoVisitante == val) equipoVisitante = null;
                  });
                },
                decoration: const InputDecoration(labelText: 'Equipo local'),
                validator: (v) => v == null ? 'Selecciona un equipo' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: equipoVisitante,
                items:
                    equiposDisponibles
                        .where((e) => e.id != equipoLocal)
                        .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                        .toList(),
                onChanged: (val) => setState(() => equipoVisitante = val),
                decoration: const InputDecoration(labelText: 'Equipo visitante'),
                validator: (v) => v == null ? 'Selecciona un equipo' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: arbitroId,
                items:
                    arbitrosDisponibles
                        .map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre)))
                        .toList(),
                onChanged: (val) => setState(() => arbitroId = val),
                decoration: const InputDecoration(labelText: 'Árbitro'),
                validator: (v) => v == null ? 'Selecciona un árbitro' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lugarCtrl,
                decoration: const InputDecoration(labelText: 'Lugar del partido'),
                validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text:
                      fechaHora == null
                          ? ''
                          : '${fechaHora!.day}/${fechaHora!.month}/${fechaHora!.year} ${fechaHora!.hour.toString().padLeft(2, '0')}:${fechaHora!.minute.toString().padLeft(2, '0')}',
                ),
                onTap: _seleccionarFechaHora,
                decoration: const InputDecoration(labelText: 'Fecha y hora de inicio'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _registrarPartido,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar partido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
