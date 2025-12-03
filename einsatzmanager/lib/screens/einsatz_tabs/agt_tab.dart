import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/einsatz_neu.dart';
import '../../services/einsatz_service_neu.dart';

class AgtTab extends StatefulWidget {
  final Einsatz einsatz;

  const AgtTab({super.key, required this.einsatz});

  @override
  State<AgtTab> createState() => _AgtTabState();
}

class _AgtTabState extends State<AgtTab> {
  late Map<String, _TruppTimer> _truppTimers;
  late Map<String, bool> _fahrzeugAtemschutz;

  @override
  void initState() {
    super.initState();
    _truppTimers = {};
    _fahrzeugAtemschutz = {};
    
    // Initialisiere Atemschutz-Status für jedes Fahrzeug
    for (var fahrzeug in widget.einsatz.fahrzeuge) {
      _fahrzeugAtemschutz[fahrzeug.id] = fahrzeug.atemschutzEinsatz;
    }
    
    // Initialisiere Timer für jeden Trupp mit Atemschutz
    for (var fahrzeug in widget.einsatz.fahrzeuge) {
      if (fahrzeug.atemschutzEinsatz) {
        _truppTimers['angriffstrupp_${fahrzeug.id}'] = _TruppTimer(
          name: 'Angriffstrupp (${fahrzeug.name})',
        );
        _truppTimers['wassertrupp_${fahrzeug.id}'] = _TruppTimer(
          name: 'Wassertrupp (${fahrzeug.name})',
        );
      }
    }
  }

  @override
  void dispose() {
    for (var timer in _truppTimers.values) {
      timer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  onChanged: (value) {
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
                  ),
                  const SizedBox(height: 16),
                  _buildTruppCard(
                    timer: _truppTimers['wassertrupp_${fahrzeug.id}']!,
                    fahrzeug: fahrzeug,
                    truppName: 'Wassertrupp',
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
                          if (timer.alarm10Minuten)
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
                                ? () {
                                    setState(() {
                                      timer.stop();
                                    });
                                  }
                                : () {
                                    setState(() {
                                      timer.start();
                                    });
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
    if (timer.alarm10Minuten) return Colors.orange;
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
  bool alarm10Minuten = false;
  late Timer? _timer;
  VoidCallback? onUpdate;

  _TruppTimer({required this.name}) {
    _timer = null;
  }

  void start() {
    if (isRunning) return;
    isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      seconds--;

      // Alarm nach 20 Minuten (10 Minuten verstrichen)
      if (seconds == 20 * 60 && !alarm10Minuten) {
        alarm10Minuten = true;
        _playAlarmSound();
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
    alarm10Minuten = false;
    onUpdate?.call();
  }

  void dispose() {
    _timer?.cancel();
  }

  void _playAlarmSound() {
    // Placeholder für Sound
    debugPrint('ALARM - $name');
  }
}
