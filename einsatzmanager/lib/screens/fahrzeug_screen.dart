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
  bool _atemschutzEnabled = false;

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

              // Atemschutz Einsatz Toggle
              Card(
                color: _atemschutzEnabled ? Colors.green[50] : Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Atemschutzeinsatz',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _atemschutzEnabled
                                ? 'Aktiviert - Truppführer werden benötigt'
                                : 'Deaktiviert',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _atemschutzEnabled,
                        onChanged: (value) {
                          setState(() {
                            _atemschutzEnabled = value;
                          });
                        },
                      ),
                    ],
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

              // Atemschutz Truppen Übersicht
              if (_atemschutzEnabled) ...[
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Atemschutzeinsatz - Truppführer',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAtemschutzOverview(),
                const SizedBox(height: 24),
              ],

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
      // Wenn Atemschutz aktiv ist, nur Truppführer anzeigen
      if (_atemschutzEnabled) {
        if (position != TruppPosition.angriffstruppfuehrer &&
            position != TruppPosition.wassertrupp_fuehrer) {
          return const SizedBox.shrink();
        }
      }

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

  Widget _buildAtemschutzOverview() {
    final angriffstruppFuehrer =
        _controllers[TruppPosition.angriffstruppfuehrer]?.text ?? '';
    final wassertruippFuehrer =
        _controllers[TruppPosition.wassertrupp_fuehrer]?.text ?? '';

    return Column(
      children: [
        if (angriffstruppFuehrer.isNotEmpty)
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue[900]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Angriffstrupp',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          angriffstruppFuehrer,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.red[50],
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[900]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Angriffstrupp Führer erforderlich',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (wassertruippFuehrer.isNotEmpty)
          Card(
            color: Colors.cyan[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.cyan[900]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wassertrupp',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          wassertruippFuehrer,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.red[50],
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[900]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wassertrupp Führer erforderlich',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _saveFahrzeugDaten() {
    // Bei Atemschutz: Nur Truppführer sind erforderlich
    if (_atemschutzEnabled) {
      final angriffstruppFuehrer =
          _controllers[TruppPosition.angriffstruppfuehrer]?.text ?? '';
      final wassertruippFuehrer =
          _controllers[TruppPosition.wassertrupp_fuehrer]?.text ?? '';

      if (angriffstruppFuehrer.isEmpty || wassertruippFuehrer.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beide Truppführer sind erforderlich'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

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
      atemschutzEinsatz: _atemschutzEnabled,
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
