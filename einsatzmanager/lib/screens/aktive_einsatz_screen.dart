import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/einsatz_neu.dart';
import '../services/einsatz_service_neu.dart';
import 'einsatz_tabs/daten_tab.dart';
import 'einsatz_tabs/fahrzeuge_tab.dart';
import 'einsatz_tabs/agt_tab.dart';

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

  @override
  void initState() {
    super.initState();
    _currentEinsatz = widget.einsatz;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
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
          AgtTab(einsatz: _currentEinsatz),

          // Tab 4: Verlauf
          _buildVerlaufTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _endEinsatz,
        backgroundColor: Colors.green,
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget _buildVerlaufTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerlaufItem(
              'Einsatz erstellt',
              DateFormat('dd.MM.yyyy HH:mm:ss').format(_currentEinsatz.erstelltAm),
              Icons.create,
            ),
            _buildVerlaufItem(
              'Einsatzart: ${_currentEinsatz.einsatzart}',
              '',
              Icons.assignment,
            ),
            _buildVerlaufItem(
              'Adresse: ${_currentEinsatz.adresse}',
              '',
              Icons.location_on,
            ),
            _buildVerlaufItem(
              'Fahrzeuge eingeplant',
              '${_currentEinsatz.fahrzeuge.length} Fahrzeug(e)',
              Icons.fire_truck,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerlaufItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: Colors.red[900]),
          title: Text(title),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        ),
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
              context.read<EinsatzService>().updateEinsatz(_currentEinsatz);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Einsatz beendet und gespeichert')),
              );
            },
            child: const Text('Beenden', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
