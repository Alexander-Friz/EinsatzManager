import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/operation.dart';
import '../providers/vehicle_notifier.dart';
import '../providers/personnel_notifier.dart';
import '../providers/archive_notifier.dart';

class OperationPlannerScreen extends StatefulWidget {
  final Operation initialOperation;

  const OperationPlannerScreen({
    required this.initialOperation,
    super.key,
  });

  @override
  State<OperationPlannerScreen> createState() => _OperationPlannerScreenState();
}

class _OperationPlannerScreenState extends State<OperationPlannerScreen> {
  late Operation _currentOperation;
  final bool _isActive = true;
  int _selectedTabIndex = 0; // 0: Fahrzeuge, 1: Einsatzprotokoll, 2: Atemschutz, 3: Übersicht

  @override
  void initState() {
    super.initState();
    _currentOperation = widget.initialOperation;
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildFahrzeugeTab();
      case 1:
        return _buildEinsatzprotokollTab();
      case 2:
        return _buildAtemschutzTab();
      case 3:
        return _buildUebersichtTab();
      default:
        return _buildUebersichtTab();
    }
  }

  Widget _buildUebersichtTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isActive ? 'EINSATZ AKTIV' : 'EINSATZ BEENDET',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentOperation.alarmstichwort,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Einsatzdetails
            Text(
              'Einsatzdetails',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alarmstichwort'),
                            Text(
                              _currentOperation.alarmstichwort,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Adresse'),
                            Text(
                              _currentOperation.adresseOrGps,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Einsatzzeit'),
                            Text(
                              _currentOperation.einsatzTime
                                  .toString()
                                  .split('.')[0],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Aktions-Buttons
            if (_isActive)
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Einsatz beenden und archivieren'),
                        content: const Text(
                          'Möchten Sie diesen Einsatz beenden und archivieren?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final archiveNotifier = context.read<ArchiveNotifier>();
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              
                              Navigator.pop(context);
                              // Archiviere den Einsatz mit aktuellem Protokoll
                              await archiveNotifier.archiveOperation(_currentOperation);
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Einsatz beendet und archiviert'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              // Navigiere zurück ins Hauptmenü
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  navigator.popUntil((route) => route.isFirst);
                                }
                              });
                            },
                            child: const Text('Beenden und Archivieren'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                label: const Text('Einsatz beenden und archivieren'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Schließen'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFahrzeugeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fahrzeugbesatzung',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Consumer2<VehicleNotifier, PersonnelNotifier>(
              builder: (context, vehicleNotifier, personnelNotifier, child) {
                return Column(
                  children: _currentOperation.vehicleIds.map((vehicleId) {
                    final vehicle = vehicleNotifier.vehicleList
                        .firstWhere((v) => v.id == vehicleId);
                    final assignment =
                        _currentOperation.vehiclePersonnelAssignment[vehicleId] ?? {};

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            ...assignment.entries.map((entry) {
                              final person = personnelNotifier.personnelList
                                  .firstWhere((p) => p.id == entry.key);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            person.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                          Text(
                                            '${person.dienstgrad} - ${person.position}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Chip(
                                      label: Text(entry.value),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEinsatzprotokollTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Einsatzprotokoll',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_isActive) ...[
                ElevatedButton.icon(
                  onPressed: () => _showAddProtocolEntryDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Eintrag hinzufügen'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showImagePickerDialog(),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Bild hinzufügen'),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _currentOperation.protocol.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text('Noch keine Einträge'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currentOperation.protocol.length,
                  itemBuilder: (context, index) {
                    final entry = _currentOperation.protocol[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.text,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.timestamp.day}.${entry.timestamp.month}.${entry.timestamp.year}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            if (entry.imageBase64 != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(entry.imageBase64!),
                                  fit: BoxFit.contain,
                                  height: 250,
                                  width: double.infinity,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddProtocolEntryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Protokoll-Eintrag hinzufügen'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Eintrag',
              hintText: 'z.B. Fahrzeuge eingetroffen',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            minLines: 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  setState(() {
                    _currentOperation.protocol.add(
                      ProtocolEntry(
                        text: textController.text,
                        timestamp: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bild aufnehmen oder auswählen'),
          content: const Text('Wählen Sie die Quelle für das Bild:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
              child: const Text('Galerie'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _takeImageWithCamera();
              },
              child: const Text('Kamera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _addImageToProtocol(pickedFile.path);
    }
  }

  Future<void> _takeImageWithCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      await _addImageToProtocol(pickedFile.path);
    }
  }

  Future<void> _addImageToProtocol(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    
    // Speichere das Bild im DCIM Ordner
    try {
      // DCIM Ordner: /sdcard/DCIM/
      final dcimPath = '/sdcard/DCIM';
      final dcimDir = Directory(dcimPath);
      
      if (await dcimDir.exists()) {
        // Speichere das Bild mit Zeitstempel
        final timestamp = DateTime.now().toString().replaceAll(':', '-').split('.')[0];
        final targetPath = '$dcimPath/IMG_$timestamp.jpg';
        await File(imagePath).copy(targetPath);
        print('Bild gespeichert in: $targetPath');
      } else {
        print('DCIM Ordner nicht gefunden');
      }
    } catch (e) {
      print('Fehler beim Speichern in DCIM: $e');
    }
    
    setState(() {
      _currentOperation.protocol.add(
        ProtocolEntry(
          text: 'Bild hinzugefügt',
          timestamp: DateTime.now(),
          imageBase64: base64Image,
        ),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bild zum Protokoll hinzugefügt und im DCIM Ordner gespeichert'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildAtemschutzTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Atemschutz Aktivierungsschalter
            Card(
              color: _currentOperation.respiratoryActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.air,
                          size: 32,
                          color: _currentOperation.respiratoryActive
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Atemschutz im Einsatz'),
                            Text(
                              _currentOperation.respiratoryActive
                                  ? 'AKTIV'
                                  : 'INAKTIV',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: _currentOperation.respiratoryActive
                                        ? Colors.white
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _currentOperation.respiratoryActive,
                      onChanged: _isActive
                          ? (value) {
                              setState(() {
                                // Initialisiere die Trupps wenn Atemschutz aktiviert wird
                                Map<String, RespiratoryTrupp> initialBreathingApparatus =
                                    Map<String, RespiratoryTrupp>.from(
                                      _currentOperation.vehicleBreathingApparatus,
                                    );

                                if (value) {
                                  // Beim Aktivieren: Initialisiere Trupps für alle Fahrzeuge
                                  for (String vehicleId
                                      in _currentOperation.vehicleIds) {
                                    if (!initialBreathingApparatus
                                        .containsKey(vehicleId)) {
                                      initialBreathingApparatus[vehicleId] =
                                          RespiratoryTrupp(
                                        angriffstrupp: 'Angriffstrupp',
                                        sicherungstrupp: 'Wassertrupp',
                                      );
                                    }
                                  }
                                }

                                _currentOperation = Operation(
                                  id: _currentOperation.id,
                                  alarmstichwort: _currentOperation.alarmstichwort,
                                  adresseOrGps: _currentOperation.adresseOrGps,
                                  vehicleIds: _currentOperation.vehicleIds,
                                  vehicleNames: _currentOperation.vehicleNames,
                                  vehiclePersonnelAssignment:
                                      _currentOperation.vehiclePersonnelAssignment,
                                  einsatzTime: _currentOperation.einsatzTime,
                                  protocol: _currentOperation.protocol,
                                  respiratoryActive: value,
                                  vehicleBreathingApparatus:
                                      initialBreathingApparatus,
                                );
                              });
                              // Protokoll-Eintrag hinzufügen
                              _addProtocolEntry(value
                                  ? 'Atemschutz aktiviert'
                                  : 'Atemschutz deaktiviert');
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fahrzeuge mit Trupps
            if (_currentOperation.respiratoryActive) ...[
              Text(
                'Fahrzeuge und Trupps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Consumer2<VehicleNotifier, PersonnelNotifier>(
                builder: (context, vehicleNotifier, personnelNotifier, child) {
                  return Column(
                    children:
                        _currentOperation.vehicleIds.map((vehicleId) {
                      final vehicle = vehicleNotifier.vehicleList
                          .firstWhere((v) => v.id == vehicleId);
                      final breathingApparatus =
                          _currentOperation.vehicleBreathingApparatus[vehicleId];
                      final assignment =
                          _currentOperation.vehiclePersonnelAssignment[vehicleId] ??
                              {};

                      // Sammle Personen nach ihren Trupps
                      final angriffstruppPersonen = assignment.entries
                          .where((e) => e.value.contains('Angriffstrupp'))
                          .map((e) => e.key)
                          .toList();
                      final sicherungstruppPersonen = assignment.entries
                          .where((e) => e.value.contains('Sicherungstrupp'))
                          .map((e) => e.key)
                          .toList();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 16),

                              // Angriffstrupp
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_4,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Angriffstrupp'),
                                          if (angriffstruppPersonen.isNotEmpty)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: angriffstruppPersonen
                                                  .map((personelId) {
                                                final person =
                                                    personnelNotifier.personnelList
                                                        .firstWhere((p) =>
                                                            p.id == personelId);
                                                return Text(
                                                  person.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                );
                                              }).toList(),
                                            )
                                          else
                                            const Text(
                                              'Keine Personen zugewiesen',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Sicherungstrupp
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person_3,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('Sicherungstrupp'),
                                              if (sicherungstruppPersonen
                                                  .isNotEmpty)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: sicherungstruppPersonen
                                                      .map((personelId) {
                                                    final person = personnelNotifier
                                                        .personnelList
                                                        .firstWhere((p) =>
                                                            p.id == personelId);
                                                    return Text(
                                                      person.name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall,
                                                    );
                                                  }).toList(),
                                                )
                                              else
                                                const Text(
                                                  'Keine Personen zugewiesen',
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SegmentedButton<String>(
                                      segments: const [
                                        ButtonSegment(
                                          value: 'Wassertrupp',
                                          label: Text('Wassertrupp'),
                                          icon: Icon(Icons.water_drop),
                                        ),
                                        ButtonSegment(
                                          value: 'Schlauchtrupp',
                                          label: Text('Schlauchtrupp'),
                                          icon: Icon(Icons.fire_extinguisher),
                                        ),
                                      ],
                                      selected: {
                                        breathingApparatus?.sicherungstrupp ??
                                            'Wassertrupp'
                                      },
                                      onSelectionChanged: (newSelection) {
                                        final oldType =
                                            breathingApparatus?.sicherungstrupp;
                                        final newType = newSelection.first;

                                        setState(() {
                                          final updatedMap = Map<String,
                                              RespiratoryTrupp>.from(
                                            _currentOperation
                                                .vehicleBreathingApparatus,
                                          );
                                          updatedMap[vehicleId] =
                                              RespiratoryTrupp(
                                            angriffstrupp:
                                                breathingApparatus?.angriffstrupp ??
                                                    'Unbekannt',
                                            sicherungstrupp: newType,
                                          );
                                          _currentOperation = Operation(
                                            id: _currentOperation.id,
                                            alarmstichwort:
                                                _currentOperation.alarmstichwort,
                                            adresseOrGps:
                                                _currentOperation.adresseOrGps,
                                            vehicleIds:
                                                _currentOperation.vehicleIds,
                                            vehicleNames:
                                                _currentOperation.vehicleNames,
                                            vehiclePersonnelAssignment:
                                                _currentOperation
                                                    .vehiclePersonnelAssignment,
                                            einsatzTime:
                                                _currentOperation.einsatzTime,
                                            protocol:
                                                _currentOperation.protocol,
                                            respiratoryActive:
                                                _currentOperation
                                                    .respiratoryActive,
                                            vehicleBreathingApparatus:
                                                updatedMap,
                                          );
                                        });

                                        // Protokoll-Eintrag hinzufügen
                                        _addProtocolEntry(
                                          '${vehicle.name}: Sicherungstrupp geändert von $oldType zu $newType',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ] else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.air,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    const Text('Atemschutz ist nicht aktiviert'),
                    const SizedBox(height: 8),
                    const Text(
                      'Aktivieren Sie den Schalter oben, um Atemschutztrupps zu verwalten',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addProtocolEntry(String text) {
    setState(() {
      _currentOperation.protocol.add(
        ProtocolEntry(
          text: text,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzplaner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 50,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isActive
              ? null
              : () {
                  Navigator.pop(context);
                },
          tooltip: _isActive ? 'Einsatz läuft noch' : 'Schließen',
        ),
      ),
      body: _buildTabContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Fahrzeuge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Einsatzprotokoll',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.air),
            label: 'Atemschutz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Übersicht',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
      ),
    );
  }
}
