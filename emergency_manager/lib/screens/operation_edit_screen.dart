import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/operation.dart';
import '../providers/archive_notifier.dart';
import '../providers/vehicle_notifier.dart';
import '../providers/personnel_notifier.dart';

// Extension für firstWhereOrNull
extension FirstWhereOrNullExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

class OperationEditScreen extends StatefulWidget {
  final Operation operation;
  final int operationIndex;

  const OperationEditScreen({
    super.key,
    required this.operation,
    required this.operationIndex,
  });

  @override
  State<OperationEditScreen> createState() => _OperationEditScreenState();
}

class _OperationEditScreenState extends State<OperationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _alarmstichwoertController;
  late TextEditingController _adresseController;
  late DateTime _selectedDateTime;
  late Map<String, Map<String, String>> _vehiclePersonnelAssignment;

  @override
  void initState() {
    super.initState();
    _alarmstichwoertController = TextEditingController(text: widget.operation.alarmstichwort);
    _adresseController = TextEditingController(text: widget.operation.adresseOrGps);
    _selectedDateTime = widget.operation.einsatzTime;
    // Erstelle eine tiefe Kopie der Personalzuweisung
    _vehiclePersonnelAssignment = Map.fromEntries(
      widget.operation.vehiclePersonnelAssignment.entries.map(
        (entry) => MapEntry(entry.key, Map<String, String>.from(entry.value)),
      ),
    );
  }

  @override
  void dispose() {
    _alarmstichwoertController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedOperation = Operation(
        id: widget.operation.id,
        alarmstichwort: _alarmstichwoertController.text.trim(),
        adresseOrGps: _adresseController.text.trim(),
        vehicleIds: widget.operation.vehicleIds,
        vehicleNames: widget.operation.vehicleNames,
        vehiclePersonnelAssignment: _vehiclePersonnelAssignment,
        einsatzTime: _selectedDateTime,
        protocol: widget.operation.protocol,
        respiratoryActive: widget.operation.respiratoryActive,
        atemschutzTrupps: widget.operation.atemschutzTrupps,
        vehicleBreathingApparatus: widget.operation.vehicleBreathingApparatus,
      );

      context.read<ArchiveNotifier>().updateArchivedOperation(
            widget.operationIndex,
            updatedOperation,
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Einsatz wurde aktualisiert'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatz bearbeiten'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Speichern',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grunddaten',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alarmstichwoertController,
                      decoration: const InputDecoration(
                        labelText: 'Alarmstichwort',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.warning_amber),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bitte Alarmstichwort eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adresseController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse / GPS',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bitte Adresse oder GPS eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDateTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Datum & Uhrzeit',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_selectedDateTime.day.toString().padLeft(2, '0')}.${_selectedDateTime.month.toString().padLeft(2, '0')}.${_selectedDateTime.year} '
                          '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hinweis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atemschutztrupps und Protokolleinträge können derzeit nicht bearbeitet werden. '
                      'Diese Daten bleiben unverändert.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Personalzuweisung für jedes Fahrzeug
            Consumer2<VehicleNotifier, PersonnelNotifier>(
              builder: (context, vehicleNotifier, personnelNotifier, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalzuteilung',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ...widget.operation.vehicleIds.asMap().entries.map((entry) {
                              final index = entry.key;
                              final vehicleId = entry.value;
                              final vehicleName = index < widget.operation.vehicleNames.length
                                  ? widget.operation.vehicleNames[index]
                                  : vehicleId;
                              
                              final vehicle = vehicleNotifier.vehicleList
                                  .firstWhereOrNull((v) => v.id == vehicleId);
                              
                              if (vehicle == null) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicleName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fahrzeug nicht mehr verfügbar',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const Divider(height: 32),
                                  ],
                                );
                              }
                              
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.fire_truck,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        vehicleName,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPersonnelSelection(
                                    vehicleId,
                                    vehicle,
                                    personnelNotifier,
                                  ),
                                  const Divider(height: 32),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fahrzeuge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.operation.vehicleNames.isEmpty)
                      const Text('Keine Fahrzeuge')
                    else
                      ...widget.operation.vehicleNames.map((name) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.fire_truck,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(name),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Abbrechen'),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Speichern'),
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

  Widget _buildPersonnelSelection(
    String vehicleId,
    dynamic vehicle,
    PersonnelNotifier personnelNotifier,
  ) {
    final assignment = _vehiclePersonnelAssignment[vehicleId] ?? {};
    
    // Berechne alle verfügbaren Positionen des Fahrzeugs
    final List<String> allPositions = [];
    allPositions.add('Maschinist');
    if (vehicle.hasGroupLeader) allPositions.add('Gruppenführer');
    if (vehicle.hasMessenger) allPositions.add('Melder');
    
    // Trupps mit Führer und Mann
    for (int i = 0; i < vehicle.trupps.length; i++) {
      final truppName = vehicle.trupps[i];
      allPositions.add('$truppName Führer');
      allPositions.add('$truppName Mann');
    }
    
    // Invertiere die Zuordnung: position -> personelId
    final Map<String, String> positionToPersonnel = {};
    assignment.forEach((personelId, position) {
      positionToPersonnel[position] = personelId;
    });

    // Gruppiere Positionen in Paare für 2-spaltige Anordnung
    final List<List<String>> positionPairs = [];
    for (int i = 0; i < allPositions.length; i += 2) {
      if (i + 1 < allPositions.length) {
        positionPairs.add([allPositions[i], allPositions[i + 1]]);
      } else {
        positionPairs.add([allPositions[i]]);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var positionPair in positionPairs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int idx = 0; idx < positionPair.length; idx++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: idx == 0 && positionPair.length > 1 ? 8 : 0,
                      ),
                      child: _buildPositionBox(
                        positionPair[idx],
                        vehicleId,
                        positionToPersonnel,
                        assignment,
                        personnelNotifier,
                        context,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPositionBox(
    String position,
    String vehicleId,
    Map<String, String> positionToPersonnel,
    Map<String, String> assignment,
    PersonnelNotifier personnelNotifier,
    BuildContext context,
  ) {
    // Finde die Person, die diese Position hat
    final currentPersonelId = positionToPersonnel[position];
    final currentPerson = currentPersonelId != null
        ? personnelNotifier.personnelList.firstWhereOrNull(
            (p) => p.id == currentPersonelId,
          )
        : null;

    // Verfügbare Personen: nicht zugewiesen oder bereits in dieser Position
    final seenIds = <String>{};
    final availablePersonnel = personnelNotifier.personnelList
        .where((person) {
          final isAssigned = assignment.containsKey(person.id);
          final isInThisPosition = currentPersonelId == person.id;
          return !isAssigned || isInThisPosition;
        })
        .where((person) {
          if (seenIds.contains(person.id)) {
            return false;
          }
          seenIds.add(person.id);
          return true;
        })
        .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentPerson != null
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            position,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: currentPersonelId,
            decoration: InputDecoration(
              labelText: 'Personal auswählen',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              hintText: 'Nicht zugewiesen',
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('--- Nicht zugewiesen ---'),
              ),
              ...availablePersonnel.map((person) {
                return DropdownMenuItem<String>(
                  value: person.id,
                  child: Text(
                    '${person.name} (${person.dienstgrad})',
                  ),
                );
              }),
            ],
            onChanged: (String? newPersonelId) {
              setState(() {
                if (newPersonelId == null) {
                  // Entferne die Position-Zuordnung
                  positionToPersonnel.remove(position);
                  // Aktualisiere assignment
                  final newAssignment = <String, String>{};
                  positionToPersonnel.forEach((pos, personelId) {
                    newAssignment[personelId] = pos;
                  });
                  _vehiclePersonnelAssignment[vehicleId] = newAssignment;
                } else {
                  // Entferne diese Person aus allen anderen Positionen in diesem Fahrzeug
                  positionToPersonnel.removeWhere(
                      (pos, id) => id == newPersonelId);
                  // Setze neue Zuordnung
                  positionToPersonnel[position] = newPersonelId;
                  // Aktualisiere assignment
                  final newAssignment = <String, String>{};
                  positionToPersonnel.forEach((pos, personelId) {
                    newAssignment[personelId] = pos;
                  });
                  _vehiclePersonnelAssignment[vehicleId] = newAssignment;
                }
              });
            },
          ),
          if (currentPerson != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPerson.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${currentPerson.dienstgrad} - ${currentPerson.position}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
