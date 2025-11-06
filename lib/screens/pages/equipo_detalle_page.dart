import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../clases.dart';
import 'package:provider/provider.dart';
import '../../providers/sesion_provider.dart';

class EquipoDetallePage extends StatefulWidget {
  final String equipoId;

  const EquipoDetallePage({super.key, required this.equipoId});

  @override
  State<EquipoDetallePage> createState() => _EquipoDetallePageState();
}

class _EquipoDetallePageState extends State<EquipoDetallePage> {
  Equipo? equipo;
  String? directorNombre; // Estado para guardar el nombre del director
  bool cargando = true;
  bool esFavorito = false;

  @override
  void initState() {
    super.initState();
    cargarDetalles();
  }

  Future<void> cargarDetalles() async {
    // Para evitar errores si el widget se desmonta
    if (!mounted) return;

    try {
      // 1. Cargar datos del equipo
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/equipos/${widget.equipoId}'),
      );

      if (response.statusCode == 200) {
        final equipoJson = jsonDecode(response.body);
        final equipoData = Equipo.fromJson(equipoJson);

        setState(() {
          equipo = equipoData;
        });

        // 2. Si hay un director, cargar su nombre
        if (equipoData.directorId != null && equipoData.directorId!.isNotEmpty) {
          final directorResponse = await http.get(
            Uri.parse('http://10.0.2.2:8000/director/${equipoData.directorId}'),
          );
          if (directorResponse.statusCode == 200) {
            final directorJson = jsonDecode(directorResponse.body);
            setState(() {
              directorNombre = directorJson['nombre'] ?? 'No encontrado';
            });
          }
        }
      } else {
        throw Exception('Error al cargar equipo');
      }
    } catch (e) {
      debugPrint('Error al cargar detalles: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No se pudo cargar la información')));
      }
    }

    // 3. Cargar estado de favorito (si hay sesión)
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    if (sesion.estaAutenticado && sesion.id != null && sesion.rol != null) {
      try {
        final userResp = await http.get(
          Uri.parse('http://10.0.2.2:8000/${sesion.rol}/${sesion.id}'),
        );
        if (userResp.statusCode == 200) {
          final userData = jsonDecode(userResp.body);
          final favs = List<String>.from(userData['equipoFav'] ?? []);
          if (mounted) {
            setState(() {
              esFavorito = favs.contains(widget.equipoId);
            });
          }
        }
      } catch (e) {
        debugPrint('Error al cargar favoritos: $e');
      }
    }

    if (mounted) {
      setState(() => cargando = false);
    }
  }

  Future<void> toggleFavorito() async {
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final rol = sesion.rol;
    final id = sesion.id;

    if (!sesion.estaAutenticado || rol == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para agregar a favoritos.')),
      );
      return;
    }

    final url =
        'http://10.0.2.2:8000/favorito/usuario/${esFavorito ? "eliminar" : "agregar"}';
    final payload = {"id_usuario": id, "tipo": "equipo", "id_fav": widget.equipoId};

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      setState(() {
        esFavorito = !esFavorito;
      });
    } else {
      debugPrint('Error al actualizar favorito: ${response.body}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al actualizar favorito')));
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
    if (cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (equipo == null) {
      return const Scaffold(body: Center(child: Text('No se pudo cargar el equipo.')));
    }

    final e = equipo!;
    return Scaffold(
      appBar: AppBar(
        title: Text(e.nombre),
        actions: [
          IconButton(
            icon: Icon(
              esFavorito ? Icons.favorite : Icons.favorite_border,
              color: esFavorito ? Colors.red : Colors.white,
            ),
            tooltip: esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
            onPressed: toggleFavorito,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            // CAMBIO AQUÍ: Muestra el nombre del director
            'Director: ${directorNombre ?? 'No asignado'}',
            style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEstadistica('Ganados', e.partidosGanados, Colors.green),
              _buildEstadistica('Empatados', e.partidosEmpatados, Colors.orange),
              _buildEstadistica('Perdidos', e.partidosPerdidos, Colors.red),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Jugadores',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (e.jugadores == null || e.jugadores!.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: Text('No hay jugadores registrados.')),
            )
          else
            ...e.jugadores!.map(
              (j) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('#${j.numero}')),
                  title: Text(
                    j.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('Posición: ${j.posicion}'),
                  trailing: Text('${j.edad} años'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
