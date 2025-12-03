import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/einsatz_documentation.dart';
import '../services/dokumentation_service.dart';

const uuid = Uuid();

class DokumentationScreen extends StatefulWidget {
  const DokumentationScreen({super.key});

  @override
  State<DokumentationScreen> createState() => _DokumentationScreenState();
}

class _DokumentationScreenState extends State<DokumentationScreen> {
  late TextEditingController _einsatzNameController;
  late TextEditingController _einsatzortController;
  late TextEditingController _einsatzleiterController;
  late TextEditingController _anzahlPersonalController;
  late TextEditingController _fahrzeugeController;
  late TextEditingController _massnahmenController;
  late TextEditingController _besonderheitenController;

  GefahrenabwehrStufe _selectedStufe = GefahrenabwehrStufe.eins;
  EinsatzErgebnis _selectedErgebnis = EinsatzErgebnis.erfolgreich;
  final List<String> _fahrzeugliste = [];

  @override
  void initState() {
    super.initState();
    _einsatzNameController = TextEditingController();
    _einsatzortController = TextEditingController();
    _einsatzleiterController = TextEditingController();
    _anzahlPersonalController = TextEditingController();
    _fahrzeugeController = TextEditingController();
    _massnahmenController = TextEditingController();
    _besonderheitenController = TextEditingController();
  }

  @override
  void dispose() {
    _einsatzNameController.dispose();
    _einsatzortController.dispose();
    _einsatzleiterController.dispose();
    _anzahlPersonalController.dispose();
    _fahrzeugeController.dispose();
    _massnahmenController.dispose();
    _besonderheitenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatz Dokumentieren'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Einsatzname
              _buildSection(
                title: 'Einsatzname *',
                child: TextField(
                  controller: _einsatzNameController,
                  decoration: InputDecoration(
                    hintText: 'z.B. Wohnhausbrand Hauptstraße',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gefahrenabwehrstufe
              _buildSection(
                title: 'Gefahrenabwehrstufe *',
                child: DropdownButtonFormField<GefahrenabwehrStufe>(
                  initialValue: _selectedStufe,
                  decoration: InputDecoration(
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: GefahrenabwehrStufe.values
                      .map((stufe) => DropdownMenuItem(
                            value: stufe,
                            child: Text(stufe.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStufe = value ?? GefahrenabwehrStufe.eins;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Einsatzort
              _buildSection(
                title: 'Einsatzort *',
                child: TextField(
                  controller: _einsatzortController,
                  decoration: InputDecoration(
                    hintText: 'Straße, Hausnummer, Stadt',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 20),

              // Einsatzleiter
              _buildSection(
                title: 'Einsatzleiter *',
                child: TextField(
                  controller: _einsatzleiterController,
                  decoration: InputDecoration(
                    hintText: 'Name des Einsatzleiters',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Anzahl Personal
              _buildSection(
                title: 'Anzahl eingesetztes Personal *',
                child: TextField(
                  controller: _anzahlPersonalController,
                  decoration: InputDecoration(
                    hintText: 'z.B. 15',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 20),

              // Fahrzeuge
              _buildSection(
                title: 'Eingesetzte Fahrzeuge',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fahrzeugeController,
                            decoration: InputDecoration(
                              hintText: 'z.B. Löschfahrzeug 1',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_fahrzeugeController.text.isNotEmpty) {
                              setState(() {
                                _fahrzeugliste.add(_fahrzeugeController.text);
                                _fahrzeugeController.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Hinzufügen'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_fahrzeugliste.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _fahrzeugliste.map((fahrzeug) {
                          return Chip(
                            label: Text(fahrzeug),
                            onDeleted: () {
                              setState(() {
                                _fahrzeugliste.remove(fahrzeug);
                              });
                            },
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        'Keine Fahrzeuge hinzugefügt',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Massnahmen
              _buildSection(
                title: 'Durchgeführte Maßnahmen *',
                child: TextField(
                  controller: _massnahmenController,
                  decoration: InputDecoration(
                    hintText: 'Beschreibung der Maßnahmen...',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 4,
                ),
              ),
              const SizedBox(height: 20),

              // Ergebnis
              _buildSection(
                title: 'Einsatzergebnis *',
                child: DropdownButtonFormField<EinsatzErgebnis>(
                  initialValue: _selectedErgebnis,
                  decoration: InputDecoration(
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: EinsatzErgebnis.values
                      .map((ergebnis) => DropdownMenuItem(
                            value: ergebnis,
                            child: Text(ergebnis.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedErgebnis = value ?? EinsatzErgebnis.erfolgreich;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Besonderheiten
              _buildSection(
                title: 'Besonderheiten / Anmerkungen',
                child: TextField(
                  controller: _besonderheitenController,
                  decoration: InputDecoration(
                    hintText: 'Besondere Vorkommnisse, Verletzungen, etc.',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 4,
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
                      onPressed: _saveDokumentation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                      ),
                      child: const Text(
                        'Dokumentation speichern',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _saveDokumentation() {
    // Validierung
    if (_einsatzNameController.text.isEmpty ||
        _einsatzortController.text.isEmpty ||
        _einsatzleiterController.text.isEmpty ||
        _anzahlPersonalController.text.isEmpty ||
        _massnahmenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füllen Sie alle Pflichtfelder (*) aus'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final anzahl = int.tryParse(_anzahlPersonalController.text);
    if (anzahl == null || anzahl < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte geben Sie eine gültige Anzahl ein'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final documentation = EinsatzDokumentation(
      id: uuid.v4(),
      einsatzId: uuid.v4(), // In Zukunft: echte Einsatz-ID
      einsatzName: _einsatzNameController.text,
      gefahrenabwehrStufe: _selectedStufe,
      einsatzort: _einsatzortController.text,
      einsatzleiter: _einsatzleiterController.text,
      anzahlPersonal: anzahl,
      eingesetzteFahrzeuge: _fahrzeugliste,
      massnahmen: _massnahmenController.text,
      ergebnis: _selectedErgebnis,
      besonderheiten: _besonderheitenController.text,
      dokumentiertAm: DateTime.now(),
    );

    context.read<DokumentationService>().addDokumentation(documentation);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dokumentation erfolgreich gespeichert'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }
}
