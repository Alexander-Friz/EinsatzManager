import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/einsatz_neu.dart';
import '../services/einsatz_service_neu.dart';
import 'einsatz_tabs/daten_tab.dart';
import 'einsatz_tabs/fahrzeuge_tab.dart';
import 'einsatz_tabs/agt_tab.dart';
import 'einsatz_tabs/verlauf_tab.dart';

class AktiveEinsatzScreen extends StatefulWidget {
  final Einsatz einsatz;

  const AktiveEinsatzScreen({super.key, required this.einsatz});

  @override
  State<AktiveEinsatzScreen> createState() => _AktiveEinsatzScreenState();
}

class _AktiveEinsatzScreenState extends State<AktiveEinsatzScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Einsatz _currentEinsatz;
  
  // AGT-State persistent halten
  late Map<String, dynamic> _agtState;

  @override
  void initState() {
    super.initState();
    _currentEinsatz = widget.einsatz;
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialisiere AGT-State mit korrekten Types
    _agtState = {
      'fahrzeugAtemschutz': <String, bool>{},
      'truppTimers': <String, dynamic>{},
    };
    
    // Initialisiere Atemschutz-Status
    final atemschutzMap = _agtState['fahrzeugAtemschutz'] as Map<String, bool>;
    for (var fahrzeug in _currentEinsatz.fahrzeuge) {
      atemschutzMap[fahrzeug.id] = fahrzeug.atemschutzEinsatz;
    }
    
    // Höre auf EinsatzService Updates
    context.read<EinsatzService>().addListener(_onEinsatzServiceChanged);
  }
  
  void _onEinsatzServiceChanged() {
    // Wenn der Einsatz im Service aktualisiert wurde, aktualisiere lokale Referenz
    final einsatzService = context.read<EinsatzService>();
    final updatedEinsatz = einsatzService.getEinsatzById(_currentEinsatz.id);
    if (updatedEinsatz != null && mounted) {
      setState(() {
        _currentEinsatz = updatedEinsatz;
      });
    }
  }

  @override
  void dispose() {
    // Cleanup Listener
    context.read<EinsatzService>().removeListener(_onEinsatzServiceChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Aktiver Einsatz', style: TextStyle(fontSize: 16)),
            Text(
              _currentEinsatz.einsatzart,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Daten'),
            Tab(icon: Icon(Icons.fire_truck), text: 'Fahrzeuge'),
            Tab(icon: Icon(Icons.warning), text: 'AGT'),
            Tab(icon: Icon(Icons.history), text: 'Verlauf'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Daten/Info
          DatenTab(einsatz: _currentEinsatz),

          // Tab 2: Fahrzeuge
          FahrzeugeTab(
            einsatz: _currentEinsatz,
            onEinsatzChanged: (updatedEinsatz) {
              setState(() {
                _currentEinsatz = updatedEinsatz;
              });
            },
          ),

          // Tab 3: AGT (Atemschutzeinsatz)
          AgtTab(
            key: const PageStorageKey('agt_tab'),
            einsatz: _currentEinsatz,
            agtState: _agtState,
          ),

          // Tab 4: Verlauf
          VerlaufTab(einsatz: _currentEinsatz),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _endEinsatz,
        backgroundColor: Colors.green,
        child: const Icon(Icons.check),
      ),
    );
  }

  void _endEinsatz() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Einsatz beenden?'),
        content: const Text('Wirklich den Einsatz beenden und die Daten speichern?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              // Speichere die aktuelle Einsatz-Version
              context.read<EinsatzService>().updateEinsatz(_currentEinsatz);
              
              // Zeige Bestätigungsmeldung
              Navigator.pop(context); // Schließe Dialog
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Einsatz beendet und gespeichert ✓'),
                  duration: Duration(seconds: 3),
                  backgroundColor: Colors.green,
                ),
              );
              
              // Navigiere zur Startseite (springe alle Screens über)
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Beenden', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
