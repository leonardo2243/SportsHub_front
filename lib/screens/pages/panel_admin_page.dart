import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../clases.dart';
import '../../providers/sesion_provider.dart';
import 'create_league_page.dart';
import 'liga_detalle_admin_page.dart';

class PanelAdminPage extends StatefulWidget {
  const PanelAdminPage({super.key});

  @override
  State<PanelAdminPage> createState() => _PanelAdminPageState();
}

class _PanelAdminPageState extends State<PanelAdminPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Liga> ligas = [];
  List<Liga> ligasFiltradas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filtrarLigas(_searchController.text);
    });
    _fetchLigas();
  }

  Future<void> _fetchLigas() async {
    setState(() => _cargando = true);

    final sesion = Provider.of<SesionProvider>(context, listen: false);
    final adminId = sesion.id;

    if (adminId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No hay sesión activa')));
      return;
    }

    try {
      final adminRes = await http.get(Uri.parse('http://10.0.2.2:8000/admin/$adminId'));

      if (adminRes.statusCode != 200) {
        throw Exception('Error al obtener datos del administrador');
      }

      final adminData = jsonDecode(adminRes.body);
      final List<String> ligasIds = List<String>.from(adminData['ligas'] ?? []);

      final List<Liga> nuevasLigas = [];

      for (final id in ligasIds) {
        final ligaRes = await http.get(Uri.parse('http://10.0.2.2:8000/ligas/$id'));

        if (ligaRes.statusCode == 200) {
          final json = jsonDecode(ligaRes.body);
          nuevasLigas.add(Liga.fromJson(json));
        }
      }

      setState(() {
        ligas = nuevasLigas;
        ligasFiltradas = List.from(nuevasLigas);
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al obtener ligas')));
      setState(() => _cargando = false);
    }
  }

  void _filtrarLigas(String texto) {
    setState(() {
      ligasFiltradas =
          ligas
              .where((l) => l.nombre.toLowerCase().contains(texto.toLowerCase()))
              .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Ligas')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar liga...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: ligasFiltradas.length,
                    itemBuilder: (context, index) {
                      final liga = ligasFiltradas[index];
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.blue[100 * ((index % 5) + 1)],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LigaDetalleAdminPage(liga: liga),
                                    ),
                                  );
                                },
                                child: Text(
                                  liga.nombre,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text('¿Eliminar liga?'),
                                        content: const Text(
                                          '¿Deseas eliminar esta liga permanentemente?',
                                        ),
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

                                if (confirm == true) {
                                  try {
                                    final res = await http.delete(
                                      Uri.parse(
                                        'http://10.0.2.2:8000/ligas/${liga.id}/completa',
                                      ),
                                    );
                                    if (res.statusCode == 200) {
                                      setState(() {
                                        ligas.removeWhere((l) => l.id == liga.id);
                                        ligasFiltradas.removeWhere(
                                          (l) => l.id == liga.id,
                                        );
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Liga eliminada')),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Error al eliminar liga'),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Error eliminando liga: $e');
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_cargando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final creado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateLeaguePage()),
          );
          if (creado == true) {
            _fetchLigas();
          }
        },
      ),
    );
  }
}
