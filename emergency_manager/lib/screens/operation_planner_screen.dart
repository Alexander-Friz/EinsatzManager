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
                              vehicle.funkrufname,
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
          child: Column(
            children: [
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
                            selectedPerson1Id = null;
                            selectedPerson2Id = null;
                            
                            // Automatisch die Besatzung des Fahrzeugs setzen
                            if (value != null && _currentOperation.vehiclePersonnelAssignment.containsKey(value)) {
                              final assignedPersonnel = _currentOperation.vehiclePersonnelAssignment[value]!;
                              final personnelIds = assignedPersonnel.keys.toList();
                              
                              // Setze die ersten zwei Personen automatisch
                              if (personnelIds.isNotEmpty) {
                                selectedPerson1Id = personnelIds[0];
                              }
                              if (personnelIds.length > 1) {
                                selectedPerson2Id = personnelIds[1];
                              }
                            }
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
                            _currentOperation.atemschutzTrupps.forEach((atTrupp) {
                              // Nur Trupps für dieses spezifische Fahrzeug berücksichtigen
                              if (atTrupp.vehicleId == selectedVehicleId) {
                                usedTrupps.add(atTrupp.name);
                              }
                            });
                            
                            final availableTrupps = vehicle.trupps
                                .where((t) => !usedTrupps.contains(t))
                                .toList();

                            if (availableTrupps.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Alle Trupps dieses Fahrzeugs sind bereits angelegt',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              value: selectedTrupp,
                              hint: const Text('Trupp wählen'),
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
      // Bei Fahrzeugbezug: nur Fahrzeug und Trupp erforderlich
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
        // Mit Fahrzeugbezug - hole Personen automatisch aus der Fahrzeugbesatzung
        String? person1Id;
        String? person2Id;
        
        if (_currentOperation.vehiclePersonnelAssignment.containsKey(selectedVehicleId)) {
          final assignedPersonnel = _currentOperation.vehiclePersonnelAssignment[selectedVehicleId]!;
          final personnelIds = assignedPersonnel.keys.toList();
          
          if (personnelIds.length >= 2) {
            person1Id = personnelIds[0];
            person2Id = personnelIds[1];
            
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
              person1Id: person1Id,
              person2Id: person2Id,
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
      );
    });
    
    _addProtocolEntry('Atemschutzeinsatz für "${trupp.name}" beendet ($pressure bar)');
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
