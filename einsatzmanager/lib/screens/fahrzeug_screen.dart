import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/einsatz_neu.dart';
import '../services/einsatz_service_neu.dart';
import 'aktive_einsatz_screen.dart';

class FahrzeugScreen extends StatefulWidget {
  final Einsatz einsatz;

  const FahrzeugScreen({super.key, required this.einsatz});

  @override
  State<FahrzeugScreen> createState() => _FahrzeugScreenState();
}

class _FahrzeugScreenState extends State<FahrzeugScreen> {
  late Fahrzeug _fahrzeug;
  final Map<TruppPosition, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _fahrzeug = Fahrzeug(
      id: '1',
      name: 'LF20',
    );

    // Controller für alle Positionen initialisieren
    for (var position in TruppPosition.values) {
      _controllers[position] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fahrzeug & Besatzung'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fahrzeugname
              const Text(
                'Fahrzeug',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.red[50],
                ),
                child: Text(
                  'LF20',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Positionen
              const Text(
                'Besatzung zuweisen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._buildPositionFields(),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Zurück'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveFahrzeugDaten,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                      ),
                      child: const Text(
                        'Einsatz starten',
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

  List<Widget> _buildPositionFields() {
    return TruppPosition.values.map((position) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _controllers[position],
          decoration: InputDecoration(
            labelText: position.label,
            hintText: 'Name eingeben',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(Icons.person, color: Colors.red[900]),
          ),
        ),
      );
    }).toList();
  }

  void _saveFahrzeugDaten() {
    // Besatzung sammeln
    final besatzung = <Besatzung>[];
    for (var position in TruppPosition.values) {
      final name = _controllers[position]?.text ?? '';
      if (name.isNotEmpty) {
        besatzung.add(Besatzung(
          position: position,
          personName: name,
        ));
      }
    }

    final fahrzeug = _fahrzeug.copyWith(
      besatzung: besatzung,
      atemschutzEinsatz: false,
    );

    final updatedEinsatz = widget.einsatz.copyWith(
      fahrzeuge: [fahrzeug],
    );

    // Speichere den Einsatz
    context.read<EinsatzService>().addEinsatz(updatedEinsatz);

    // Navigiere zum aktiven Einsatz-Screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AktiveEinsatzScreen(einsatz: updatedEinsatz),
      ),
    );
  }
}
