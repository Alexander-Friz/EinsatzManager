import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../models/operation.dart';
import '../providers/personnel_notifier.dart';
import '../providers/vehicle_notifier.dart';
import '../services/pdf_service.dart';
import 'operation_edit_screen.dart';

final logger = Logger();

class OperationDetailScreen extends StatefulWidget {
  final Operation operation;
  final int operationIndex;

  const OperationDetailScreen({
    super.key,
    required this.operation,
    required this.operationIndex,
  });

  @override
  State<OperationDetailScreen> createState() => _OperationDetailScreenState();
}

class _OperationDetailScreenState extends State<OperationDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPlayingPath;
  
  // Standardpositionen für Feuerwehrfahrzeuge
  static const List<String> standardPositions = [
    'Gruppenführer',
    'Maschinist',
    'Angriffstrupp',
    'Wassertrupp',
    'Schlauchtrupp',
    'Melder',
  ];

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzdetails'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.operation.protocol.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _exportProtocolToPdf(),
              tooltip: 'Als PDF exportieren',
              color: Colors.purple,
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OperationEditScreen(
                    operation: widget.operation,
                    operationIndex: widget.operationIndex,
                  ),
                ),
              );
            },
            tooltip: 'Bearbeiten',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card mit Hauptinformationen
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.operation.alarmstichwort,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.location_on,
                      'Adresse/GPS',
                      widget.operation.adresseOrGps,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.access_time,
                      'Datum & Uhrzeit',
                      _formatDateTime(widget.operation.einsatzTime),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fahrzeuge Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eingesetzte Fahrzeuge (${widget.operation.vehicleIds.length + widget.operation.externalVehicles.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.operation.vehicleNames.isEmpty && widget.operation.externalVehicles.isEmpty)
                      const Text('Keine Fahrzeuge eingesetzt')
                    else ...[
                      // Eigene Fahrzeuge
                      ...widget.operation.vehicleNames.map((vehicleName) {
                        final vehicleId = widget.operation.vehicleIds[
                            widget.operation.vehicleNames.indexOf(vehicleName)];
                        return _buildVehicleItem(vehicleId, vehicleName);
                      }),
                      // Externe Fahrzeuge
                      ...widget.operation.externalVehicles.map((externalVehicle) {
                        return _buildExternalVehicleItem(externalVehicle);
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Personal Section
            if (widget.operation.vehiclePersonnelAssignment.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Personalzuteilung',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.operation.vehiclePersonnelAssignment.entries.map(
                        (entry) {
                          final vehicleIndex =
                              widget.operation.vehicleIds.indexOf(entry.key);
                          final vehicleName = vehicleIndex >= 0 &&
                                  vehicleIndex < widget.operation.vehicleNames.length
                              ? widget.operation.vehicleNames[vehicleIndex]
                              : entry.key;
                          return _buildPersonnelByVehicle(vehicleName, entry.value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Atemschutz Section
            if (widget.operation.atemschutzTrupps.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.masks,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Atemschutztrupps (${widget.operation.atemschutzTrupps.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.operation.atemschutzTrupps.map(
                        (trupp) => _buildAtemschutzTrupp(trupp),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Protokoll Section
            if (widget.operation.protocol.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Einsatzprotokoll (${widget.operation.protocol.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.operation.protocol
                          .asMap()
                          .entries
                          .map((entry) => _buildProtocolEntry(entry.value, entry.key)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleItem(String vehicleId, String vehicleName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fire_truck,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              vehicleName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalVehicleItem(String vehicleName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.groups,
            color: Theme.of(context).colorScheme.tertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Externes Fahrzeug',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.tertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonnelByVehicle(
      String vehicleName, Map<String, String> personnel) {
    if (personnel.isEmpty) return const SizedBox.shrink();

    // Personnel Map umkehren: von {personId: position} zu {position: personName}
    final personnelNotifier = context.read<PersonnelNotifier>();
    final Map<String, String> positionToPersonMap = {};
    
    // Durchlaufe alle Personen im Fahrzeug
    for (var entry in personnel.entries) {
      final personId = entry.key;
      final position = entry.value;
      
      // Finde den Namen der Person
      final person = personnelNotifier.personnelList
          .firstWhere((p) => p.id == personId, orElse: () => PersonalData(
                id: personId,
                name: 'Unbekannt',
                email: '',
                phone: '',
                position: '',
                dienstgrad: '',
                lehrgaenge: [],
              ));
      
      positionToPersonMap[position] = person.name;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Icon(
                Icons.fire_truck,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                vehicleName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          // Zeige alle Standardpositionen an
          ...standardPositions.map((position) {
            final personName = positionToPersonMap[position] ?? '-';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    personName != '-' ? Icons.person : Icons.person_outline,
                    size: 16,
                    color: personName != '-' 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        children: [
                          TextSpan(
                            text: '$position: ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: personName,
                            style: TextStyle(
                              color: personName != '-'
                                  ? Theme.of(context).textTheme.bodyMedium?.color
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          // Zeige zusätzliche Positionen an, die nicht in den Standardpositionen sind
          ...positionToPersonMap.entries
              .where((entry) => !standardPositions.contains(entry.key))
              .map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        children: [
                          TextSpan(
                            text: '${entry.key}: ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: entry.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAtemschutzTrupp(AtemschutzTrupp trupp) {
    // Hole Personennamen und Fahrzeugnamen
    final personnelNotifier = context.read<PersonnelNotifier>();
    final vehicleNotifier = context.read<VehicleNotifier>();
    
    // Finde Person 1
    final person1 = personnelNotifier.personnelList.firstWhere(
      (p) => p.id == trupp.person1Id,
      orElse: () => PersonalData(
        id: trupp.person1Id,
        name: 'Unbekannt',
        email: '',
        phone: '',
        position: '',
        dienstgrad: '',
        lehrgaenge: [],
      ),
    );
    
    // Finde Person 2
    final person2 = personnelNotifier.personnelList.firstWhere(
      (p) => p.id == trupp.person2Id,
      orElse: () => PersonalData(
        id: trupp.person2Id,
        name: 'Unbekannt',
        email: '',
        phone: '',
        position: '',
        dienstgrad: '',
        lehrgaenge: [],
      ),
    );
    
    // Finde Fahrzeug (falls vorhanden)
    String? vehicleName;
    if (trupp.vehicleId != null) {
      try {
        final vehicle = vehicleNotifier.vehicleList.firstWhere(
          (v) => v.id == trupp.vehicleId,
        );
        vehicleName = vehicle.funkrufname;
      } catch (e) {
        // Fahrzeug nicht gefunden
        vehicleName = null;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: trupp.isCompleted
              ? Colors.green.withValues(alpha: 0.5)
              : trupp.isActive
                  ? Colors.orange.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trupp.isCompleted
                    ? Icons.check_circle
                    : trupp.isActive
                        ? Icons.play_circle
                        : Icons.circle_outlined,
                color: trupp.isCompleted
                    ? Colors.green
                    : trupp.isActive
                        ? Colors.orange
                        : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trupp.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trupp.roundNumber > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Durchgang ${trupp.roundNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Zeige Fahrzeug an (falls vorhanden)
          if (vehicleName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.fire_truck,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fahrzeug: $vehicleName',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Zeige AGT-Träger an
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AGT 1: ${person1.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AGT 2: ${person2.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (trupp.startTime != null)
            Text(
              'Start: ${_formatDateTime(trupp.startTime!)}',
              style: const TextStyle(fontSize: 12),
            ),
          if (trupp.startPressure != null)
            Text(
              'Startdruck: ${trupp.startPressure} bar',
              style: const TextStyle(fontSize: 12),
            ),
          if (trupp.lowestPressure != null)
            Text(
              'Niedrigster Druck: ${trupp.lowestPressure} bar',
              style: const TextStyle(fontSize: 12),
            ),
          if (trupp.startTime != null && trupp.endTime != null)
            Builder(
              builder: (context) {
                final totalDuration = trupp.endTime!.difference(trupp.startTime!);
                final pausedSeconds = trupp.pausedDuration?.inSeconds ?? 0;
                final einsatzSeconds = totalDuration.inSeconds - pausedSeconds;
                final minutes = einsatzSeconds ~/ 60;
                final seconds = einsatzSeconds % 60;
                return Text(
                  'Einsatzzeit: $minutes:${seconds.toString().padLeft(2, '0')} Min',
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProtocolEntry(ProtocolEntry entry, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(entry.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry.imageBase64 != null && entry.imageBase64!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildImagePreview(entry.imageBase64!),
            ),
          if (entry.audioPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildAudioPlayer(entry.audioPath!),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String imageBase64) {
    try {
      final imageBytes = base64Decode(imageBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 40),
                  SizedBox(height: 8),
                  Text('Bild konnte nicht geladen werden'),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      logger.e('Fehler beim Decodieren des Bildes: $e');
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(height: 8),
            Text('Fehler beim Laden des Bildes'),
          ],
        ),
      );
    }
  }

  Widget _buildAudioPlayer(String audioPath) {
    final isThisPlaying = _isPlaying && _currentPlayingPath == audioPath;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.audiotrack,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Sprachnotiz'),
          ),
          IconButton(
            icon: Icon(isThisPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () => _toggleAudioPlayback(audioPath),
            tooltip: isThisPlaying ? 'Pausieren' : 'Abspielen',
          ),
        ],
      ),
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
      logger.e('Fehler beim Abspielen der Sprachnotiz: $e');
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

  Future<void> _exportProtocolToPdf() async {
    try {
      final personnelNotifier = context.read<PersonnelNotifier>();
      
      await PdfService.generateOperationProtocolPdf(
        alarmstichwort: widget.operation.alarmstichwort,
        adresse: widget.operation.adresseOrGps,
        einsatzTime: widget.operation.einsatzTime,
        vehicleNames: widget.operation.vehicleNames,
        protocol: widget.operation.protocol,
        vehiclePersonnelAssignment: widget.operation.vehiclePersonnelAssignment,
        personnelList: personnelNotifier.personnelList,
        atemschutzTrupps: widget.operation.atemschutzTrupps,
        externalVehicles: widget.operation.externalVehicles,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
