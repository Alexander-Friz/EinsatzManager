import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import '../providers/archive_notifier.dart';
import '../models/operation.dart' show Operation, ProtocolEntry;

final logger = Logger();

class PastOperationsScreen extends StatefulWidget {
  const PastOperationsScreen({super.key});

  @override
  State<PastOperationsScreen> createState() => _PastOperationsScreenState();
}

class _PastOperationsScreenState extends State<PastOperationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ArchiveNotifier>().loadArchivedOperations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vergangene Einsätze'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ArchiveNotifier>(
        builder: (context, archiveNotifier, child) {
          if (!archiveNotifier.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final operationsList = archiveNotifier.archivedOperations;

          return operationsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text('Keine archivierten Einsätze vorhanden'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: operationsList.length,
                  itemBuilder: (context, index) {
                    final operation = operationsList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.archive,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(operation.alarmstichwort),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adresse/GPS: ${operation.adresseOrGps}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Datum: ${operation.einsatzTime.day}.${operation.einsatzTime.month}.${operation.einsatzTime.year} ${operation.einsatzTime.hour}:${operation.einsatzTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Fahrzeuge: ${operation.vehicleIds.length}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteOperation(context, operation, index);
                            } else if (value == 'details') {
                              _showOperationDetails(context, operation);
                            } else if (value == 'protocol') {
                              _showOperationProtocol(context, operation);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'details',
                              child: Text('Details anzeigen'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'protocol',
                              child: Text('Protokoll anzeigen'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Löschen'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  void _deleteOperation(
      BuildContext context, Operation operation, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Einsatz löschen'),
          content: Text(
            'Möchten Sie den Einsatz "${operation.alarmstichwort}" wirklich löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<ArchiveNotifier>().deleteArchivedOperation(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Einsatz gelöscht'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }

  void _showOperationDetails(BuildContext context, Operation operation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Einsatzdetails'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Alarmstichwort:', operation.alarmstichwort),
                const SizedBox(height: 12),
                _buildDetailRow('Adresse/GPS:', operation.adresseOrGps),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Datum und Uhrzeit:',
                  '${operation.einsatzTime.day}.${operation.einsatzTime.month}.${operation.einsatzTime.year} ${operation.einsatzTime.hour}:${operation.einsatzTime.minute.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Anzahl Fahrzeuge:',
                  '${operation.vehicleIds.length}',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Eingesetzte Fahrzeuge:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (var vehicleName in operation.vehicleNames)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                    child: Text('• $vehicleName'),
                  ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  void _showOperationProtocol(BuildContext context, Operation operation) {
    try {
      if (operation.protocol.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Protokolleinträge vorhanden'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Einsatzprotokoll'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${operation.alarmstichwort} - ${operation.einsatzTime.day}.${operation.einsatzTime.month}.${operation.einsatzTime.year}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < operation.protocol.length; i++)
                                _buildProtocolEntry(context, operation.protocol[i], i),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      logger.e('Fehler beim Anzeigen des Protokolls: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden des Protokolls: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildProtocolEntry(BuildContext context, ProtocolEntry entry, int index) {
    try {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${entry.timestamp.day}.${entry.timestamp.month}.${entry.timestamp.year} ${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (entry.imageBase64 != null && entry.imageBase64!.isNotEmpty)
                _buildImagePreview(entry.imageBase64!),
            ],
          ),
        ),
      );
    } catch (e) {
      logger.e('Fehler beim Rendern von Protokoll-Eintrag $index: $e');
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fehler bei Eintrag #$index'),
              const SizedBox(height: 6),
              Text('Fehler: $e', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildImagePreview(String imageBase64) {
    try {
      final imageBytes = base64Decode(imageBase64);
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            height: 250,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 250,
                width: double.infinity,
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
        ),
      );
    } catch (e) {
      logger.e('Fehler beim Decodieren des Bildes: $e');
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(height: 8),
              Text('Fehler beim Bild: Base64 Decodierung'),
            ],
          ),
        ),
      );
    }
  }
}
