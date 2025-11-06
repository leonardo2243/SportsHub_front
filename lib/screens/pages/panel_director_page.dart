// panel_director_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../clases.dart';
import '../../providers/sesion_provider.dart';

class PanelDirectorPage extends StatefulWidget {
  const PanelDirectorPage({Key? key}) : super(key: key);

  @override
  State<PanelDirectorPage> createState() => _PanelDirectorPageState();
}

class _PanelDirectorPageState extends State<PanelDirectorPage> {
  bool _cargando = true;
  Equipo? _equipo; // Puede ser nulo si el director no tiene equipo

  @override
  void initState() {
    super.initState();
    _cargarEquipoDelDirector();
  }

  Future<void> _cargarEquipoDelDirector() async {
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final directorId = sesion.id;
    if (directorId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No hay sesión activa')));
      }
      return;
    }

    if (mounted) setState(() => _cargando = true);
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:8000/equipos/por_director/$directorId'),
      );

      if (res.statusCode == 200) {
        final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _equipo = Equipo.fromJson(jsonMap);
          });
        }
      } else if (res.statusCode != 404) {
        // Ignoramos el 404 (director sin equipo), pero mostramos otros errores
        throw Exception('Error al cargar el equipo: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error al cargar equipo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarPopupAgregarJugador() {
    final nombreCtrl = TextEditingController();
    final numeroCtrl = TextEditingController();
    final posicionCtrl = TextEditingController();
    final edadCtrl = TextEditingController(); // Añadido campo de edad

    showDialog<Jugador?>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Agregar jugador'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: numeroCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Número'),
                  ),
                  TextField(
                    controller: posicionCtrl,
                    decoration: const InputDecoration(labelText: 'Posición'),
                  ),
                  TextField(
                    controller: edadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edad'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nuevo = Jugador(
                    nombre: nombreCtrl.text.trim(),
                    numero: int.tryParse(numeroCtrl.text.trim()) ?? 0,
                    posicion: posicionCtrl.text.trim(),
                    edad: int.tryParse(edadCtrl.text.trim()) ?? 0,
                  );
                  Navigator.pop(ctx, nuevo);
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
    ).then((nuevoJugador) async {
      if (nuevoJugador == null || _equipo == null) return;

      final payload = {
        'id_equipo': _equipo!.id,
        'jugador': {
          'nombre': nuevoJugador.nombre,
          'numero': nuevoJugador.numero,
          'posicion': nuevoJugador.posicion,
          'edad': nuevoJugador.edad,
        },
      };

      try {
        final resp = await http.post(
          Uri.parse('http://10.0.2.2:8000/equipos/agregar_jugador'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (resp.statusCode == 200 && mounted) {
          setState(() {
            _equipo!.jugadores ??= <Jugador>[];
            _equipo!.jugadores!.add(nuevoJugador);
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Jugador agregado')));
        } else {
          final body = jsonDecode(resp.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${body['detail'] ?? resp.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error de conexión')));
      }
    });
  }

  // --- NUEVA FUNCIÓN PARA ELIMINAR JUGADOR ---
  Future<void> _eliminarJugador(Jugador jugador) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Estás seguro de que quieres eliminar a ${jugador.nombre}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmado != true || _equipo == null) return;

    final payload = {'id_equipo': _equipo!.id, 'numero': jugador.numero};

    try {
      final resp = await http.post(
        Uri.parse('http://10.0.2.2:8000/equipos/eliminar_jugador'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _equipo!.jugadores?.removeWhere((j) => j.numero == jugador.numero);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Jugador eliminado')));
      } else {
        final body = jsonDecode(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${body['detail'] ?? resp.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error de conexión')));
    }
  }

  Widget _buildEstadistica(String label, int valor, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withAlpha(50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$valor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_equipo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Panel de Director')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Aún no tienes un equipo asignado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_equipo!.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEstadistica('Puntos', _equipo!.puntosLiga, Colors.blue),
              _buildEstadistica('Ganados', _equipo!.partidosGanados, Colors.green),
              _buildEstadistica('Empatados', _equipo!.partidosEmpatados, Colors.orange),
              _buildEstadistica('Perdidos', _equipo!.partidosPerdidos, Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jugadores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _mostrarPopupAgregarJugador,
                icon: const Icon(Icons.person_add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_equipo!.jugadores == null || _equipo!.jugadores!.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay jugadores registrados.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _equipo!.jugadores!.length,
              itemBuilder: (context, index) {
                final jugador = _equipo!.jugadores![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('#${jugador.numero}')),
                    title: Text(jugador.nombre),
                    subtitle: Text('Posición: ${jugador.posicion}'),
                    // --- WIDGET MODIFICADO CON BOTÓN DE ELIMINAR ---
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Eliminar jugador',
                      onPressed: () => _eliminarJugador(jugador),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
