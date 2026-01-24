import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/operation.dart';
import '../providers/vehicle_notifier.dart';
import '../providers/personnel_notifier.dart';
import '../providers/archive_notifier.dart';
import '../services/audio_recorder_service.dart';
import '../services/pdf_service.dart';

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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _alertedTrupps = {}; // Trupps die bereits alarmiert wurden
  final Set<String> _alertedPressureChecks = {}; // Druckprüfungen die bereits Alarm gespielt haben
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  bool _isPlaying = false;
  String? _currentPlayingPath;

  @override
  void initState() {
    super.initState();
    _currentOperation = widget.initialOperation;
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fahrzeugbesatzung',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddVehicleDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Fahrzeug hinzufügen'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer2<VehicleNotifier, PersonnelNotifier>(
              builder: (context, vehicleNotifier, personnelNotifier, child) {
                return Column(
                  children: [
                    // Eigene Fahrzeuge
                    ..._currentOperation.vehicleIds.map((vehicleId) {
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    vehicle.funkrufname,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () => _showEditPersonnelDialog(vehicleId, vehicle.funkrufname),
                                        tooltip: 'Besatzung bearbeiten',
                                        color: Colors.blue,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        onPressed: () => _removeVehicle(vehicleId),
                                        tooltip: 'Fahrzeug entfernen',
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
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
                              if (assignment.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    'Keine Besatzung zugewiesen',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    // Externe Fahrzeuge
                    ..._currentOperation.externalVehicles.map((externalVehicle) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.groups,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        externalVehicle,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _removeExternalVehicle(externalVehicle),
                                    tooltip: 'Externes Fahrzeug entfernen',
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Externes Fahrzeug (andere Wehr)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
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
          child: Column(
            children: [
              // PDF Export Button - ganz oben
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _currentOperation.protocol.isEmpty
                      ? null
                      : () => _exportProtocolToPdf(),
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: const Text('Protokoll als PDF drucken'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Einsatzprotokoll',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_isActive) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddProtocolEntryDialog(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Eintrag'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showImagePickerDialog(),
                        icon: const Icon(Icons.camera_alt, size: 20),
                        label: const Text('Bild'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showVoiceRecordingDialog(),
                        icon: const Icon(Icons.mic, size: 20),
                        label: const Text('Audio'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        ),
                      ),
                    ),
                  ],
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
                            if (entry.audioPath != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Builder(
                                  builder: (context) {
                                    final isThisPlaying = _isPlaying && _currentPlayingPath == entry.audioPath!;
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.audiotrack,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Sprachnotiz',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(isThisPlaying ? Icons.pause : Icons.play_arrow),
                                          onPressed: () => _toggleAudioPlayback(entry.audioPath!),
                                          tooltip: isThisPlaying ? 'Pausieren' : 'Abspielen',
                                        ),
                                      ],
                                    );
                                  },
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

  Future<void> _exportProtocolToPdf() async {
    try {
      final personnelNotifier = context.read<PersonnelNotifier>();
      
      await PdfService.generateOperationProtocolPdf(
        alarmstichwort: _currentOperation.alarmstichwort,
        adresse: _currentOperation.adresseOrGps,
        einsatzTime: _currentOperation.einsatzTime,
        vehicleNames: _currentOperation.vehicleNames,
        protocol: _currentOperation.protocol,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        personnelList: personnelNotifier.personnelList,
        atemschutzTrupps: _currentOperation.atemschutzTrupps,
        externalVehicles: _currentOperation.externalVehicles,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim PDF-Export: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

  // Sprachnotizen-Methoden
  void _showVoiceRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _VoiceRecordingDialog(
          audioRecorderService: _audioRecorderService,
          onRecordingSaved: (String audioPath) {
            setState(() {
              _currentOperation.protocol.add(
                ProtocolEntry(
                  text: 'Sprachnotiz',
                  timestamp: DateTime.now(),
                  audioPath: audioPath,
                ),
              );
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sprachnotiz gespeichert'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _toggleAudioPlayback(String audioPath) async {
    try {
      // Wenn diese Audiodatei gerade spielt, pausiere sie
      if (_isPlaying && _currentPlayingPath == audioPath) {
        await _audioPlayer.pause();
      } else {
        // Wenn eine andere Audiodatei spielt oder keine spielt, spiele diese ab
        await _audioPlayer.stop();
        _currentPlayingPath = audioPath;
        await _audioPlayer.play(DeviceFileSource(audioPath));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abspielen: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildAtemschutzTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Atemschutztrupps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: _showAddTruppDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Trupp anlegen'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Atemschutztrupps (sortiert nach Zeit, neueste zuerst)
            if (_currentOperation.atemschutzTrupps.isNotEmpty) ...[
              Consumer2<VehicleNotifier, PersonnelNotifier>(
                builder: (context, vehicleNotifier, personnelNotifier, child) {
                  // Sortiere Trupps nach Zeit (neueste zuerst)
                  final sortedTrupps = List<AtemschutzTrupp>.from(_currentOperation.atemschutzTrupps)
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  
                  return Column(
                    children:
                        sortedTrupps.map((trupp) {
                      
                      // Hole die Personennamen
                      String person1Name;
                      String person2Name;
                      
                      if (trupp.isVehicleLinked) {
                        // Fahrzeug-Trupp: Suche in Personalliste
                        final person1 = personnelNotifier.personnelList.firstWhere(
                                (p) => p.id == trupp.person1Id,
                                orElse: () => PersonalData(
                                  id: 'unknown',
                                  name: 'Unbekannt',
                                  email: '',
                                  phone: '',
                                  position: '',
                                  dienstgrad: '',
                                  lehrgaenge: [],
                                ));
                        
                        final person2 = personnelNotifier.personnelList.firstWhere(
                                (p) => p.id == trupp.person2Id,
                                orElse: () => PersonalData(
                                  id: 'unknown',
                                  name: 'Unbekannt',
                                  email: '',
                                  phone: '',
                                  position: '',
                                  dienstgrad: '',
                                  lehrgaenge: [],
                                ));
                        
                        person1Name = person1.name;
                        person2Name = person2.name;
                      } else {
                        // GS-Trupp: Prüfe ob IDs oder Namen gespeichert sind
                        // Wenn eine Person mit dieser ID existiert, ist es eine ID
                        final person1FromList = personnelNotifier.personnelList.firstWhere(
                                (p) => p.id == trupp.person1Id,
                                orElse: () => PersonalData(
                                  id: 'unknown',
                                  name: 'Unbekannt',
                                  email: '',
                                  phone: '',
                                  position: '',
                                  dienstgrad: '',
                                  lehrgaenge: [],
                                ));
                        
                        final person2FromList = personnelNotifier.personnelList.firstWhere(
                                (p) => p.id == trupp.person2Id,
                                orElse: () => PersonalData(
                                  id: 'unknown',
                                  name: 'Unbekannt',
                                  email: '',
                                  phone: '',
                                  position: '',
                                  dienstgrad: '',
                                  lehrgaenge: [],
                                ));
                        
                        // Wenn die Person gefunden wurde (id != 'unknown'), dann verwende den Namen
                        // Ansonsten ist es bereits ein Name (Freitexteingabe)
                        person1Name = person1FromList.id != 'unknown' ? person1FromList.name : trupp.person1Id;
                        person2Name = person2FromList.id != 'unknown' ? person2FromList.name : trupp.person2Id;
                      }
                      
                      if (trupp.isVehicleLinked) {
                        // Fahrzeug-Trupp
                        final vehicle = vehicleNotifier.vehicleList
                            .firstWhere((v) => v.id == trupp.vehicleId);
                        
                        // Berechne ob Zeit abgelaufen ist für Styling
                        final remainingTime = _calculateRemainingTime(trupp);
                        final isTimeExpired = remainingTime.isNegative && trupp.isActive;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: isTimeExpired ? 8 : 1,
                          color: isTimeExpired ? Colors.red.shade50 : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isTimeExpired ? Colors.red.shade700 : Colors.transparent,
                              width: isTimeExpired ? 3 : 0,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isTimeExpired ? Colors.red.shade100 : null,
                            ),
                            child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${vehicle.funkrufname} - ${trupp.name}',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '${trupp.createdAt.hour.toString().padLeft(2, '0')}:${trupp.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                      Icon(Icons.people,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              person1Name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              person2Name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Countdown Timer
                                _buildTimerSection(trupp),
                              ],
                            ),
                          ),
                          ),
                        );
                      } else {
                        // Großschadenslagen-Trupp
                        // Berechne ob Zeit abgelaufen ist für Styling
                        final remainingTime = _calculateRemainingTime(trupp);
                        final isTimeExpired = remainingTime.isNegative && trupp.isActive;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: isTimeExpired ? 8 : 1,
                          color: isTimeExpired ? Colors.deepOrange.shade50 : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isTimeExpired ? Colors.deepOrange.shade700 : Colors.transparent,
                              width: isTimeExpired ? 3 : 0,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isTimeExpired ? Colors.deepOrange.shade100 : null,
                            ),
                            child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'GS - ${trupp.name}',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '${trupp.createdAt.hour.toString().padLeft(2, '0')}:${trupp.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.people,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiaryContainer),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              person1Name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                            ),
                                            Text(
                                              person2Name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Countdown Timer
                                _buildTimerSection(trupp),
                              ],
                            ),
                          ),
                          ),
                        );
                      }
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
                    const Text('Noch keine Atemschutztrupps angelegt'),
                    const SizedBox(height: 8),
                    const Text(
                      'Klicken Sie auf "Trupp anlegen", um Ihre ersten Trupps zu erstellen',
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

  void _showAddTruppDialog() {
    String? selectedVehicleId;
    String? selectedTrupp;
    String? selectedPerson1Id;
    String? selectedPerson2Id;
    String freetruppName = '';
    String person1Name = '';
    String person2Name = '';
    bool isVehicleLinked = true;
    String nameInputMode = 'name'; // 'name' oder 'personnel'
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final vehicleNotifier = this.context.read<VehicleNotifier>();
        final personnelNotifier = this.context.read<PersonnelNotifier>();
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Atemschutztrupp anlegen'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bereits angelegte Trupps anzeigen
                    if (_currentOperation.atemschutzTrupps.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bereits angelegte Trupps:',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            ..._currentOperation.atemschutzTrupps.map((trupp) {
                              if (trupp.vehicleId != null) {
                                final vehicle = vehicleNotifier.vehicleList
                                    .firstWhere((v) => v.id == trupp.vehicleId);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• ${vehicle.funkrufname}: ${trupp.name}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• GS: ${trupp.name}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Toggle: Mit oder ohne Fahrzeugbezug
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Mit Fahrzeugbezug'),
                          icon: Icon(Icons.local_shipping),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Ohne Fahrzeugbezug'),
                          icon: Icon(Icons.people),
                        ),
                      ],
                      selected: {isVehicleLinked},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          isVehicleLinked = newSelection.first;
                          selectedVehicleId = null;
                          selectedTrupp = null;
                          selectedPerson1Id = null;
                          selectedPerson2Id = null;
                          freetruppName = '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (isVehicleLinked) ...[
                      const Text('1. Wählen Sie ein Fahrzeug:'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedVehicleId,
                        hint: const Text('Fahrzeug wählen'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        items: _currentOperation.vehicleIds.map((vehicleId) {
                          final vehicle = vehicleNotifier.vehicleList
                              .firstWhere((v) => v.id == vehicleId);
                          return DropdownMenuItem<String>(
                            value: vehicleId,
                            child: Text(vehicle.funkrufname),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedVehicleId = value;
                            selectedTrupp = null;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedVehicleId != null) ...[
                        const Text('2. Wählen Sie einen Trupp:'),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final vehicle = vehicleNotifier.vehicleList
                                .firstWhere((v) => v.id == selectedVehicleId);
                            
                            // Trupps die bereits für dieses Fahrzeug verwendet wurden
                            final usedTrupps = <String>{};
                            for (var atTrupp in _currentOperation.atemschutzTrupps) {
                              if (atTrupp.vehicleId == selectedVehicleId) {
                                usedTrupps.add(atTrupp.name);
                              }
                            }
                            
                            final availableTrupps = vehicle.trupps
                                .where((t) => !usedTrupps.contains(t))
                                .toList();

                            if (availableTrupps.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orange.shade300),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Alle Trupps dieses Fahrzeugs sind bereits angelegt',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedTrupp,
                              hint: const Text('Trupp wählen (z.B. Angriffstrupp)'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              items: availableTrupps.map((trupp) {
                                return DropdownMenuItem<String>(
                                  value: trupp,
                                  child: Text(trupp),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedTrupp = value;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Zeige automatisch zugewiesene Personen an
                        if (selectedTrupp != null) ...[
                          const Text('Truppbesetzung:'),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final assignedPersonnel = _currentOperation.vehiclePersonnelAssignment[selectedVehicleId];
                              
                              if (assignedPersonnel == null || assignedPersonnel.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.shade300),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.error, color: Colors.red),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Diesem Fahrzeug ist keine Besatzung zugewiesen. Bitte weisen Sie zunächst Personal zu.',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              // Finde Personen basierend auf Rolle
                              final truppFuehrerRole = '$selectedTrupp Führer';
                              final truppMannRole = '$selectedTrupp Mann';
                              
                              String? fuehrerId;
                              String? mannId;
                              
                              assignedPersonnel.forEach((personId, role) {
                                if (role == truppFuehrerRole) {
                                  fuehrerId = personId;
                                } else if (role == truppMannRole) {
                                  mannId = personId;
                                }
                              });
                              
                              if (fuehrerId == null || mannId == null) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.orange.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.warning, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Unvollständige Truppbesetzung',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Fehlende Rollen:\n${fuehrerId == null ? '• $truppFuehrerRole\n' : ''}${mannId == null ? '• $truppMannRole' : ''}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Bitte weisen Sie die entsprechenden Rollen in der Fahrzeugbesatzung zu.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              final fuehrer = personnelNotifier.personnelList
                                  .firstWhere((p) => p.id == fuehrerId);
                              final mann = personnelNotifier.personnelList
                                  .firstWhere((p) => p.id == mannId);
                              
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$selectedTrupp Führer: ${fuehrer.name}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$selectedTrupp Mann: ${mann.name}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ] else ...[
                      // Truppname (immer Freitext)
                      const Text('Truppname:'),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: InputDecoration(
                          hintText: 'z.B. Angriffstrupp, Sondertrupp',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            freetruppName = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Auswahl: Personen eingeben oder aus Liste wählen
                      const Text('Personen:'),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'name',
                            label: Text('Namen eingeben'),
                          ),
                          ButtonSegment(
                            value: 'personnel',
                            label: Text('Aus Personal wählen'),
                          ),
                        ],
                        selected: {nameInputMode},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            nameInputMode = newSelection.first;
                            if (nameInputMode == 'name') {
                              selectedPerson1Id = null;
                              selectedPerson2Id = null;
                            } else {
                              person1Name = '';
                              person2Name = '';
                            }
                          });
                        },
                      ),
                    ],
                    
                    // Truppbesetzung nur bei Großschadenslagen anzeigen
                    if (!isVehicleLinked) ...[
                      const SizedBox(height: 16),
                      const Text('Truppbesetzung:'),
                      Text(
                        nameInputMode == 'name' 
                          ? 'Geben Sie die Namen der zwei Personen ein'
                          : 'Wählen Sie zwei Personen für den Trupp',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 12),
                      
                      // Bei "Namen eingeben": Textfelder für Personennamen
                      if (nameInputMode == 'name') ...[
                        const Text('1. Person:'),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Name der ersten Person',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              person1Name = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        const Text('2. Person:'),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Name der zweiten Person',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              person2Name = value;
                            });
                          },
                        ),
                      ],
                      
                      // Bei "Aus Personal": Dropdowns für Personenauswahl
                      if (nameInputMode == 'personnel') ...[
                        const Text('1. Person:'),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            // Dedupliziere die Liste
                            final seenIds = <String>{};
                            final uniquePersonnel = personnelNotifier.personnelList.where((person) {
                              if (seenIds.contains(person.id)) {
                                return false;
                              }
                              seenIds.add(person.id);
                              return true;
                            }).toList();
                            
                            return DropdownButtonFormField<String>(
                              value: selectedPerson1Id,
                              hint: const Text('Person wählen'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              items: uniquePersonnel.map((person) {
                                return DropdownMenuItem<String>(
                                  value: person.id,
                                  child: Text('${person.name} (${person.dienstgrad})'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPerson1Id = value;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        const Text('2. Person:'),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            // Dedupliziere die Liste
                            final seenIds = <String>{};
                            final uniquePersonnel = personnelNotifier.personnelList.where((person) {
                              if (seenIds.contains(person.id)) {
                                return false;
                              }
                              seenIds.add(person.id);
                              return true;
                            }).toList();
                            
                            return DropdownButtonFormField<String>(
                              value: selectedPerson2Id,
                              hint: const Text('Person wählen'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              items: uniquePersonnel.map((person) {
                                return DropdownMenuItem<String>(
                                  value: person.id,
                                  child: Text('${person.name} (${person.dienstgrad})'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedPerson2Id = value;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: _canCreateTrupp(
                    isVehicleLinked,
                    selectedVehicleId,
                    selectedTrupp,
                    freetruppName,
                    nameInputMode,
                    person1Name,
                    person2Name,
                    selectedPerson1Id,
                    selectedPerson2Id,
                  )
                      ? () {
                          _createTrupp(
                            isVehicleLinked,
                            selectedVehicleId,
                            selectedTrupp,
                            freetruppName,
                            nameInputMode,
                            person1Name,
                            person2Name,
                            selectedPerson1Id,
                            selectedPerson2Id,
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Atemschutztrupp anlegen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _canCreateTrupp(
    bool isVehicleLinked,
    String? selectedVehicleId,
    String? selectedTrupp,
    String freetruppName,
    String nameInputMode,
    String person1Name,
    String person2Name,
    String? selectedPerson1Id,
    String? selectedPerson2Id,
  ) {
    if (isVehicleLinked) {
      // Bei Fahrzeugbezug: nur Fahrzeug und Trupp erforderlich (Personen werden automatisch zugewiesen)
      return selectedVehicleId != null && selectedTrupp != null;
    } else {
      // Bei Großschadenslagen: Name erforderlich
      if (freetruppName.trim().isEmpty) return false;
      
      if (nameInputMode == 'name') {
        // Bei Freitexteingabe: beide Personennamen müssen eingegeben sein
        return person1Name.trim().isNotEmpty && person2Name.trim().isNotEmpty;
      } else {
        // Bei Personalauswahl: beide Personen müssen ausgewählt und unterschiedlich sein
        if (selectedPerson1Id == null || selectedPerson2Id == null) return false;
        if (selectedPerson1Id == selectedPerson2Id) return false;
        return true;
      }
    }
  }

  void _createTrupp(
    bool isVehicleLinked,
    String? selectedVehicleId,
    String? selectedTrupp,
    String freetruppName,
    String nameInputMode,
    String person1Name,
    String person2Name,
    String? selectedPerson1Id,
    String? selectedPerson2Id,
  ) {
    setState(() {
      final updatedList = List<AtemschutzTrupp>.from(
        _currentOperation.atemschutzTrupps,
      );

      if (isVehicleLinked && selectedVehicleId != null && selectedTrupp != null) {
        // Mit Fahrzeugbezug - finde Personen automatisch basierend auf Rollen
        final assignedPersonnel = _currentOperation.vehiclePersonnelAssignment[selectedVehicleId];
        
        if (assignedPersonnel != null && assignedPersonnel.isNotEmpty) {
          String? person1Id;
          String? person2Id;
          
          // Suche nach Truppführer und Truppmann für den gewählten Trupp
          final truppFuehrerRole = '$selectedTrupp Führer';
          final truppMannRole = '$selectedTrupp Mann';
          
          assignedPersonnel.forEach((personId, role) {
            if (role == truppFuehrerRole) {
              person1Id = personId;
            } else if (role == truppMannRole) {
              person2Id = personId;
            }
          });
          
          if (person1Id != null && person2Id != null) {
            // Hole die Namen für das Protokoll
            final person1 = context.read<PersonnelNotifier>().personnelList
                .firstWhere((p) => p.id == person1Id, orElse: () => PersonalData(
                  id: 'unknown', name: 'Unbekannt', email: '', phone: '', 
                  position: '', dienstgrad: '', lehrgaenge: []));
            final person2 = context.read<PersonnelNotifier>().personnelList
                .firstWhere((p) => p.id == person2Id, orElse: () => PersonalData(
                  id: 'unknown', name: 'Unbekannt', email: '', phone: '', 
                  position: '', dienstgrad: '', lehrgaenge: []));
            
            updatedList.add(AtemschutzTrupp(
              name: selectedTrupp,
              vehicleId: selectedVehicleId,
              person1Id: person1Id!,
              person2Id: person2Id!,
            ));
            
            _addProtocolEntry('Atemschutztrupp "$selectedTrupp" angelegt: ${person1.name}, ${person2.name}');
          }
        }
      } else {
        // Ohne Fahrzeugbezug (Großschadenslagen)
        if (nameInputMode == 'name') {
          // Freitexteingabe - speichere die Namen direkt
          final name1 = person1Name.trim();
          final name2 = person2Name.trim();
          
          updatedList.add(AtemschutzTrupp(
            name: freetruppName,
            vehicleId: null,
            person1Id: name1,
            person2Id: name2,
          ));
          
          _addProtocolEntry('Großschadenslagen-Atemschutztrupp "$freetruppName" angelegt: $name1, $name2');
        } else {
          // Personalauswahl - verwende ausgewählte Personen
          if (selectedPerson1Id != null && selectedPerson2Id != null) {
            final person1 = context.read<PersonnelNotifier>().personnelList
                .firstWhere((p) => p.id == selectedPerson1Id, orElse: () => PersonalData(
                  id: 'unknown', name: 'Unbekannt', email: '', phone: '', 
                  position: '', dienstgrad: '', lehrgaenge: []));
            final person2 = context.read<PersonnelNotifier>().personnelList
                .firstWhere((p) => p.id == selectedPerson2Id, orElse: () => PersonalData(
                  id: 'unknown', name: 'Unbekannt', email: '', phone: '', 
                  position: '', dienstgrad: '', lehrgaenge: []));
            
            updatedList.add(AtemschutzTrupp(
              name: freetruppName,
              vehicleId: null,
              person1Id: selectedPerson1Id,
              person2Id: selectedPerson2Id,
            ));
            
            _addProtocolEntry('Großschadenslagen-Atemschutztrupp "$freetruppName" angelegt: ${person1.name}, ${person2.name}');
          }
        }
      }

      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: true,
        atemschutzTrupps: updatedList,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
  }

  void _showSaveOperationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Einsatz speichern'),
          content: const Text(
            'Möchten Sie diesen Einsatz beenden und archivieren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nein'),
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
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
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
              ? () => _showSaveOperationDialog()
              : () {
                  Navigator.pop(context);
                },
          tooltip: _isActive ? 'Einsatz speichern und beenden' : 'Schließen',
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

  Widget _buildTimerSection(AtemschutzTrupp trupp) {
    if (trupp.isCompleted) {
      // Einsatz beendet
      if (trupp.roundNumber < 2) {
        // Erster Durchgang beendet - Option für zweiten Durchgang
        return ElevatedButton.icon(
          onPressed: () => _startSecondRound(trupp),
          icon: const Icon(Icons.replay),
          label: const Text('Zweiten Durchgang starten'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        // Zweiter Durchgang beendet - kein weiterer Durchgang möglich
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Einsatz abgeschlossen (2 Durchgänge)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        );
      }
    } else if (trupp.startTime == null) {
      // Noch nicht gestartet - Startknopf anzeigen
      return ElevatedButton.icon(
        onPressed: () => _showPressureDialog(trupp),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Stoppuhr starten'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
      );
    } else if (!trupp.isActive) {
      // Pausiert - Resume-Knopf anzeigen
      return ElevatedButton.icon(
        onPressed: () => _showResumePressureDialog(trupp),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Fortsetzen'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // Timer läuft - Anzeige mit Pause-Button
      return StreamBuilder<void>(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, snapshot) {
          final remainingTime = _calculateRemainingTime(trupp);
          final isWarning = remainingTime.inMinutes < 5;
          final isAlert = remainingTime.isNegative;
          
          // Prüfe ob Druckabfragen fällig sind - NACH dem Build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkPressureIntervals(trupp, remainingTime);
          });
          
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAlert 
                  ? Colors.red.shade100 
                  : isWarning 
                      ? Colors.orange.shade100 
                      : Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: isAlert 
                              ? Colors.red.shade900 
                              : isWarning 
                                  ? Colors.orange.shade900 
                                  : Colors.green.shade900,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(remainingTime.abs()),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isAlert 
                                ? Colors.red.shade900 
                                : isWarning 
                                    ? Colors.orange.shade900 
                                    : Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${trupp.lowestPressure} bar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAlert 
                            ? Colors.red.shade900 
                            : isWarning 
                                ? Colors.orange.shade900 
                                : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pauseTimer(trupp),
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _endTruppEinsatz(trupp),
                        icon: const Icon(Icons.stop),
                        label: const Text('Beenden'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Duration _calculateRemainingTime(AtemschutzTrupp trupp) {
    if (trupp.startTime == null) {
      return Duration.zero;
    }
    
    // Fester 30-Minuten Timer
    final totalDuration = const Duration(minutes: 30);
    
    if (trupp.isActive) {
      // Timer läuft - berechne Zeit seit letztem Start + bereits pausierte Zeit
      final elapsedSinceStart = DateTime.now().difference(trupp.startTime!);
      final totalElapsed = elapsedSinceStart + (trupp.pausedDuration ?? Duration.zero);
      final remaining = totalDuration - totalElapsed;
      return remaining;
    } else {
      // Timer ist pausiert - zeige gefrorene Zeit
      final totalElapsed = trupp.pausedDuration ?? Duration.zero;
      final remaining = totalDuration - totalElapsed;
      return remaining;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showPressureDialog(AtemschutzTrupp trupp) {
    final pressureController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atemschutzüberwachung starten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trupp: ${trupp.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Niedrigster Flaschendruck des Trupps (in bar):'),
              const SizedBox(height: 8),
              TextField(
                controller: pressureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'z.B. 200',
                  suffixText: 'bar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final pressure = int.tryParse(pressureController.text);
                if (pressure != null && pressure > 0) {
                  _startTimer(trupp, pressure);
                  Navigator.pop(context);
                }
              },
              child: const Text('Starten'),
            ),
          ],
        );
      },
    );
  }

  void _startTimer(AtemschutzTrupp trupp, int pressure) {
    setState(() {
      final updatedList = _currentOperation.atemschutzTrupps.map((t) {
        if (t.id == trupp.id) {
          // Erhöhe roundNumber wenn es ein zweiter Durchgang ist
          final newRoundNumber = trupp.isCompleted ? trupp.roundNumber + 1 : trupp.roundNumber;
          
          return t.copyWith(
            startTime: DateTime.now(),
            pausedDuration: Duration.zero,
            lowestPressure: pressure,
            isActive: true,
            isCompleted: false,
            pressure10MinChecked: false,
            pressure20MinChecked: false,
            roundNumber: newRoundNumber,
          );
        }
        return t;
      }).toList();

      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: updatedList,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
    
    // Entferne Alert-Status für zweiten Durchgang
    _alertedTrupps.remove(trupp.id);
    _alertedPressureChecks.remove('${trupp.id}_10');
    _alertedPressureChecks.remove('${trupp.id}_20');
    
    final roundInfo = trupp.isCompleted ? ' (2. Durchgang)' : '';
    _addProtocolEntry('Atemschutzüberwachung für "${trupp.name}" gestartet$roundInfo (${pressure} bar)');
  }

  void _pauseTimer(AtemschutzTrupp trupp) {
    _showPausePressureDialog(trupp);
  }

  void _showPausePressureDialog(AtemschutzTrupp trupp) {
    final pressureController = TextEditingController(
      text: trupp.lowestPressure?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atemschutzüberwachung pausieren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trupp: ${trupp.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Aktueller niedrigster Flaschendruck des Trupps (in bar):'),
              const SizedBox(height: 8),
              TextField(
                controller: pressureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'z.B. 150',
                  suffixText: 'bar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final pressure = int.tryParse(pressureController.text);
                if (pressure == null || pressure <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte einen gültigen Druck eingeben'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Prüfe ob der neue Druck höher ist als der vorherige
                if (trupp.lowestPressure != null && pressure > trupp.lowestPressure!) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Der Druck kann nicht höher sein als der vorherige Wert (${trupp.lowestPressure} bar)'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                _executePauseTimer(trupp, pressure);
                Navigator.pop(context);
              },
              child: const Text('Pausieren'),
            ),
          ],
        );
      },
    );
  }

  void _executePauseTimer(AtemschutzTrupp trupp, int pressure) {
    setState(() {
      // Berechne die bisher verstrichene Zeit
      final elapsedSinceStart = DateTime.now().difference(trupp.startTime!);
      final totalElapsed = elapsedSinceStart + (trupp.pausedDuration ?? Duration.zero);
      
      final updatedList = _currentOperation.atemschutzTrupps.map((t) {
        if (t.id == trupp.id) {
          return t.copyWith(
            pausedDuration: totalElapsed,
            isActive: false,
            lowestPressure: pressure,
          );
        }
        return t;
      }).toList();

      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: updatedList,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
    
    _addProtocolEntry('Atemschutzüberwachung für "${trupp.name}" pausiert ($pressure bar)');
  }

  void _checkPressureIntervals(AtemschutzTrupp trupp, Duration remainingTime) {
    // Berechne vergangene Zeit (30 Minuten - verbleibende Zeit)
    final elapsed = const Duration(minutes: 30) - remainingTime;
    
    // Prüfe ob Zeit abgelaufen ist und spiele Alarm ab
    if (remainingTime.isNegative && !_alertedTrupps.contains(trupp.id)) {
      _alertedTrupps.add(trupp.id);
      _playAlarmSound();
      _addProtocolEntry('ALARM: Atemschutzüberwachungszeit für "${trupp.name}" abgelaufen!');
    }
    
    // Prüfe 10-Minuten-Marke (zwischen 10:00 und 10:05)
    final check10Key = '${trupp.id}_10';
    if (!trupp.pressure10MinChecked && elapsed.inMinutes >= 10 && elapsed.inMinutes < 10.1 && !_alertedPressureChecks.contains(check10Key)) {
      _alertedPressureChecks.add(check10Key);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntervalPressureDialog(trupp, 10);
      });
    }
    
    // Prüfe 20-Minuten-Marke (zwischen 20:00 und 20:05)
    final check20Key = '${trupp.id}_20';
    if (!trupp.pressure20MinChecked && elapsed.inMinutes >= 20 && elapsed.inMinutes < 20.1 && !_alertedPressureChecks.contains(check20Key)) {
      _alertedPressureChecks.add(check20Key);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIntervalPressureDialog(trupp, 20);
      });
    }
  }

  void _showIntervalPressureDialog(AtemschutzTrupp trupp, int minute) {
    // Spiele kurzen Alarmton ab
    _playShortAlertSound();
    
    final pressureController = TextEditingController(
      text: trupp.lowestPressure?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Druckabfrage nach $minute Minuten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trupp: ${trupp.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('Nach $minute Minuten - niedrigster Flaschendruck (in bar):'),
              const SizedBox(height: 8),
              TextField(
                controller: pressureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'z.B. 150',
                  suffixText: 'bar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final pressure = int.tryParse(pressureController.text);
                if (pressure == null || pressure <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte einen gültigen Druck eingeben'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Prüfe ob der neue Druck höher ist als der vorherige
                if (trupp.lowestPressure != null && pressure > trupp.lowestPressure!) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Der Druck kann nicht höher sein als der vorherige Wert (${trupp.lowestPressure} bar)'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                _updatePressureAtInterval(trupp, pressure, minute);
                Navigator.pop(context);
              },
              child: const Text('Bestätigen'),
            ),
          ],
        );
      },
    );
  }

  void _updatePressureAtInterval(AtemschutzTrupp trupp, int pressure, int minute) {
    setState(() {
      final updatedList = _currentOperation.atemschutzTrupps.map((t) {
        if (t.id == trupp.id) {
          return t.copyWith(
            lowestPressure: pressure,
            pressure10MinChecked: minute == 10 ? true : t.pressure10MinChecked,
            pressure20MinChecked: minute == 20 ? true : t.pressure20MinChecked,
          );
        }
        return t;
      }).toList();

      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: updatedList,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
    
    _addProtocolEntry('Druckabfrage "${trupp.name}" nach $minute Min: ${pressure} bar');
  }

  Future<void> _playAlarmSound() async {
    try {
      // Spiele einen Alarm-Beep mehrmals ab
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      // Falls kein Sound-File vorhanden, verwende System-Beep als Fallback
      // Spiele einen synthetischen Ton durch mehrfaches abspielen
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        // Nutze Vibration als Alternative (erfordert vibration package)
      }
    }
  }

  Future<void> _playShortAlertSound() async {
    try {
      // Spiele einen kurzen Alarm-Ton für Druckabfragen ab
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      // Falls kein Sound-File vorhanden, spiele kurzen Beep als Fallback
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _showResumePressureDialog(AtemschutzTrupp trupp) {
    final pressureController = TextEditingController(
      text: trupp.lowestPressure?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atemschutzüberwachung fortsetzen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trupp: ${trupp.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Aktueller niedrigster Flaschendruck des Trupps (in bar):'),
              const SizedBox(height: 8),
              TextField(
                controller: pressureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'z.B. 180',
                  suffixText: 'bar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final pressure = int.tryParse(pressureController.text);
                if (pressure == null || pressure <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte einen gültigen Druck eingeben'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Prüfe ob der neue Druck höher ist als der vorherige
                if (trupp.lowestPressure != null && pressure > trupp.lowestPressure!) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Der Druck kann nicht höher sein als der vorherige Wert (${trupp.lowestPressure} bar)'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                _resumeTimer(trupp, pressure);
                Navigator.pop(context);
              },
              child: const Text('Fortsetzen'),
            ),
          ],
        );
      },
    );
  }

  void _resumeTimer(AtemschutzTrupp trupp, int pressure) {
    setState(() {
      final updatedList = _currentOperation.atemschutzTrupps.map((t) {
        if (t.id == trupp.id) {
          return t.copyWith(
            startTime: DateTime.now(),
            lowestPressure: pressure,
            isActive: true,
          );
        }
        return t;
      }).toList();

      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: updatedList,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
    
    _addProtocolEntry('Atemschutzüberwachung für "${trupp.name}" fortgesetzt (${pressure} bar)');
  }

  void _endTruppEinsatz(AtemschutzTrupp trupp) {
    _showEndPressureDialog(trupp);
  }

  void _showEndPressureDialog(AtemschutzTrupp trupp) {
    final pressureController = TextEditingController(
      text: trupp.lowestPressure?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atemschutzeinsatz beenden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trupp: ${trupp.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Niedrigster Flaschendruck des Trupps (in bar):'),
              const SizedBox(height: 8),
              TextField(
                controller: pressureController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'z.B. 50',
                  suffixText: 'bar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final pressure = int.tryParse(pressureController.text);
                if (pressure == null || pressure <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte einen gültigen Druck eingeben'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Prüfe ob der neue Druck höher ist als der vorherige
                if (trupp.lowestPressure != null && pressure > trupp.lowestPressure!) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Der Druck kann nicht höher sein als der vorherige Wert (${trupp.lowestPressure} bar)'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                _executeEndTruppEinsatz(trupp, pressure);
                Navigator.pop(context);
              },
              child: const Text('Beenden'),
            ),
          ],
        );
      },
    );
  }

  void _executeEndTruppEinsatz(AtemschutzTrupp trupp, int pressure) {
    setState(() {
      final updatedList = _currentOperation.atemschutzTrupps.map((t) {
        if (t.id == trupp.id) {
          return t.copyWith(
            isActive: false,
            isCompleted: true,
            lowestPressure: pressure,
          );
        }
        return t;
      }).toList();

      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: updatedList,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
    
    _addProtocolEntry('Atemschutzeinsatz für "${trupp.name}" beendet ($pressure bar)');
  }

  void _showAddVehicleDialog() {
    bool isExternal = false;
    final vehicleNotifier = context.read<VehicleNotifier>();
    final externalVehicleController = TextEditingController();
    
    // Filtere Fahrzeuge, die noch nicht im Einsatz sind
    final availableVehicles = vehicleNotifier.vehicleList
        .where((v) => !_currentOperation.vehicleIds.contains(v.id))
        .toList();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Fahrzeug hinzufügen'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Eigene Fahrzeuge'),
                          icon: Icon(Icons.local_fire_department),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Andere Wehr'),
                          icon: Icon(Icons.groups),
                        ),
                      ],
                      selected: {isExternal},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          isExternal = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!isExternal) ...[
                      if (availableVehicles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Alle Fahrzeuge sind bereits im Einsatz',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableVehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = availableVehicles[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.local_fire_department),
                                  title: Text(vehicle.funkrufname),
                                  subtitle: Text(vehicle.fahrzeugklasse),
                                  onTap: () {
                                    _addVehicleToOperation(vehicle.id);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ] else ...[
                      const Text('Funkrufname des externen Fahrzeugs:'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: externalVehicleController,
                        decoration: const InputDecoration(
                          hintText: 'z.B. Florian Nachbarstadt 11/1',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                if (isExternal)
                  ElevatedButton(
                    onPressed: () {
                      final funkrufname = externalVehicleController.text.trim();
                      if (funkrufname.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bitte einen Funkrufnamen eingeben'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      _addExternalVehicle(funkrufname);
                      Navigator.pop(context);
                    },
                    child: const Text('Hinzufügen'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _addVehicleToOperation(String vehicleId) {
    setState(() {
      final updatedVehicleIds = List<String>.from(_currentOperation.vehicleIds)
        ..add(vehicleId);
      
      final vehicleNotifier = context.read<VehicleNotifier>();
      final vehicle = vehicleNotifier.vehicleList.firstWhere((v) => v.id == vehicleId);
      
      final updatedVehicleNames = List<String>.from(_currentOperation.vehicleNames)
        ..add(vehicle.funkrufname);
      
      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: updatedVehicleIds,
        vehicleNames: updatedVehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: _currentOperation.atemschutzTrupps,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
    
    final vehicleNotifier = context.read<VehicleNotifier>();
    final vehicle = vehicleNotifier.vehicleList.firstWhere((v) => v.id == vehicleId);
    _addProtocolEntry('Fahrzeug "${vehicle.funkrufname}" zum Einsatz hinzugefügt');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${vehicle.funkrufname} wurde hinzugefügt'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addExternalVehicle(String funkrufname) {
    setState(() {
      final updatedExternalVehicles = List<String>.from(_currentOperation.externalVehicles)
        ..add(funkrufname);
      
      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: _currentOperation.atemschutzTrupps,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: updatedExternalVehicles,
      );
    });
    
    _addProtocolEntry('Externes Fahrzeug "$funkrufname" zum Einsatz hinzugefügt');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$funkrufname wurde hinzugefügt'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeVehicle(String vehicleId) {
    final vehicleNotifier = context.read<VehicleNotifier>();
    final vehicle = vehicleNotifier.vehicleList.firstWhere((v) => v.id == vehicleId);
    
    // Prüfe ob es Atemschutztrupps für dieses Fahrzeug gibt
    final hasTrupps = _currentOperation.atemschutzTrupps
        .any((trupp) => trupp.vehicleId == vehicleId);
    
    if (hasTrupps) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fahrzeug kann nicht entfernt werden, da noch Atemschutztrupps zugewiesen sind'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fahrzeug entfernen'),
          content: Text(
            'Möchten Sie "${vehicle.funkrufname}" wirklich vom Einsatz entfernen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final updatedVehicleIds = List<String>.from(_currentOperation.vehicleIds)
                    ..remove(vehicleId);
                  
                  final vehicleIndex = _currentOperation.vehicleIds.indexOf(vehicleId);
                  final updatedVehicleNames = List<String>.from(_currentOperation.vehicleNames);
                  if (vehicleIndex >= 0 && vehicleIndex < updatedVehicleNames.length) {
                    updatedVehicleNames.removeAt(vehicleIndex);
                  }
                  
                  final updatedAssignment = Map<String, Map<String, String>>.from(
                    _currentOperation.vehiclePersonnelAssignment,
                  )..remove(vehicleId);
                  
                  _currentOperation = Operation(
                    id: _currentOperation.id,
                    alarmstichwort: _currentOperation.alarmstichwort,
                    adresseOrGps: _currentOperation.adresseOrGps,
                    vehicleIds: updatedVehicleIds,
                    vehicleNames: updatedVehicleNames,
                    vehiclePersonnelAssignment: updatedAssignment,
                    einsatzTime: _currentOperation.einsatzTime,
                    protocol: _currentOperation.protocol,
                    respiratoryActive: _currentOperation.respiratoryActive,
                    atemschutzTrupps: _currentOperation.atemschutzTrupps,
                    vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
                    externalVehicles: _currentOperation.externalVehicles,
                  );
                });
                
                _addProtocolEntry('Fahrzeug "${vehicle.funkrufname}" vom Einsatz entfernt');
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${vehicle.funkrufname} wurde entfernt'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Entfernen'),
            ),
          ],
        );
      },
    );
  }

  void _removeExternalVehicle(String funkrufname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Externes Fahrzeug entfernen'),
          content: Text(
            'Möchten Sie "$funkrufname" wirklich vom Einsatz entfernen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final updatedExternalVehicles = List<String>.from(_currentOperation.externalVehicles)
                    ..remove(funkrufname);
                  
                  _currentOperation = Operation(
                    id: _currentOperation.id,
                    alarmstichwort: _currentOperation.alarmstichwort,
                    adresseOrGps: _currentOperation.adresseOrGps,
                    vehicleIds: _currentOperation.vehicleIds,
                    vehicleNames: _currentOperation.vehicleNames,
                    vehiclePersonnelAssignment: _currentOperation.vehiclePersonnelAssignment,
                    einsatzTime: _currentOperation.einsatzTime,
                    protocol: _currentOperation.protocol,
                    respiratoryActive: _currentOperation.respiratoryActive,
                    atemschutzTrupps: _currentOperation.atemschutzTrupps,
                    vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
                    externalVehicles: updatedExternalVehicles,
                  );
                });
                
                _addProtocolEntry('Externes Fahrzeug "$funkrufname" vom Einsatz entfernt');
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$funkrufname wurde entfernt'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Entfernen'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPersonnelDialog(String vehicleId, String vehicleName) {
    final personnelNotifier = context.read<PersonnelNotifier>();
    final vehicleNotifier = context.read<VehicleNotifier>();
    final vehicle = vehicleNotifier.vehicleList.firstWhere((v) => v.id == vehicleId);
    
    final currentAssignment = Map<String, String>.from(
      _currentOperation.vehiclePersonnelAssignment[vehicleId] ?? {},
    );
    
    // Invertiere die Zuordnung: position -> personelId
    final Map<String, String> positionToPersonnel = {};
    currentAssignment.forEach((personelId, position) {
      positionToPersonnel[position] = personelId;
    });
    
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
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Besatzung: $vehicleName'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal den Positionen zuweisen:',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 16),
                      ...allPositions.map((position) {
                        return _buildPositionEditBox(
                          position,
                          vehicleId,
                          positionToPersonnel,
                          personnelNotifier,
                          setState,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Konvertiere zurück: personelId -> position
                    final newAssignment = <String, String>{};
                    positionToPersonnel.forEach((pos, personelId) {
                      newAssignment[personelId] = pos;
                    });
                    _updateVehiclePersonnel(vehicleId, vehicleName, newAssignment);
                    Navigator.pop(context);
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPositionEditBox(
    String position,
    String vehicleId,
    Map<String, String> positionToPersonnel,
    PersonnelNotifier personnelNotifier,
    StateSetter setState,
  ) {
    final currentPersonelId = positionToPersonnel[position];
    final currentPerson = currentPersonelId != null
        ? personnelNotifier.personnelList.firstWhere(
            (p) => p.id == currentPersonelId,
            orElse: () => PersonalData(
              id: 'unknown',
              name: 'Unbekannt',
              email: '',
              phone: '',
              position: '',
              dienstgrad: '',
              lehrgaenge: [],
            ),
          )
        : null;

    // Sammle alle bereits zugewiesenen Personen-IDs über ALLE Fahrzeuge im Einsatz
    final allAssignedPersonIds = <String>{};
    _currentOperation.vehiclePersonnelAssignment.forEach((vId, assignment) {
      // assignment ist Map<String, String> mit personId -> position
      allAssignedPersonIds.addAll(assignment.keys);
    });
    
    // Füge auch die lokalen Änderungen im aktuellen Dialog hinzu (positionToPersonnel)
    // um zu verhindern, dass die gleiche Person mehrfach im selben Fahrzeug zugewiesen wird
    allAssignedPersonIds.addAll(positionToPersonnel.values);
    
    // Nur Personen anzeigen, die noch keine Position haben (in keinem Fahrzeug)
    // AUSSER die Person, die aktuell auf dieser Position ist
    final availablePersonnel = personnelNotifier.personnelList.where((person) {
      // Person ist verfügbar wenn sie nirgendwo zugewiesen ist ODER wenn sie auf dieser Position ist
      return !allAssignedPersonIds.contains(person.id) || person.id == currentPersonelId;
    }).toList();

    // Verwende leeren String statt null für "keine Zuweisung"
    final dropdownValue = currentPersonelId ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: currentPerson != null
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          width: currentPerson != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  position,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (currentPerson != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      positionToPersonnel.remove(position);
                    });
                  },
                  tooltip: 'Entfernen',
                  color: Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: dropdownValue,
            decoration: InputDecoration(
              hintText: 'Person auswählen',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('-- Keine Zuweisung --'),
              ),
              ...availablePersonnel.map((person) {
                return DropdownMenuItem<String>(
                  value: person.id,
                  child: Text('${person.name} (${person.dienstgrad})'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                if (value == null || value.isEmpty) {
                  positionToPersonnel.remove(position);
                } else {
                  positionToPersonnel[position] = value;
                }
              });
            },
          ),
          if (currentPerson != null && currentPerson.id != 'unknown') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
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

  void _updateVehiclePersonnel(
    String vehicleId,
    String vehicleName,
    Map<String, String> newAssignment,
  ) {
    this.setState(() {
      final updatedAssignment = Map<String, Map<String, String>>.from(
        _currentOperation.vehiclePersonnelAssignment,
      );
      
      if (newAssignment.isEmpty) {
        updatedAssignment.remove(vehicleId);
      } else {
        updatedAssignment[vehicleId] = newAssignment;
      }
      
      _currentOperation = Operation(
        id: _currentOperation.id,
        alarmstichwort: _currentOperation.alarmstichwort,
        adresseOrGps: _currentOperation.adresseOrGps,
        vehicleIds: _currentOperation.vehicleIds,
        vehicleNames: _currentOperation.vehicleNames,
        vehiclePersonnelAssignment: updatedAssignment,
        einsatzTime: _currentOperation.einsatzTime,
        protocol: _currentOperation.protocol,
        respiratoryActive: _currentOperation.respiratoryActive,
        atemschutzTrupps: _currentOperation.atemschutzTrupps,
        vehicleBreathingApparatus: _currentOperation.vehicleBreathingApparatus,
        externalVehicles: _currentOperation.externalVehicles,
      );
    });
    
    _addProtocolEntry('Besatzung von "$vehicleName" aktualisiert');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Besatzung von $vehicleName wurde aktualisiert'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _startSecondRound(AtemschutzTrupp trupp) {
    // Zeige Druckabfrage für zweiten Durchgang
    _showPressureDialog(trupp);
  }
}

// Dialog-Widget für Sprachaufnahme
class _VoiceRecordingDialog extends StatefulWidget {
  final AudioRecorderService audioRecorderService;
  final Function(String) onRecordingSaved;

  const _VoiceRecordingDialog({
    required this.audioRecorderService,
    required this.onRecordingSaved,
  });

  @override
  State<_VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<_VoiceRecordingDialog> {
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() async {
    try {
      await widget.audioRecorderService.startRecording();
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      
      // Timer für Aufnahmedauer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Starten der Aufnahme: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _stopRecording() async {
    _timer?.cancel();
    final audioPath = await widget.audioRecorderService.stopRecording();
    
    if (audioPath != null && mounted) {
      widget.onRecordingSaved(audioPath);
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Speichern der Aufnahme'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    await widget.audioRecorderService.cancelRecording();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sprachnotiz aufnehmen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording) ...[
            Icon(
              Icons.fiber_manual_record,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _formatDuration(_recordingSeconds),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Aufnahme läuft...'),
          ] else ...[
            const Icon(
              Icons.mic,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('Bereit zum Aufnehmen'),
          ],
        ],
      ),
      actions: [
        if (!_isRecording) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Aufnahme starten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: _cancelRecording,
            child: const Text('Verwerfen'),
          ),
          ElevatedButton.icon(
            onPressed: _stopRecording,
            icon: const Icon(Icons.stop),
            label: const Text('Speichern'),
          ),
        ],
      ],
    );
  }
}
