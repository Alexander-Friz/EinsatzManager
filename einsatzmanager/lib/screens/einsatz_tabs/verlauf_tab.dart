import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/einsatz_neu.dart';

class VerlaufTab extends StatelessWidget {
  final Einsatz einsatz;

  const VerlaufTab({
    super.key,
    required this.einsatz,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Einsatz Timeline
            _buildEinsatzTimeline(),
            const SizedBox(height: 24),

            // Atemschutz Protokoll
            if (einsatz.atemschutzProtokoll != null &&
                einsatz.atemschutzProtokoll!.isNotEmpty)
              _buildAtemschutzProtokoll()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildEinsatzTimeline() {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm:ss');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Einsatz Zeitstrahl',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Einsatz erstellt
            _buildTimelineEntry(
              icon: Icons.add_circle,
              title: 'Einsatz erstellt',
              time: dateFormat.format(einsatz.erstelltAm),
              color: Colors.blue,
            ),

            // Einsatz beendet
            if (einsatz.beendetAm != null)
              _buildTimelineEntry(
                icon: Icons.check_circle,
                title: 'Einsatz beendet',
                time: dateFormat.format(einsatz.beendetAm!),
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtemschutzProtokoll() {
    final protokoll = einsatz.atemschutzProtokoll ?? [];
    if (protokoll.isEmpty) return const SizedBox.shrink();

    // Gruppiere nach Fahrzeug
    final gruppiertNachFahrzeug = <String, List<AtemschutzEintrag>>{};
    for (var eintrag in protokoll) {
      if (!gruppiertNachFahrzeug.containsKey(eintrag.fahrzeugId)) {
        gruppiertNachFahrzeug[eintrag.fahrzeugId] = [];
      }
      gruppiertNachFahrzeug[eintrag.fahrzeugId]!.add(eintrag);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atemschutz Protokoll',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ...gruppiertNachFahrzeug.entries.map((entry) {
              final fahrzeugId = entry.key;
              final eintraege = entry.value;
              final fahrzeug = einsatz.fahrzeuge.firstWhere(
                (f) => f.id == fahrzeugId,
                orElse: () => Fahrzeug(id: fahrzeugId, name: 'Unbekannt'),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fahrzeug.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  ...eintraege.map((eintrag) => _buildAtemschutzEintrag(eintrag)),
                  
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAtemschutzEintrag(AtemschutzEintrag eintrag) {
    final dateFormat = DateFormat('HH:mm:ss');
    final ereignisText = _getEreignisText(eintrag.ereignis);
    final ereignisColor = _getEreignisColor(eintrag.ereignis);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ereignisColor.withOpacity(0.1),
          border: Border(
            left: BorderSide(
              color: ereignisColor,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${eintrag.truppName} - $ereignisText',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: ereignisColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(eintrag.zeitpunkt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (eintrag.druck != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ereignisColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${eintrag.druck} bar',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineEntry({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
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
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Atemschutz-Einträge',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEreignisText(String ereignis) {
    switch (ereignis) {
      case 'START':
        return 'Gestartet';
      case '20MIN_ALARM':
        return '20 Min Alarm';
      case '10MIN_ALARM':
        return '10 Min Alarm';
      case 'STOP':
        return 'Beendet';
      default:
        return ereignis;
    }
  }

  Color _getEreignisColor(String ereignis) {
    switch (ereignis) {
      case 'START':
        return Colors.green;
      case '20MIN_ALARM':
        return Colors.orange;
      case '10MIN_ALARM':
        return Colors.red;
      case 'STOP':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
