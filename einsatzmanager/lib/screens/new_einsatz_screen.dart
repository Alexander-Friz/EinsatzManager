import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/einsatz.dart';
import '../services/einsatz_service.dart';

const uuid = Uuid();

class NewEinsatzScreen extends StatefulWidget {
  const NewEinsatzScreen({super.key});

  @override
  State<NewEinsatzScreen> createState() => _NewEinsatzScreenState();
}

class _NewEinsatzScreenState extends State<NewEinsatzScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _commanderController;

  EinsatzType _selectedType = EinsatzType.fire;
  EinsatzPriority _selectedPriority = EinsatzPriority.high;
  EinsatzStatus _selectedStatus = EinsatzStatus.pending;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _commanderController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _commanderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neuer Einsatz'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel
              const Text(
                'Einsatztitel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'z.B. Wohnhausbrand',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),

              // Typ
              const Text(
                'Einsatztyp',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EinsatzType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: EinsatzType.values
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? EinsatzType.fire;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Priorität
              const Text(
                'Priorität',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EinsatzPriority>(
                initialValue: _selectedPriority,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: EinsatzPriority.values
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value ?? EinsatzPriority.high;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Status
              const Text(
                'Initialstatus',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EinsatzStatus>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [EinsatzStatus.pending, EinsatzStatus.active]
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? EinsatzStatus.pending;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Adresse
              const Text(
                'Adresse',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  hintText: 'z.B. Hauptstraße 123, 12345 Musterstadt',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Beschreibung
              const Text(
                'Beschreibung',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Detaillierte Beschreibung des Einsatzes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              // Einsatzleiter
              const Text(
                'Einsatzleiter (optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commanderController,
                decoration: InputDecoration(
                  hintText: 'Name des Einsatzleiters',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createEinsatz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Einsatz erstellen',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createEinsatz() {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füllen Sie alle Pflichtfelder aus'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final newEinsatz = Einsatz(
      id: uuid.v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      type: _selectedType,
      status: _selectedStatus,
      priority: _selectedPriority,
      address: _addressController.text,
      createdAt: DateTime.now(),
      commanderName: _commanderController.text.isEmpty ? null : _commanderController.text,
      startedAt: _selectedStatus == EinsatzStatus.active ? DateTime.now() : null,
    );

    context.read<EinsatzService>().addEinsatz(newEinsatz);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Einsatz erstellt'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }
}
