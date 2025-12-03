import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/einsatz.dart';
import '../services/einsatz_service.dart';

class EinsatzDetailScreen extends StatefulWidget {
  final Einsatz einsatz;

  const EinsatzDetailScreen({super.key, required this.einsatz});

  @override
  State<EinsatzDetailScreen> createState() => _EinsatzDetailScreenState();
}

class _EinsatzDetailScreenState extends State<EinsatzDetailScreen> {
  late TextEditingController _notesController;
  late TextEditingController _personnelController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.einsatz.notes ?? '');
    _personnelController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _personnelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatzdetails'),
        elevation: 0,
      ),
      body: Consumer<EinsatzService>(
        builder: (context, service, _) {
          final currentEinsatz = service.getEinsatzById(widget.einsatz.id) ?? widget.einsatz;
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header mit Status
                Container(
                  width: double.infinity,
                  color: Colors.red[900],
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentEinsatz.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(currentEinsatz.type.label),
                            backgroundColor: Colors.white10,
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(currentEinsatz.status.label),
                            backgroundColor: _getStatusColor(currentEinsatz.status),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(currentEinsatz.priority.label),
                            backgroundColor: _getPriorityColor(currentEinsatz.priority),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status ändern
                      _buildStatusSection(context, service, currentEinsatz),
                      const SizedBox(height: 24),

                      // Grundinformationen
                      _buildInfoSection(currentEinsatz),
                      const SizedBox(height: 24),

                      // Personal
                      _buildPersonnelSection(context, service, currentEinsatz),
                      const SizedBox(height: 24),

                      // Notizen
                      _buildNotesSection(context, service, currentEinsatz),
                      const SizedBox(height: 24),

                      // Aktionsbuttons
                      _buildActionButtons(context, service, currentEinsatz),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, EinsatzService service, Einsatz einsatz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status aktualisieren',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: EinsatzStatus.values.map((status) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: einsatz.status == status
                    ? _getStatusColor(status)
                    : Colors.grey[300],
              ),
              onPressed: einsatz.status != status
                  ? () {
                      service.updateStatus(einsatz.id, status);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status zu ${status.label} geändert'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: Text(
                status.label,
                style: TextStyle(
                  color: einsatz.status == status ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoSection(Einsatz einsatz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Einsatzdetails',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Typ:', einsatz.type.label),
                const SizedBox(height: 12),
                _buildInfoRow('Priorität:', einsatz.priority.label),
                const SizedBox(height: 12),
                _buildInfoRow('Adresse:', einsatz.address),
                const SizedBox(height: 12),
                _buildInfoRow('Erstellt:', einsatz.formattedCreatedAt),
                if (einsatz.commanderName != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Einsatzleiter:', einsatz.commanderName ?? 'Nicht zugewiesen'),
                ],
                if (einsatz.status == EinsatzStatus.completed) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Dauer:', einsatz.duration),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Beschreibung:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800]),
        ),
        const SizedBox(height: 4),
        Text(
          einsatz.description,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildPersonnelSection(BuildContext context, EinsatzService service, Einsatz einsatz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zugewiesenes Personal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (einsatz.assignedPersonnel.isEmpty)
          Text(
            'Kein Personal zugewiesen',
            style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
          )
        else
          Column(
            children: einsatz.assignedPersonnel.map((person) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(person),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => service.removePersonnel(einsatz.id, person),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _personnelController,
                decoration: InputDecoration(
                  hintText: 'Name des Personals',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                if (_personnelController.text.isNotEmpty) {
                  service.assignPersonnel(einsatz.id, _personnelController.text);
                  _personnelController.clear();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Hinzufügen'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context, EinsatzService service, Einsatz einsatz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notizen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Einsatznotizen hinzufügen...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            service.updateEinsatz(einsatz.copyWith(notes: value));
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, EinsatzService service, Einsatz einsatz) {
    return Column(
      children: [
        if (einsatz.status != EinsatzStatus.completed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                service.updateStatus(einsatz.id, EinsatzStatus.completed);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Einsatz abgeschlossen')),
                );
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.check),
              label: const Text('Einsatz abschließen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Einsatz löschen?'),
                  content: const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                    TextButton(
                      onPressed: () {
                        service.deleteEinsatz(einsatz.id);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('Löschen', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete),
            label: const Text('Löschen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(EinsatzStatus status) {
    switch (status) {
      case EinsatzStatus.active:
        return Colors.red;
      case EinsatzStatus.pending:
        return Colors.orange;
      case EinsatzStatus.completed:
        return Colors.green;
      case EinsatzStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(EinsatzPriority priority) {
    switch (priority) {
      case EinsatzPriority.high:
        return Colors.red;
      case EinsatzPriority.medium:
        return Colors.orange;
      case EinsatzPriority.low:
        return Colors.green;
    }
  }
}
