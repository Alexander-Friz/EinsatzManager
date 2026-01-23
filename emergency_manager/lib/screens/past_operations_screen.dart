import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../providers/archive_notifier.dart';
import '../models/operation.dart' show Operation;
import 'operation_detail_screen.dart';
import 'operation_edit_screen.dart';

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OperationDetailScreen(
                                    operation: operation,
                                    operationIndex: index,
                                  ),
                            ),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteOperation(context, operation, index);
                            } else if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OperationEditScreen(
                                    operation: operation,
                                    operationIndex: index,
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Abändern'),
                                ],
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18),
                                  SizedBox(width: 8),
                                  Text('Löschen'),
                                ],
                              ),
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
}
