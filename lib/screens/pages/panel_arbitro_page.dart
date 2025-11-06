import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../clases.dart';
import '../../providers/sesion_provider.dart';
import 'partido_registro_page.dart';

class PanelArbitroPage extends StatefulWidget {
  const PanelArbitroPage({super.key});

  @override
  State<PanelArbitroPage> createState() => _PanelArbitroPageState();
}

class _PanelArbitroPageState extends State<PanelArbitroPage> {
  // Listas separadas para cada estado del partido
  List<Partido> _partidosEnCurso = [];
  List<Partido> _partidosFuturos = [];
  List<Partido> _partidosPasados = [];

  Map<String, String> _nombresEquipos = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _fetchPartidosAsignados();
  }

  Future<void> _fetchPartidosAsignados() async {
    if (!mounted) return;
    setState(() => _cargando = true);

    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final arbitroId = sesion.id;
    if (arbitroId == null) {
      setState(() => _cargando = false);
      return;
    }

    try {
      // 1) Traemos la lista completa de partidos del árbitro
      final res = await http.get(
        Uri.parse('http://10.0.2.2:8000/partidos/por_arbitro/$arbitroId'),
      );
      if (res.statusCode != 200) throw Exception('Error al cargar partidos del servidor');

      final data = jsonDecode(res.body) as List<dynamic>;
      final nombresTemp = Map<String, String>.from(
        _nombresEquipos,
      ); // Conservar nombres ya cargados

      // Listas locales para procesar antes de actualizar el estado
      final List<Partido> todosLosPartidos = [];

      // 2) Obtenemos los nombres de los equipos de forma eficiente
      for (final item in data) {
        final p = Partido.fromJson(item as Map<String, dynamic>);
        todosLosPartidos.add(p);

        for (final id in [p.localId, p.visitanteId]) {
          if (!nombresTemp.containsKey(id)) {
            final r = await http.get(Uri.parse('http://10.0.2.2:8000/equipos/$id'));
            if (r.statusCode == 200) {
              nombresTemp[id] = Equipo.fromJson(jsonDecode(r.body)).nombre;
            }
          }
        }
      }

      // 3) Clasificamos los partidos en las 3 listas
      final ahora = DateTime.now();
      final enCurso = <Partido>[];
      final futuros = <Partido>[];
      final pasados = <Partido>[];

      for (final p in todosLosPartidos) {
        if (p.resultado != null && p.resultado!.isNotEmpty) {
          pasados.add(p);
        } else if (p.horario.horaInicio.isAfter(ahora)) {
          futuros.add(p);
        } else {
          enCurso.add(p);
        }
      }

      // 4) Actualizamos el estado de la UI
      if (mounted) {
        setState(() {
          _partidosEnCurso = enCurso;
          _partidosFuturos = futuros;
          _partidosPasados = pasados;
          _nombresEquipos = nombresTemp;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar partidos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron cargar los partidos')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Partidos')),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchPartidosAsignados,
                child:
                    (_partidosEnCurso.isEmpty &&
                            _partidosFuturos.isEmpty &&
                            _partidosPasados.isEmpty)
                        ? const Center(child: Text('No tienes partidos asignados.'))
                        : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // --- SECCIÓN EN CURSO / RECIENTES ---
                            if (_partidosEnCurso.isNotEmpty)
                              _buildSeccionPartidos(
                                'En Curso o Recientes',
                                _partidosEnCurso,
                                Colors.orange,
                              ),

                            // --- SECCIÓN PRÓXIMOS ---
                            if (_partidosFuturos.isNotEmpty)
                              _buildSeccionPartidos(
                                'Próximos Partidos',
                                _partidosFuturos,
                                Colors.blue,
                              ),

                            // --- SECCIÓN PASADOS ---
                            if (_partidosPasados.isNotEmpty)
                              _buildSeccionPartidos(
                                'Resultados Anteriores',
                                _partidosPasados,
                                Colors.grey,
                              ),
                          ],
                        ),
              ),
    );
  }

  // Widget reutilizable para construir cada sección de la lista
  Widget _buildSeccionPartidos(String titulo, List<Partido> listaPartidos, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
          child: Text(
            titulo.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...listaPartidos.map((p) {
          final local = _nombresEquipos[p.localId] ?? 'Equipo Local';
          final visita = _nombresEquipos[p.visitanteId] ?? 'Equipo Visitante';
          final hora = DateFormat(
            'EEE, dd/MM - HH:mm',
            'es_ES',
          ).format(p.horario.horaInicio);
          final resultado =
              (p.resultado != null && p.resultado!.isNotEmpty)
                  ? '${p.resultado![p.localId] ?? 0} - ${p.resultado![p.visitanteId] ?? 0}'
                  : null;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              title: Text(
                '$local VS $visita',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(hora),
              trailing:
                  resultado != null
                      ? Text(
                        resultado,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PartidoRegistroPage(partidoId: p.id)),
                ).then((_) => _fetchPartidosAsignados()); // Recargar al volver
              },
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
