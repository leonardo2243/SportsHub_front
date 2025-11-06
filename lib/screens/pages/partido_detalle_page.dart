import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import '../../clases.dart';

class PartidoDetallePage extends StatefulWidget {
  final String partidoId;

  const PartidoDetallePage({super.key, required this.partidoId});

  @override
  State<PartidoDetallePage> createState() => _PartidoDetallePageState();
}

class _PartidoDetallePageState extends State<PartidoDetallePage> {
  Partido? partido;
  String nombreLocal = '';
  String nombreVisitante = '';
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPartido();
  }

  Future<void> cargarPartido() async {
    if (!mounted) return;
    try {
      final resPartido = await http.get(
        Uri.parse('http://10.0.2.2:8000/partidos/${widget.partidoId}'),
      );

      if (resPartido.statusCode != 200) throw Exception('Error al obtener partido');

      final data = jsonDecode(resPartido.body);
      final p = Partido.fromJson(data);

      final [resLocal, resVisitante] = await Future.wait([
        http.get(Uri.parse('http://10.0.2.2:8000/equipos/${p.localId}')),
        http.get(Uri.parse('http://10.0.2.2:8000/equipos/${p.visitanteId}')),
      ]);

      if (resLocal.statusCode != 200 || resVisitante.statusCode != 200) {
        throw Exception('Error al obtener nombres de equipos');
      }

      final nombreL = jsonDecode(resLocal.body)['nombre'] ?? 'Local';
      final nombreV = jsonDecode(resVisitante.body)['nombre'] ?? 'Visitante';

      if (mounted) {
        setState(() {
          partido = p;
          nombreLocal = nombreL;
          nombreVisitante = nombreV;
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar partido: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No se pudo cargar el partido')));
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando || partido == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del Partido')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('$nombreLocal vs $nombreVisitante')),
      body: RefreshIndicator(
        onRefresh: cargarPartido,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- NUEVO WIDGET DE ENCABEZADO ---
            _buildHeaderCard(),
            const SizedBox(height: 24),

            // --- CRONOLOGÍA DE EVENTOS ---
            const Text(
              'Cronología del Partido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (partido!.eventos != null && partido!.eventos!.isNotEmpty)
              _buildListaEventos(partido!.eventos!)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No hay eventos registrados.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET MEJORADO PARA EL ENCABEZADO ---
  Widget _buildHeaderCard() {
    final p = partido!;
    final tieneResultado = p.resultado != null && p.resultado!.isNotEmpty;
    final resultadoStr =
        tieneResultado
            ? '${p.resultado![p.localId] ?? 0} - ${p.resultado![p.visitanteId] ?? 0}'
            : 'VS';
    final fecha = DateFormat(
      'EEE, dd/MM/yyyy - HH:mm',
      'es_ES',
    ).format(p.horario.horaInicio);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(fecha, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamInfo(nombreLocal),
                Text(
                  resultadoStr,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                _buildTeamInfo(nombreVisitante),
              ],
            ),
            if (!tieneResultado)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Próximamente',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                const SizedBox(width: 4),
                Text(p.lugar, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(String nombre) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            child: const Icon(Icons.shield, size: 30, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildListaEventos(Map<String, List<dynamic>> eventos) {
    final eventosOrdenados =
        eventos.entries.toList()
          ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    return Column(
      children:
          eventosOrdenados.map((entry) {
            final details = List<String>.from(entry.value);
            if (details.length < 4) return const SizedBox.shrink();

            final tipo = details[0];
            final equipoId = details[1];
            final jugador = details[2];
            final detalle = details[3];

            final esLocal = equipoId == partido!.localId;
            final nombreEquipo = esLocal ? nombreLocal : nombreVisitante;
            final color = esLocal ? Colors.blue.shade700 : Colors.red.shade700;
            final icon = tipo == 'punto' ? Icons.sports_basketball : Icons.warning_amber;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text('$detalle (${tipo.capitalize()})'),
                subtitle: Text('$jugador - $nombreEquipo'),
              ),
            );
          }).toList(),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
