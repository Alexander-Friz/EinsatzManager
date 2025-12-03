import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/einsatz_neu.dart';
import '../services/einsatz_service_neu.dart';
import 'einsatz_erstellen_screen.dart';

class HomeScreenNeu extends StatelessWidget {
  const HomeScreenNeu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EinsatzManager'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<EinsatzService>(
        builder: (context, service, _) {
          return Column(
            children: [
              // Großer Einsatz Button
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EinsatzErstellenScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red[900],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'EINSATZ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Einsätze Liste
              if (service.einsaetze.isNotEmpty)
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: ListView.builder(
                      itemCount: service.einsaetze.length,
                      itemBuilder: (context, index) {
                        final einsatz = service.einsaetze[index];
                        return _buildEinsatzCard(context, einsatz);
                      },
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Keine Einsätze',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Drücke den Button oben um einen\nneuen Einsatz zu erstellen',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEinsatzCard(BuildContext context, Einsatz einsatz) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: Icon(Icons.fire_truck, color: Colors.red[900]),
        title: Text(
          einsatz.einsatzart,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(einsatz.adresse),
            const SizedBox(height: 4),
            Text(
              '${einsatz.datum.day.toString().padLeft(2, '0')}.${einsatz.datum.month.toString().padLeft(2, '0')}.${einsatz.datum.year} - ${einsatz.uhrzeit.toFormattedString()}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () {
          // Optional: Detail-View öffnen
        },
      ),
    );
  }
}
