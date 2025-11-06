import 'package:flutter/material.dart';
import 'liga_detalle_page.dart';
import '../../clases.dart';
import 'package:provider/provider.dart';
import '../../providers/sesion_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => InicioPageState();
}

class InicioPageState extends State<InicioPage> {
  List<Liga> ligas = [];
  List<Liga> ligasFiltradas = [];
  final TextEditingController _searchController = TextEditingController();
  Reglas? reglaSeleccionada;
  List<Reglas> reglasDisponibles = [];

  @override
  void initState() {
    super.initState();
    recargar(); // Carga inicial
  }

  Future<void> recargar() async {
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final bool autenticado = sesion.estaAutenticado;
    final String? rol = sesion.rol;
    final String? id = sesion.id;

    try {
      final ligasResp = await http.get(Uri.parse('http://10.0.2.2:8000/ligas'));

      if (ligasResp.statusCode == 200) {
        final data = jsonDecode(ligasResp.body) as List;

        // IDs favoritos si hay sesión
        Set<String> favoritos = {};

        if (autenticado && rol != null && id != null) {
          final userResp = await http.get(Uri.parse('http://10.0.2.2:8000/$rol/$id'));

          if (userResp.statusCode == 200) {
            final userData = jsonDecode(userResp.body);
            favoritos = Set<String>.from(userData['ligasFav'] ?? []);
          }
        }

        final nuevasLigas =
            data.map((json) {
              return Liga(
                id: json['_id'] ?? '',
                nombre: json['nombre'],
                reglasId: json['reglas_id'],
                temporada:
                    (json['temporada'] as List).map((e) => Horario.fromJson(e)).toList(),
                arbitros: List<String>.from(json['arbitros'] ?? []),
                directores: List<String>.from(json['directores'] ?? []),
                equipos: List<String>.from(json['equipos'] ?? []),
                partidos: List<String>.from(json['partidos'] ?? []),
                fase: json['fase'],
                esFavorita: favoritos.contains(json['_id']),
              );
            }).toList();

        setState(() {
          ligas = nuevasLigas;
          ligasFiltradas = nuevasLigas;
        });
      } else {
        throw Exception('Error al cargar ligas');
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudieron cargar las ligas')));
    }
  }

  Future<void> toggleFavorito(String id, bool esFavorita) async {
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    if (!sesion.estaAutenticado || sesion.id == null) return;

    final uri = Uri.parse(
      'http://10.0.2.2:8000/favorito/usuario/${esFavorita ? "eliminar" : "agregar"}',
    );
    final payload = {"id_usuario": sesion.id, "tipo": "liga", "id_fav": id};

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      setState(() {
        final liga = ligas.firstWhere((l) => l.id == id);
        liga.esFavorita = !liga.esFavorita;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar favorito: ${response.body}')),
      );
    }
  }

  void _mostrarFiltroPopup() async {
    List<Reglas> reglas = [];

    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8000/reglas'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        reglas = data.map((e) => Reglas.fromJson(e)).toList();
      } else {
        throw Exception('Error al obtener reglas');
      }
    } catch (e) {
      debugPrint('Error al cargar reglas: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudieron cargar las reglas')));
      return;
    }

    String? idSeleccionado;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar por deporte'),
          content: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Selecciona un deporte'),
            value: idSeleccionado,
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos los deportes')),
              ...reglas.map((r) => DropdownMenuItem(value: r.id, child: Text(r.deporte))),
            ],
            onChanged: (id) {
              idSeleccionado = id;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  if (idSeleccionado == null) {
                    ligasFiltradas = List.from(ligas); // sin filtro
                  } else {
                    ligasFiltradas =
                        ligas.where((l) => l.reglasId == idSeleccionado).toList();
                  }
                });
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  void _filtrarLigas(String texto) {
    setState(() {
      ligasFiltradas =
          ligas.where((l) {
            final nombreCoincide = l.nombre.toLowerCase().contains(texto.toLowerCase());
            final reglaCoincide =
                reglaSeleccionada == null || l.reglasId == reglaSeleccionada!.id;
            return nombreCoincide && reglaCoincide;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: recargar,
      child: Scaffold(
        appBar: AppBar(title: const Text('Ligas disponibles')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Búsqueda
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filtrarLigas,
                      decoration: InputDecoration(
                        hintText: 'Buscar liga...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  if (reglasDisponibles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<Reglas>(
                        value: reglaSeleccionada,
                        hint: const Text('Filtrar por deporte'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.filter_alt),
                        ),
                        items: [
                          const DropdownMenuItem<Reglas>(
                            value: null,
                            child: Text('Todos los deportes'),
                          ),
                          ...reglasDisponibles.map(
                            (r) => DropdownMenuItem(value: r, child: Text(r.deporte)),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() => reglaSeleccionada = val);
                          _filtrarLigas(_searchController.text);
                        },
                      ),
                    ),

                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _mostrarFiltroPopup,
                    icon: const Icon(Icons.filter_alt),
                    tooltip: 'Filtrar por deporte',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de ligas
              Expanded(
                child: ListView.builder(
                  itemCount: ligasFiltradas.length,
                  itemBuilder: (context, index) {
                    final liga = ligasFiltradas[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => LigaDetallePage(id: liga.id, nombre: liga.nombre),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.blue[100 * ((index % 5) + 1)],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .1),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              liga.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                liga.esFavorita ? Icons.favorite : Icons.favorite_border,
                                color: liga.esFavorita ? Colors.red : Colors.black,
                              ),
                              onPressed: () {
                                final sesion = Provider.of<SesionProvider>(
                                  context,
                                  listen: false,
                                );
                                if (!sesion.estaAutenticado) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Debes iniciar sesión para agregar a favoritos.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                toggleFavorito(liga.id, liga.esFavorita);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
