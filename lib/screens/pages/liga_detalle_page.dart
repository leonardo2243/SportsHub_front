import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../clases.dart';
import 'equipo_detalle_page.dart';
import 'partido_detalle_page.dart';

class LigaDetallePage extends StatefulWidget {
  final String id;
  final String nombre;

  const LigaDetallePage({super.key, required this.id, required this.nombre});

  @override
  State<LigaDetallePage> createState() => _LigaDetallePageState();
}

class _LigaDetallePageState extends State<LigaDetallePage> with TickerProviderStateMixin {
  late final TabController _tabController;

  List<Partido> partidos = [];
  List<Equipo> equipos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    cargarLiga();
  }

  Future<void> cargarLiga() async {
    try {
      final ligaResp = await http.get(
        Uri.parse('http://10.0.2.2:8000/ligas/${widget.id}'),
      );

      if (ligaResp.statusCode == 200) {
        final ligaData = jsonDecode(ligaResp.body);
        final List<String> equipoIds = List<String>.from(ligaData['equipos'] ?? []);
        final List<String> partidoIds = List<String>.from(ligaData['partidos'] ?? []);

        // Cargar equipos
        final List<Equipo> cargadosEquipos = [];
        for (final id in equipoIds) {
          final res = await http.get(Uri.parse('http://10.0.2.2:8000/equipos/$id'));
          if (res.statusCode == 200) {
            cargadosEquipos.add(Equipo.fromJson(jsonDecode(res.body)));
          }
        }

        // Cargar partidos
        final List<Partido> cargadosPartidos = [];
        for (final id in partidoIds) {
          final res = await http.get(Uri.parse('http://10.0.2.2:8000/partidos/$id'));
          if (res.statusCode == 200) {
            cargadosPartidos.add(Partido.fromJson(jsonDecode(res.body)));
          }
        }

        setState(() {
          equipos = cargadosEquipos;
          partidos = cargadosPartidos;
          cargando = false;
        });
      } else {
        throw Exception('No se pudo cargar la liga');
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al cargar liga')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombre),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Partidos'), Tab(text: 'Posiciones')],
          unselectedLabelColor: Colors.white,
          labelColor: const Color.fromARGB(255, 151, 181, 233),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPartidos(), _buildPosiciones()],
      ),
    );
  }

  Widget _buildPartidos() {
    final futuros =
        partidos.where((p) => p.resultado == null || p.resultado!.isEmpty).toList();
    final jugados =
        partidos.where((p) => p.resultado != null && p.resultado!.isNotEmpty).toList();
    final mapaNombres = {for (var e in equipos) e.id: e.nombre};

    String formatoFechaHora(DateTime fecha) => DateFormat('dd/MM - HH:mm').format(fecha);
    String getNombre(String id) => mapaNombres[id] ?? 'Desconocido';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Próximos partidos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...futuros.map(
          (p) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${getNombre(p.localId)} VS ${getNombre(p.visitanteId)}'),
              subtitle: Text(formatoFechaHora(p.horario.horaInicio)),
              trailing: const Text('-'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PartidoDetallePage(partidoId: p.id)),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Resultados anteriores',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...jugados.map(
          (p) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${getNombre(p.localId)} VS ${getNombre(p.visitanteId)}'),
              subtitle: Text(formatoFechaHora(p.horario.horaInicio)),
              trailing: Text(
                '${p.resultado?[p.localId] ?? 0} - ${p.resultado?[p.visitanteId] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PartidoDetallePage(partidoId: p.id)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosiciones() {
    equipos.sort((a, b) => b.puntosLiga.compareTo(a.puntosLiga));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: equipos.length,
      itemBuilder: (context, index) {
        final equipo = equipos[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EquipoDetallePage(equipoId: equipo.id)),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(equipo.nombre, style: const TextStyle(fontSize: 16)),
                ),
                Text(
                  '${equipo.puntosLiga} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
