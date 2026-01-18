import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/operation.dart';
import '../providers/vehicle_notifier.dart';
import '../providers/personnel_notifier.dart';
import 'operation_planner_screen.dart';

// Extension für firstWhereOrNull
extension FirstWhereOrNullExt<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// Standardisierte Alarmstichworte
const List<String> _standardAlarmstichworte = [
  'B1 - Brennend',
  'B2 - Brennend (Gebäude)',
  'B3 - Brennend (Fahrzeug)',
  'B4 - Brennend (Sonstiges)',
  'B5 - Brennend (Außenbereich)',
  'TH - Technische Hilfeleistung',
  'TH1 - Verkehrsunfall',
  'TH2 - Personenrettung',
  'TH3 - Befreiung',
  'TH4 - Verkehrsunfall mit Personenschaden',
  'G - Gefahrguteinsatz',
  'A - ABC-Einsatz',
  'W - Wasser/Hochwasser',
  'WB - Wildfireeinsatz',
  'HB - Havarist',
  'FOE - Feuer Öffentlicher Einsatz',
  'AAO - Automatische Alarmierungsmaßnahme',
  'VU - Verkehrsunfall',
  'Person vermisst',
  'Falschalarm',
];

class OperationCreateScreen extends StatefulWidget {
  const OperationCreateScreen({super.key});

  @override
  State<OperationCreateScreen> createState() => _OperationCreateScreenState();
}

class _OperationCreateScreenState extends State<OperationCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alarmstichwoertController = TextEditingController();
  final _adresseController = TextEditingController();
  
  final List<String> _selectedVehicleIds = [];
  // vehicleId -> { personelId -> trupp/function }
  final Map<String, Map<String, String>> _vehiclePersonnelAssignment = {};

  @override
  void dispose() {
    _alarmstichwoertController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatz anlegen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alarmstichwort mit DropdownButtonFormField
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Alarmstichwort',
                  hintText: 'Wählen Sie ein Alarmstichwort',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                items: _standardAlarmstichworte.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    _alarmstichwoertController.text = value;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alarmstichwort ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                controller: _adresseController,
                decoration: InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'z.B. Hauptstraße 42, 12345 Musterstadt',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Adresse ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Fahrzeugauswahl
              Text(
                'Fahrzeuge auswählen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Consumer<VehicleNotifier>(
                builder: (context, vehicleNotifier, child) {
                  return Wrap(
                    spacing: 8,
                    children: vehicleNotifier.vehicleList.map((vehicle) {
                      final isSelected = _selectedVehicleIds.contains(vehicle.id);
                      return FilterChip(
                        label: Text(vehicle.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedVehicleIds.add(vehicle.id);
                              _vehiclePersonnelAssignment[vehicle.id] = {};
                            } else {
                              _selectedVehicleIds.remove(vehicle.id);
                              _vehiclePersonnelAssignment.remove(vehicle.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Personalauswahl für jedes Fahrzeug
              if (_selectedVehicleIds.isNotEmpty)
                Consumer2<VehicleNotifier, PersonnelNotifier>(
                  builder: (context, vehicleNotifier, personnelNotifier, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _selectedVehicleIds.map((vehicleId) {
                        final vehicle = vehicleNotifier.vehicleList
                            .firstWhere((v) => v.id == vehicleId);
                        final assignment =
                            _vehiclePersonnelAssignment[vehicleId] ?? {};

                        // Berechne verfügbare Sitzplätze
                        int availableSeats = 1; // Maschinist
                        if (vehicle.hasGroupLeader) availableSeats++;
                        if (vehicle.hasMessenger) availableSeats++;
                        availableSeats += (vehicle.trupps.length * 2).toInt();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.name} (${assignment.length}/$availableSeats Plätze)',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            _buildPersonnelSelection(
                              vehicleId,
                              vehicle,
                              availableSeats,
                              personnelNotifier,
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),

              // Uhrzeit anzeigen
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time),
                    const SizedBox(width: 12),
                    Text(
                      'Einsatzzeit: ${DateTime.now().toString().split('.')[0]}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Speichern Button
              ElevatedButton.icon(
                onPressed: _selectedVehicleIds.isEmpty
                    ? null
                    : () => _saveOperation(),
                icon: const Icon(Icons.check),
                label: const Text('Einsatz anlegen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonnelSelection(
    String vehicleId,
    dynamic vehicle,
    int maxSeats,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var position in allPositions)
          Builder(
            builder: (BuildContext context) {
              // Finde die Person, die diese Position hat
              final currentPersonelId = positionToPersonnel[position];
              final currentPerson = currentPersonelId != null
                  ? personnelNotifier.personnelList.firstWhereOrNull(
                      (p) => p.id == currentPersonelId,
                    )
                  : null;

              // Verfügbare Personen: nicht zugewiesen oder bereits in dieser Position
              final availablePersonnel = personnelNotifier.personnelList
                  .where((person) {
                    final isAssigned = assignment.containsKey(person.id);
                    final isInThisPosition = currentPersonelId == person.id;
                    return !isAssigned || isInThisPosition;
                  })
                  .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
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
                        initialValue: currentPersonelId,
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
                              // Entferne alte Zuordnung wenn diese Person schon woanders war
                              positionToPersonnel.removeWhere(
                                  (pos, id) => id == newPersonelId && pos != position);
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
                ),
              );
            },
          ),
      ],
    );
  }

  void _saveOperation() {
    if (_formKey.currentState!.validate()) {
      // Sammle die Fahrzeugnamen
      final vehicleNotifier = context.read<VehicleNotifier>();
      final vehicleNames = <String>[];
      for (var vehicleId in _selectedVehicleIds) {
        final vehicle = vehicleNotifier.vehicleList
            .firstWhereOrNull((v) => v.id == vehicleId);
        if (vehicle != null) {
          vehicleNames.add(vehicle.name);
        }
      }

      final operation = Operation(
        alarmstichwort: _alarmstichwoertController.text,
        adresseOrGps: _adresseController.text,
        vehicleIds: _selectedVehicleIds,
        vehicleNames: vehicleNames,
        vehiclePersonnelAssignment: _vehiclePersonnelAssignment,
        einsatzTime: DateTime.now(),
        protocol: [
          ProtocolEntry(
            text: 'Einsatz Start',
            timestamp: DateTime.now(),
          ),
        ],
      );

      // TODO: Speichern des Einsatzes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Einsatz angelegt: ${operation.alarmstichwort}',
          ),
        ),
      );

      // Navigiere zum Einsatzplaner
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OperationPlannerScreen(
            initialOperation: operation,
          ),
        ),
      );
    }
  }
}
