import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../models/einsatz_neu.dart';
import '../../services/einsatz_service_neu.dart';

class AgtTab extends StatefulWidget {
  final Einsatz einsatz;
  final Map<String, dynamic> agtState;

  const AgtTab({
    super.key,
    required this.einsatz,
    required this.agtState,
  });

  @override
  State<AgtTab> createState() => _AgtTabState();
}

class _AgtTabState extends State<AgtTab> with AutomaticKeepAliveClientMixin {
  late Map<String, _TruppTimer> _truppTimers;
  late Map<String, bool> _fahrzeugAtemschutz;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Verwende State vom Parent wenn vorhanden mit korrektem Cast
    final timerMap = widget.agtState['truppTimers'] as Map<String, dynamic>?;
    _truppTimers = {};
    if (timerMap != null) {
      for (var entry in timerMap.entries) {
        if (entry.value is _TruppTimer) {
          _truppTimers[entry.key] = entry.value as _TruppTimer;
        }
      }
    }
    
    final atemschutzMap = widget.agtState['fahrzeugAtemschutz'] as Map<String, bool>?;
    if (atemschutzMap != null) {
      _fahrzeugAtemschutz = atemschutzMap;
    } else {
      _fahrzeugAtemschutz = {};
    }
    
    // Nur initialisieren wenn noch nicht geschehen
    if (_fahrzeugAtemschutz.isEmpty) {
      for (var fahrzeug in widget.einsatz.fahrzeuge) {
        _fahrzeugAtemschutz[fahrzeug.id] = fahrzeug.atemschutzEinsatz;
      }
    }
    
    // Initialisiere Timer für jeden Trupp mit Atemschutz
    if (_truppTimers.isEmpty) {
      for (var fahrzeug in widget.einsatz.fahrzeuge) {
        if (fahrzeug.atemschutzEinsatz) {
          final angriffstruppTimer = _TruppTimer(
            name: 'Angriffstrupp (${fahrzeug.name})',
          );
          angriffstruppTimer.onDruckRequest = (sekunden) => _handleDruckRequest(
            'Druckabfrage - Angriffstrupp ${fahrzeug.name}',
            'angriffstrupp_${fahrzeug.id}',
            sekunden,
          );
          
          final wassertruuppTimer = _TruppTimer(
            name: 'Wassertrupp (${fahrzeug.name})',
          );
          wassertruuppTimer.onDruckRequest = (sekunden) => _handleDruckRequest(
            'Druckabfrage - Wassertrupp ${fahrzeug.name}',
            'wassertrupp_${fahrzeug.id}',
            sekunden,
          );
          
          _truppTimers['angriffstrupp_${fahrzeug.id}'] = angriffstruppTimer;
          _truppTimers['wassertrupp_${fahrzeug.id}'] = wassertruuppTimer;
        }
      }
    }
    
    // Update Parent State
    widget.agtState['truppTimers'] = _truppTimers;
    widget.agtState['fahrzeugAtemschutz'] = _fahrzeugAtemschutz;
  }

  @override
  void dispose() {
    // Nicht hier dispose aufrufen - wird vom Parent gemacht
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atemschutz-Einsätze',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (widget.einsatz.fahrzeuge.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.fire_truck, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Fahrzeuge eingeplant',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...widget.einsatz.fahrzeuge.map((fahrzeug) {
                return _buildFahrzeugAtemschutzCard(context, fahrzeug);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFahrzeugAtemschutzCard(BuildContext context, Fahrzeug fahrzeug) {
    final isAgtActive = _fahrzeugAtemschutz[fahrzeug.id] ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Toggle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isAgtActive ? Colors.green : Colors.grey[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fahrzeug.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isAgtActive ? 'AGT aktiviert' : 'AGT deaktiviert',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isAgtActive,
                  onChanged: _isAnyTimerRunning() ? null : (value) {
                    setState(() {
                      _fahrzeugAtemschutz[fahrzeug.id] = value;
                      
                      if (value) {
                        // Aktiviere Timer
                        _truppTimers['angriffstrupp_${fahrzeug.id}'] = _TruppTimer(
                          name: 'Angriffstrupp (${fahrzeug.name})',
                        );
                        _truppTimers['wassertrupp_${fahrzeug.id}'] = _TruppTimer(
                          name: 'Wassertrupp (${fahrzeug.name})',
                        );
                      } else {
                        // Deaktiviere Timer
                        _truppTimers['angriffstrupp_${fahrzeug.id}']?.dispose();
                        _truppTimers['wassertrupp_${fahrzeug.id}']?.dispose();
                        _truppTimers.remove('angriffstrupp_${fahrzeug.id}');
                        _truppTimers.remove('wassertrupp_${fahrzeug.id}');
                      }
                      
                      // Speichere in Einsatz
                      final updatedFahrzeuge = widget.einsatz.fahrzeuge.map((f) {
                        if (f.id == fahrzeug.id) {
                          return f.copyWith(atemschutzEinsatz: value);
                        }
                        return f;
                      }).toList();
                      
                      final updatedEinsatz = widget.einsatz.copyWith(
                        fahrzeuge: updatedFahrzeuge,
                      );
                      
                      context.read<EinsatzService>().updateEinsatz(updatedEinsatz);
                    });
                  },
                ),
              ],
            ),
          ),

          if (isAgtActive)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTruppCard(
                    timer: _truppTimers['angriffstrupp_${fahrzeug.id}']!,
                    fahrzeug: fahrzeug,
                    truppName: 'Angriffstrupp',
                    timerId: 'angriffstrupp_${fahrzeug.id}',
                  ),
                  const SizedBox(height: 16),
                  _buildTruppCard(
                    timer: _truppTimers['wassertrupp_${fahrzeug.id}']!,
                    fahrzeug: fahrzeug,
                    truppName: 'Wassertrupp',
                    timerId: 'wassertrupp_${fahrzeug.id}',
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aktiviere Atemschutzeinsatz um die Stoppuhren zu nutzen',
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTruppCard({
    required _TruppTimer timer,
    required Fahrzeug fahrzeug,
    required String truppName,
    required String timerId,
  }) {
    // Finde Truppführer und Truppmann basierend auf Truppname
    String? truppFuehrerName;
    String? truppMannName;
    
    if (truppName == 'Angriffstrupp') {
      truppFuehrerName = fahrzeug.besatzung
          .firstWhere(
            (b) => b.position == TruppPosition.angriffstruppfuehrer,
            orElse: () => Besatzung(
              position: TruppPosition.angriffstruppfuehrer,
              personName: 'N/A',
            ),
          )
          .personName;
      truppMannName = fahrzeug.besatzung
          .firstWhere(
            (b) => b.position == TruppPosition.angriffstruppmann,
            orElse: () => Besatzung(
              position: TruppPosition.angriffstruppmann,
              personName: 'N/A',
            ),
          )
          .personName;
    } else if (truppName == 'Wassertrupp') {
      truppFuehrerName = fahrzeug.besatzung
          .firstWhere(
            (b) => b.position == TruppPosition.wassertrupp_fuehrer,
            orElse: () => Besatzung(
              position: TruppPosition.wassertrupp_fuehrer,
              personName: 'N/A',
            ),
          )
          .personName;
      truppMannName = fahrzeug.besatzung
          .firstWhere(
            (b) => b.position == TruppPosition.wassertrupp_mann,
            orElse: () => Besatzung(
              position: TruppPosition.wassertrupp_mann,
              personName: 'N/A',
            ),
          )
          .personName;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        timer.onUpdate = () {
          setState(() {});
        };

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getHeaderColor(timer),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truppName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      fahrzeug.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (truppFuehrerName != null || truppMannName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (truppFuehrerName != null && truppFuehrerName != 'N/A')
                              Text(
                                'Führer: $truppFuehrerName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE8E8E8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (truppMannName != null && truppMannName != 'N/A')
                              Text(
                                'Mann: $truppMannName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFE8E8E8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Timer Display
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(timer.seconds),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontFamily: 'Courier',
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (timer.hasAlarmTriggered)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    '10 Minuten verstrichen!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: timer.isRunning
                                ? () async {
                                    // Druckfrage beim Stop
                                    final druck = await _showDruckDialog(context, 'Enddruck');
                                    if (druck != null && mounted) {
                                      // STOP Eintrag beim Stopp mit Enddruck
                                      _addAtemschutzEintrag(
                                        timerId: timerId,
                                        truppName: timer.name,
                                        ereignis: 'STOP',
                                        druck: druck,
                                      );
                                      setState(() {
                                        timer.stop();
                                      });
                                    }
                                  }
                                : () async {
                                    // Druckfrage beim Start
                                    final druck = await _showDruckDialog(context, 'Startdruck');
                                    if (druck != null && mounted) {
                                      setState(() {
                                        timer.start();
                                      });
                                      // Protokoll-Eintrag hinzufügen
                                      _addAtemschutzEintrag(
                                        timerId: timerId,
                                        truppName: timer.name,
                                        ereignis: 'START',
                                        druck: druck,
                                      );
                                    }
                                  },
                            icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
                            label: Text(timer.isRunning ? 'Stopp' : 'Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  timer.isRunning ? Colors.orange : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                timer.reset();
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getHeaderColor(_TruppTimer timer) {
    if (timer.hasAlarmTriggered) return Colors.orange;
    if (timer.isRunning) return Colors.green;
    return Colors.grey[700]!;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _TruppTimer {
  final String name;
  int seconds = 30 * 60; // 30 Minuten
  bool isRunning = false;
  late Timer? _timer;
  VoidCallback? onUpdate;
  Function(int)? onDruckRequest; // Callback für Druckabfrage
  final Set<int> _triggeredAlarms = {}; // Verhindere doppelte Alarme

  // Getter für Alarm-Status
  bool get hasAlarmTriggered => _triggeredAlarms.isNotEmpty;

  _TruppTimer({required this.name}) {
    _timer = null;
  }

  void start() {
    if (isRunning) return;
    isRunning = true;
    _triggeredAlarms.clear(); // Setze Alarm-Tracker zurück

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;

      // Prüfe auf Alarm nach 10 Minuten (20 Minuten verbleibend = 1200 Sekunden)
      if (seconds == 20 * 60 && !_triggeredAlarms.contains(20 * 60)) {
        _triggeredAlarms.add(20 * 60);
        _playAlarmSound();
        // Triggere die Druckabfrage
        onDruckRequest?.call(seconds);
      }

      // Prüfe auf Alarm nach 20 Minuten (10 Minuten verbleibend = 600 Sekunden)
      if (seconds == 10 * 60 && !_triggeredAlarms.contains(10 * 60)) {
        _triggeredAlarms.add(10 * 60);
        _playAlarmSound();
        // Triggere die Druckabfrage
        onDruckRequest?.call(seconds);
      }

      // Alarm bei 0
      if (seconds <= 0) {
        seconds = 0;
        isRunning = false;
        _playAlarmSound();
        timer.cancel();
      }

      onUpdate?.call();
    });
  }

  void stop() {
    _timer?.cancel();
    isRunning = false;
    onUpdate?.call();
  }

  void reset() {
    _timer?.cancel();
    seconds = 30 * 60;
    isRunning = false;
    _triggeredAlarms.clear();
    onUpdate?.call();
  }

  void dispose() {
    _timer?.cancel();
  }

  void _playAlarmSound() {
    // Spiele System-Sound und Vibration ab
    HapticFeedback.heavyImpact();
    // Wiederhole den Sound mehrfach für Alarm-Effekt
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.mediumImpact();
      });
    }
  }
}

// Hilfsfunktionen für AGT-Tab
extension AgtTabHelper on _AgtTabState {
  Future<int?> _showDruckDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Druck in bar eingeben',
            labelText: 'Druck (bar)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final druck = int.tryParse(controller.text);
              Navigator.pop(context, druck);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTimerFahrzeugId(_TruppTimer timer) {
    // Extrahiere fahrzeugId aus Timer-Keys
    for (var entry in _truppTimers.entries) {
      if (entry.value == timer) {
        return entry.key.replaceAll(RegExp(r'(angriffstrupp|wassertrupp)_'), '');
      }
    }
    return '';
  }

  void _addAtemschutzEintrag({
    required String timerId,
    required String truppName,
    required String ereignis,
    required int? druck,
  }) {
    final fahrzeugId = _getTimerFahrzeugId(_truppTimers[timerId]!);
    final fahrzeug = widget.einsatz.fahrzeuge.firstWhere((f) => f.id == fahrzeugId);
    
    final eintrag = AtemschutzEintrag(
      fahrzeugId: fahrzeugId,
      fahrzeugName: fahrzeug.name,
      truppName: truppName,
      zeitpunkt: DateTime.now(),
      ereignis: ereignis,
      druck: druck,
    );

    final existingProtokoll = widget.einsatz.atemschutzProtokoll ?? [];
    final newProtokoll = [...existingProtokoll, eintrag];
    
    final updatedEinsatz = widget.einsatz.copyWith(
      atemschutzProtokoll: newProtokoll,
    );

    context.read<EinsatzService>().updateEinsatz(updatedEinsatz);
  }

  void _handleDruckRequest(String title, String timerId, int sekunden) async {
    final controller = TextEditingController();
    final druck = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verbleibende Zeit:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  Text(
                    _formatTime(sekunden),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'z.B. 28',
                labelText: 'Druck (bar)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final druck = int.tryParse(controller.text);
              Navigator.pop(context, druck);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (druck != null && mounted) {
      _addAtemschutzEintrag(
        timerId: timerId,
        truppName: _getTruppName(timerId),
        ereignis: 'DRUCKABFRAGE',
        druck: druck,
      );
    }
  }

  String _getTruppName(String timerId) {
    return _truppTimers[timerId]?.name ?? 'Unbekannt';
  }

  bool _isAnyTimerRunning() {
    return _truppTimers.values.any((timer) => timer.isRunning);
  }
}
