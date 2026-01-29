import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
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
" B0 - Kleinstbrand",
" B1 - Brand",
" B2 - Wohnungsbrand",
" B3 - Gebäudebrand",
" B4 - Brand Industrie / Landwirtschaft",
" B5 - Großbrand",
"TH0 - Kleine technische Hilfe",
"TH1 - Technische Hilfeleistung klein",
"TH2 - Technische Hilfeleistung mittel",
"TH3 - Technische Hilfeleistung groß",
"VU0 - Verkehrsunfall klein",
"VU1 - Verkehrsunfall ohne eingeklemmte Person",
"VU2 - Verkehrsunfall mit eingeklemmter Person",
"VU3 - Verkehrsunfall mit mehreren eingeklemmten Personen",
"ABC0 - Kleine Gefahrstofflage",
"ABC1 - Gefahrstoffaustritt gering",
"ABC2 - Gefahrstoffaustritt mittel",
"ABC3 - Gefahrstoffaustritt groß",
"G0 - Gasgeruch / unklare Lage",
"G1 - Gasleck klein",
"G2 - Gasleck mittel",
"G3 - Gasleck groß",
"G4 - Gasunfall / Explosion",
"W0 - Kleine Wasserhilfe",
"W1 - Wasser / Hochwasser klein",
"W2 - Wasser / Hochwasser mittel",
"W3 - Wasser / Hochwasser groß",
"U0 - Umwelteinsatz klein",
"U1 - Umweltschaden",
"U2 - Umweltschaden größer",
"S - Sonstiges"

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
  
  List<String> _filteredAlarmstichworte = [];
  bool _showAlarmstichworteDropdown = false;

  @override
  void initState() {
    super.initState();
    _filteredAlarmstichworte = _standardAlarmstichworte;
    _alarmstichwoertController.addListener(_filterAlarmstichworte);
  }

  void _filterAlarmstichworte() {
    final query = _alarmstichwoertController.text.toLowerCase();
    setState(() {
      _filteredAlarmstichworte = _standardAlarmstichworte
          .where((item) => item.toLowerCase().contains(query))
          .toList();
      _showAlarmstichworteDropdown = query.isNotEmpty;
    });
  }

  void _selectAlarmstichtwort(String value) {
    setState(() {
      _alarmstichwoertController.text = value;
      _showAlarmstichworteDropdown = false;
      _filteredAlarmstichworte = _standardAlarmstichworte;
    });
  }

  Future<void> _getCurrentLocation() async {
    // Zeige Loading-Indikator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('GPS-Position wird ermittelt...'),
            ],
          ),
          duration: Duration(seconds: 8),
        ),
      );
    }

    try {
      // Prüfe ob Standortdienste aktiviert sind
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Standortdienste sind deaktiviert. Bitte aktivieren Sie GPS.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Prüfe auf Standortberechtigungen
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Standortberechtigung verweigert. Bitte geben Sie die Adresse manuell ein.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Standortberechtigung dauerhaft verweigert. Bitte ändern Sie dies in den Einstellungen.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Hole aktuelle Position mit kürzerem Timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() {
          _adresseController.text = '${position.latitude}, ${position.longitude}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS-Koordinaten erfolgreich eingetragen.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS-Fehler: ${e.toString()}. Bitte Adresse manuell eingeben.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _alarmstichwoertController.removeListener(_filterAlarmstichworte);
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
              // Alarmstichwort mit Suchfunktion
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _alarmstichwoertController,
                    decoration: InputDecoration(
                      labelText: 'Alarmstichwort',
                      hintText: 'Schreiben Sie, um Alarmstichwort zu suchen...',
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.warning_amber),
                      suffixIcon: _alarmstichwoertController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _alarmstichwoertController.clear();
                                  _showAlarmstichworteDropdown = false;
                                  _filteredAlarmstichworte = _standardAlarmstichworte;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) {
                      _filterAlarmstichworte();
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alarmstichwort ist erforderlich';
                      }
                      if (!_standardAlarmstichworte.contains(value)) {
                        return 'Bitte wählen Sie ein gültiges Alarmstichwort aus der Liste';
                      }
                      return null;
                    },
                  ),
                  if (_showAlarmstichworteDropdown && _filteredAlarmstichworte.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredAlarmstichworte.length,
                            itemBuilder: (context, index) {
                              final item = _filteredAlarmstichworte[index];
                              return Material(
                                child: InkWell(
                                  onTap: () => _selectAlarmstichtwort(item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      item,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Adresse mit GPS-Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adresseController,
                      decoration: const InputDecoration(
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
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('GPS'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ),
                ],
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
                        label: Text(vehicle.funkrufname),
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
                              '${vehicle.funkrufname} (${assignment.length}/$availableSeats Plätze)',
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
              SizedBox(
                width: 250,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _selectedVehicleIds.isEmpty
                      ? null
                      : () => _saveOperation(),
                  icon: const Icon(Icons.check, size: 24),
                  label: const Text(
                    'Einsatz anlegen',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

    // Sammle alle bereits zugewiesenen Personen-IDs über ALLE Fahrzeuge
    final allAssignedPersonIds = <String>{};
    _vehiclePersonnelAssignment.forEach((vId, vAssignment) {
      allAssignedPersonIds.addAll(vAssignment.keys);
    });
    
    // Verfügbare Personen: nicht zugewiesen oder bereits in dieser Position
    // Deduplizierung nach ID um Duplikate zu vermeiden
    final seenIds = <String>{};
    final availablePersonnel = personnelNotifier.personnelList
        .where((person) {
          final isAssigned = allAssignedPersonIds.contains(person.id);
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

  void _saveOperation() {
    if (_formKey.currentState!.validate()) {
      // Sammle die Fahrzeugnamen
      final vehicleNotifier = context.read<VehicleNotifier>();
      final vehicleNames = <String>[];
      for (var vehicleId in _selectedVehicleIds) {
        final vehicle = vehicleNotifier.vehicleList
            .firstWhereOrNull((v) => v.id == vehicleId);
        if (vehicle != null) {
          vehicleNames.add(vehicle.funkrufname);
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
        respiratoryActive: false,
        atemschutzTrupps: const [],
        vehicleBreathingApparatus: const {},
        externalVehicles: const [],
      );

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
