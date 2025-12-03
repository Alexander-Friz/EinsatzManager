import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/einsatz_neu.dart';
import '../services/gps_service.dart';
import 'fahrzeug_screen.dart';

const uuid = Uuid();

class EinsatzErstellenScreen extends StatefulWidget {
  const EinsatzErstellenScreen({super.key});

  @override
  State<EinsatzErstellenScreen> createState() => _EinsatzErstellenScreenState();
}

class _EinsatzErstellenScreenState extends State<EinsatzErstellenScreen> {
  late TextEditingController _einsatzartController;
  late TextEditingController _adresseController;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _gefiltert = [];
  String? _selectedEinsatzart;
  
  double? _latitude;
  double? _longitude;
  bool _loadingGps = false;
  final GpsService _gpsService = GpsService();

  @override
  void initState() {
    super.initState();
    _einsatzartController = TextEditingController();
    _adresseController = TextEditingController();
  }

  @override
  void dispose() {
    _einsatzartController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  void _filterEinsatzarten(String query) {
    setState(() {
      if (query.isEmpty) {
        _gefiltert = [];
      } else {
        _gefiltert = vordefinierteEinsatzarten
            .where((art) => art.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einsatz erstellen'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Einsatzart mit Autocomplete
              const Text(
                'Einsatzart *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _einsatzartController,
                decoration: InputDecoration(
                  hintText: 'Einsatzart eingeben oder auswählen...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: _selectedEinsatzart != null
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                ),
                onChanged: (value) {
                  _filterEinsatzarten(value);
                  _selectedEinsatzart = null;
                },
              ),
              const SizedBox(height: 8),
              if (_gefiltert.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _gefiltert.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_gefiltert[index]),
                        onTap: () {
                          setState(() {
                            _selectedEinsatzart = _gefiltert[index];
                            _einsatzartController.text = _gefiltert[index];
                            _gefiltert = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // Datum (fest)
              const Text(
                'Datum',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.red[900]),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd.MM.yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Uhrzeit (fest vom System)
              const Text(
                'Uhrzeit',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.red[900]),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Adresse (GPS)
              const Text(
                'Adresse (GPS) *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _adresseController,
                decoration: InputDecoration(
                  hintText: 'Adresse eingeben oder GPS nutzen...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  suffixIcon: _loadingGps
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.red[900]),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.my_location,
                            color: _latitude != null ? Colors.green : Colors.red[900],
                          ),
                          onPressed: _loadingGps ? null : _getGPSAdresse,
                          tooltip: _latitude != null
                              ? 'GPS: Erfolgreich ermittelt'
                              : 'GPS-Position ermitteln',
                        ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _latitude != null ? Icons.check_circle : Icons.info,
                    size: 16,
                    color: _latitude != null ? Colors.green : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _latitude != null
                          ? 'GPS: Koordinaten ermittelt (${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)})'
                          : 'Hinweis: GPS wird bei Bedarf automatisch ermittelt',
                      style: TextStyle(
                        fontSize: 12,
                        color: _latitude != null ? Colors.green : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
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
                      onPressed: _saveBasisDaten,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                      ),
                      child: const Text(
                        'Weiter zu Fahrzeugen',
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

  void _getGPSAdresse() async {
    setState(() {
      _loadingGps = true;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS-Position wird ermittelt...'),
          duration: Duration(seconds: 3),
        ),
      );

      final position = await _gpsService.getCurrentPosition();

      if (mounted) {
        if (position != null) {
          setState(() {
            _latitude = position.latitude;
            _longitude = position.longitude;
            _adresseController.text =
                '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            _loadingGps = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Position ermittelt: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _loadingGps = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Fehler: Position konnte nicht ermittelt werden.\nBitte überprüfen Sie die GPS-Berechtigungen in den App-Einstellungen.',
              ),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingGps = false;
        });

        debugPrint('GPS Error in UI: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim GPS-Abruf: $e',
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveBasisDaten() {
    if (_selectedEinsatzart == null || _adresseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte füllen Sie alle Felder aus'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final einsatz = Einsatz(
      id: uuid.v4(),
      einsatzart: _selectedEinsatzart!,
      datum: _selectedDate,
      uhrzeit: _selectedTime,
      adresse: _adresseController.text,
      latitude: _latitude,
      longitude: _longitude,
      erstelltAm: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FahrzeugScreen(einsatz: einsatz),
      ),
    );
  }
}
