import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/archive_notifier.dart';
import '../providers/personnel_notifier.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedYear = DateTime.now().year;
  final List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _initializeYears();
    // Lade archivierte Operationen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final archiveNotifier = context.read<ArchiveNotifier>();
        archiveNotifier.loadArchivedOperations();
      }
    });
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    for (int year = currentYear; year >= currentYear - 10; year--) {
      _availableYears.add(year);
    }
  }

  Map<int, int> _getOperationsPerMonth(List<dynamic> operations) {
    final monthCounts = <int, int>{};
    for (int i = 1; i <= 12; i++) {
      monthCounts[i] = 0;
    }

    for (var operation in operations) {
      if (operation.einsatzTime.year == _selectedYear) {
        final month = operation.einsatzTime.month;
        monthCounts[month] = (monthCounts[month] ?? 0) + 1;
      }
    }

    return monthCounts;
  }

  Map<String, int> _getOperationTypeStats(List<dynamic> operations) {
    final typeCounts = <String, int>{};

    for (var operation in operations) {
      if (operation.einsatzTime.year == _selectedYear) {
        final type = operation.alarmstichwort;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    return typeCounts;
  }

  Map<String, int> _getDayNightStats(List<dynamic> operations) {
    int dayCount = 0;
    int nightCount = 0;

    for (var operation in operations) {
      if (operation.einsatzTime.year == _selectedYear) {
        final hour = operation.einsatzTime.hour;
        // Nacht: 22:00-5:59, Tag: 06:00-21:59
        if (hour >= 22 || hour < 6) {
          nightCount++;
        } else {
          dayCount++;
        }
      }
    }

    return {'Tag (06:00-21:59)': dayCount, 'Nacht (22:00-05:59)': nightCount};
  }

  Map<String, int> _getPersonnelByTraining(List<dynamic> personnelList) {
    final trainingCounts = <String, int>{};

    for (var person in personnelList) {
      for (var lehrgang in person.lehrgaenge) {
        trainingCounts[lehrgang] = (trainingCounts[lehrgang] ?? 0) + 1;
      }
    }

    return trainingCounts;
  }

  List<MapEntry<String, int>> _getTopPersonnel(
      List<dynamic> operations, List<dynamic> personnelList) {
    final personnelCounts = <String, int>{};

    // Initialisiere alle Personen mit 0
    for (var person in personnelList) {
      personnelCounts[person.name] = 0;
    }

    // Zähle Einsätze pro Person
    for (var operation in operations) {
      final assignments = operation.vehiclePersonnelAssignment;
      for (var vehicleAssignment in assignments.values) {
        for (var personId in vehicleAssignment.keys) {
          // Finde den Namen der Person
          try {
            final person = personnelList.firstWhere(
              (p) => p.id == personId,
            );
            personnelCounts[person.name] = (personnelCounts[person.name] ?? 0) + 1;
          } catch (e) {
            // Person nicht gefunden, überspringen
          }
        }
      }
    }

    // Sortiere und nimm Top 5
    final sortedEntries = personnelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(5).toList();
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return monthNames[month - 1];
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<ArchiveNotifier, PersonnelNotifier>(
        builder: (context, archiveNotifier, personnelNotifier, child) {
          if (!archiveNotifier.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final operations = archiveNotifier.archivedOperations;
          final personnel = personnelNotifier.personnelList;
          final operationsPerMonth = _getOperationsPerMonth(operations);
          final operationTypeStats = _getOperationTypeStats(operations);
          final dayNightStats = _getDayNightStats(operations);
          final trainingStats = _getPersonnelByTraining(personnel);
          final topPersonnel = _getTopPersonnel(operations, personnel);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Einsätze pro Monat
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Einsätze pro Monat',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            DropdownButton<int>(
                              value: _selectedYear,
                              items: _availableYears.map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedYear = value;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildBarChart(operationsPerMonth),
                        const SizedBox(height: 16),
                        Text(
                          'Gesamt $_selectedYear: ${operationsPerMonth.values.reduce((a, b) => a + b)} Einsätze',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Einsatzarten-Statistik
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Einsatzarten',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Jahr: $_selectedYear',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (operationTypeStats.isEmpty)
                          const Text('Keine Einsätze in diesem Jahr')
                        else
                          ...operationTypeStats.entries.map((entry) {
                            final total = operationTypeStats.values.reduce((a, b) => a + b);
                            final percentage = (entry.value / total * 100).toStringAsFixed(1);
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: LinearProgressIndicator(
                                      value: entry.value / total,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                      minHeight: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 70,
                                    child: Text(
                                      '${entry.value} ($percentage%)',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                const SizedBox(height: 20),

                // Tag/Nacht-Statistik
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Einsatzzeiten',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Jahr: $_selectedYear',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (dayNightStats.values.every((v) => v == 0))
                          const Text('Keine Einsätze in diesem Jahr')
                        else
                          Column(
                            children: [
                              _buildDayNightRow(
                                context,
                                Icons.wb_sunny,
                                'Tag (06:00-21:59)',
                                dayNightStats['Tag (06:00-21:59)'] ?? 0,
                                Colors.orange,
                                dayNightStats.values.reduce((a, b) => a + b),
                              ),
                              const SizedBox(height: 12),
                              _buildDayNightRow(
                                context,
                                Icons.nightlight_round,
                                'Nacht (22:00-05:59)',
                                dayNightStats['Nacht (22:00-05:59)'] ?? 0,
                                Colors.indigo,
                                dayNightStats.values.reduce((a, b) => a + b),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Ausbildungsstatistik
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ausbildungsstatistik',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${personnel.length} Mitglieder',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (trainingStats.isEmpty)
                          const Text('Keine Ausbildungsdaten vorhanden')
                        else
                          ...trainingStats.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: LinearProgressIndicator(
                                      value: entry.value / personnel.length,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                      minHeight: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '${entry.value}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                const SizedBox(height: 20),

                // Top 5 Personal
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top 5 Personal (Einsätze)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (topPersonnel.isEmpty ||
                            topPersonnel.first.value == 0)
                          const Text('Keine Einsatzdaten vorhanden')
                        else
                          ...topPersonnel.asMap().entries.map((entry) {
                            final index = entry.key;
                            final person = entry.value;
                            if (person.value == 0) return const SizedBox.shrink();
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getRankColor(index),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      person.key,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${person.value} Einsätze',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                      ),
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChart(Map<int, int> data) {
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final double maxHeight = maxValue > 0 ? maxValue.toDouble() : 1.0;

    return SizedBox(
      height: 220,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final month = entry.key;
          final count = entry.value;
          final barHeight = maxHeight > 0 ? (count / maxHeight) * 160 : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 20,
                    child: count > 0
                        ? Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMonthName(month),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayNightRow(
    BuildContext context,
    IconData icon,
    String label,
    int count,
    Color color,
    int total,
  ) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    
    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 20,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            '$count ($percentage%)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber[700]!; // Gold
      case 1:
        return Colors.grey[400]!; // Silber
      case 2:
        return Colors.brown[400]!; // Bronze
      default:
        return Colors.blue;
    }
  }
}
