import 'package:flutter/material.dart';
import '../../models/einsatz_neu.dart';

class FahrzeugeTab extends StatefulWidget {
  final Einsatz einsatz;
  final Function(Einsatz) onEinsatzChanged;

  const FahrzeugeTab({
    super.key,
    required this.einsatz,
    required this.onEinsatzChanged,
  });

  @override
  State<FahrzeugeTab> createState() => _FahrzeugeTabState();
}

class _FahrzeugeTabState extends State<FahrzeugeTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eingesetzte Fahrzeuge & Besatzung',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (widget.einsatz.fahrzeuge.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.fire_truck, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Fahrzeuge eingeplant',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...widget.einsatz.fahrzeuge.map((fahrzeug) {
                return _buildFahrzeugCard(fahrzeug);
              }).toList(),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addFahrzeug,
              icon: const Icon(Icons.add),
              label: const Text('Fahrzeug hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFahrzeugCard(Fahrzeug fahrzeug) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fahrzeug-Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              fahrzeug.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Besatzung
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Besatzung:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (fahrzeug.besatzung.isEmpty)
                  Text(
                    'Kein Personal zugewiesen',
                    style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  )
                else
                  ...fahrzeug.besatzung.map((besatzung) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red[900],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  besatzung.personName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  besatzung.position.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                const SizedBox(height: 12),
                if (fahrzeug.besatzung.isNotEmpty)
                  Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),

                // Atemschutz Info
                Row(
                  children: [
                    Icon(
                      fahrzeug.atemschutzEinsatz ? Icons.check_circle : Icons.cancel,
                      color: fahrzeug.atemschutzEinsatz ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fahrzeug.atemschutzEinsatz ? 'Atemschutzeinsatz: JA' : 'Atemschutzeinsatz: NEIN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: fahrzeug.atemschutzEinsatz ? Colors.green : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addFahrzeug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weitere Fahrzeuge hinzufügen - Coming Soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
