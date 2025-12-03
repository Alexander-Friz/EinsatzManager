import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/einsatz_neu.dart';

class DatenTab extends StatelessWidget {
  final Einsatz einsatz;

  const DatenTab({super.key, required this.einsatz});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    einsatz.einsatzart,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          einsatz.adresse,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Informationen
            const Text(
              'Einsatz-Informationen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.calendar_today,
              label: 'Datum',
              value: DateFormat('dd.MM.yyyy').format(einsatz.datum),
            ),
            _buildInfoCard(
              icon: Icons.access_time,
              label: 'Uhrzeit',
              value: einsatz.uhrzeit.toFormattedString(),
            ),
            _buildInfoCard(
              icon: Icons.assignment,
              label: 'Einsatzart',
              value: einsatz.einsatzart,
            ),
            _buildInfoCard(
              icon: Icons.fire_truck,
              label: 'Fahrzeuge',
              value: '${einsatz.fahrzeuge.length}',
            ),

            // Gesamtpersonal
            const SizedBox(height: 20),
            const Text(
              'Personal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (einsatz.fahrzeuge.isNotEmpty)
              ...einsatz.fahrzeuge.expand((fahrzeug) {
                return [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fahrzeug: ${fahrzeug.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...fahrzeug.besatzung.map((besatzung) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.person,
                                      size: 18, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(besatzung.personName),
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
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ];
              }).toList()
            else
              Text(
                'Kein Personal eingeplant',
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.red[900]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
