import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../clases.dart';
import '../../providers/sesion_provider.dart';
import 'liga_detalle_page.dart';
import 'equipo_detalle_page.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<Liga> ligasFav = [];
  List<Equipo> equiposFav = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarFavoritos();
  }

  Future<void> cargarFavoritos() async {
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final String? id = sesion.id;
    final String? rol = sesion.rol;

    if (id == null || rol == null) return;

    try {
      final userResp = await http.get(Uri.parse('http://10.0.2.2:8000/$rol/$id'));

      if (userResp.statusCode == 200) {
        final userData = jsonDecode(userResp.body);
        final List<String> ligasFavIds = List<String>.from(userData['ligasFav'] ?? []);
        final List<String> equiposFavIds = List<String>.from(userData['equipoFav'] ?? []);

        final List<Liga> ligasCargadas = [];
        final List<Equipo> equiposCargados = [];

        for (final id in ligasFavIds) {
          final ligaResp = await http.get(Uri.parse('http://10.0.2.2:8000/ligas/$id'));
          if (ligaResp.statusCode == 200) {
            final json = jsonDecode(ligaResp.body);
            ligasCargadas.add(Liga.fromJson(json)..esFavorita = true);
          }
        }

        for (final id in equiposFavIds) {
          final equipoResp = await http.get(
            Uri.parse('http://10.0.2.2:8000/equipos/$id'),
          );
          if (equipoResp.statusCode == 200) {
            final json = jsonDecode(equipoResp.body);
            equiposCargados.add(Equipo.fromJson(json));
          }
        }

        setState(() {
          ligasFav = ligasCargadas;
          equiposFav = equiposCargados;
          cargando = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar favoritos: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al cargar favoritos')));
      setState(() => cargando = false);
    }
  }

  Future<void> eliminarFavorito(String id, String tipo) async {
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final userId = sesion.id;

    if (userId == null) return;

    final payload = {"id_usuario": userId, "tipo": tipo, "id_fav": id};

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/favorito/usuario/eliminar"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      setState(() {
        if (tipo == 'liga') {
          ligasFav.removeWhere((l) => l.id == id);
        } else {
          equiposFav.removeWhere((e) => e.id == id);
        }
      });
    } else {
      debugPrint("Error al eliminar favorito: ${response.body}");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo eliminar el favorito.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = Provider.of<SesionProvider>(context);
    final usuario = sesion.id;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favoritos')),
        body: const Center(child: Text('Inicia sesión para ver tus favoritos.')),
      );
    }

    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final elementos = [
      {'tipo': 'separador', 'titulo': 'Ligas favoritas'},
      ...ligasFav.map((liga) => {'tipo': 'liga', 'liga': liga}),
      {'tipo': 'separador', 'titulo': 'Equipos favoritos'},
      ...equiposFav.map((equipo) => {'tipo': 'equipo', 'equipo': equipo}),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: elementos.length,
        itemBuilder: (context, index) {
          final item = elementos[index];

          if (item['tipo'] == 'separador') {
            final String titulo = item['titulo'] as String;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                titulo,
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
            );
          }

          final String tipo = item['tipo'] as String;
          final String nombre;
          final Color color;
          String id = '';

          if (tipo == 'liga') {
            final liga = item['liga'] as Liga;
            nombre = liga.nombre;
            color = Colors.blue[100 * ((index % 5) + 1)]!;
            id = liga.id;
          } else {
            final equipo = item['equipo'] as Equipo;
            nombre = equipo.nombre;
            color = Colors.green[100 * ((index % 5) + 1)]!;
            id = equipo.id;
          }

          return InkWell(
            onTap: () {
              if (tipo == 'liga') {
                final liga = item['liga'] as Liga;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LigaDetallePage(id: liga.id, nombre: liga.nombre),
                  ),
                );
              } else {
                final equipo = item['equipo'] as Equipo;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipoDetallePage(equipoId: equipo.id),
                  ),
                );
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => eliminarFavorito(id, tipo),
                    tooltip: 'Eliminar de favoritos',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
