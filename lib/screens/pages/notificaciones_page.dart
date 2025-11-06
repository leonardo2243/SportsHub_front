import 'package:flutter/material.dart';

class NotificacionesPage extends StatelessWidget {
  const NotificacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificaciones = [
      'Liga 1 tiene un partido próximo en 15 min: Equipo 2 vs Equipo 3',
      'Se canceló un partido de la Liga 4: Equipo 3 vs Equipo 1',
      'Liga 2 tiene un partido mañana: Equipo 7 vs Equipo 8',
      'Resultados del Equipo 8: 2 - 1 contra Equipo 3',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notificaciones.length,
        itemBuilder:
            (context, index) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(notificaciones[index]),
              ),
            ),
      ),
    );
  }
}
