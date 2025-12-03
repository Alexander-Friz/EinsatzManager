import 'package:flutter/material.dart';
import 'dart:async';
import '../models/einsatz_neu.dart';

class AtemschutzScreen extends StatefulWidget {
  final Einsatz einsatz;
  final Fahrzeug fahrzeug;

  const AtemschutzScreen({
    super.key,
    required this.einsatz,
    required this.fahrzeug,
  });

  @override
  State<AtemschutzScreen> createState() => _AtemschutzScreenState();
}

class _AtemschutzScreenState extends State<AtemschutzScreen> {
  late Timer _timerAngriffstrupp;
  late Timer _timerWassertrupp;

  int _angriffstruppSeconden = 30 * 60; // 30 Minuten in Sekunden
  int _wassertruippSeconden = 30 * 60; // 30 Minuten in Sekunden

  bool _runningAngriffstrupp = false;
  bool _runningWassertrupp = false;

  bool _alarm10MinutenAngriffstrupp = false;
  bool _alarm10MinutenWassertrupp = false;

  @override
  void dispose() {
    _timerAngriffstrupp.cancel();
    _timerWassertrupp.cancel();
    super.dispose();
  }

  void _startAngriffstrupp() {
    if (_runningAngriffstrupp) return;

    setState(() {
      _runningAngriffstrupp = true;
    });

    _timerAngriffstrupp = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _angriffstruppSeconden--;

        // Alarm nach 10 Minuten (20 * 60 Sekunden)
        if (_angriffstruppSeconden == 20 * 60 && !_alarm10MinutenAngriffstrupp) {
          _alarm10MinutenAngriffstrupp = true;
          _playAlarmSound();
        }

        // Alarm bei 0
        if (_angriffstruppSeconden <= 0) {
          _angriffstruppSeconden = 0;
          _runningAngriffstrupp = false;
          _playAlarmSound();
          timer.cancel();
        }
      });
    });
  }

  void _startWassertrupp() {
    if (_runningWassertrupp) return;

    setState(() {
      _runningWassertrupp = true;
    });

    _timerWassertrupp = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _wassertruippSeconden--;

        // Alarm nach 10 Minuten (20 * 60 Sekunden)
        if (_wassertruippSeconden == 20 * 60 && !_alarm10MinutenWassertrupp) {
          _alarm10MinutenWassertrupp = true;
          _playAlarmSound();
        }

        // Alarm bei 0
        if (_wassertruippSeconden <= 0) {
          _wassertruippSeconden = 0;
          _runningWassertrupp = false;
          _playAlarmSound();
          timer.cancel();
        }
      });
    });
  }

  void _stopAngriffstrupp() {
    _timerAngriffstrupp.cancel();
    setState(() {
      _runningAngriffstrupp = false;
    });
  }

  void _stopWassertrupp() {
    _timerWassertrupp.cancel();
    setState(() {
      _runningWassertrupp = false;
    });
  }

  void _resetAngriffstrupp() {
    _timerAngriffstrupp.cancel();
    setState(() {
      _angriffstruppSeconden = 30 * 60;
      _runningAngriffstrupp = false;
      _alarm10MinutenAngriffstrupp = false;
    });
  }

  void _resetWassertrupp() {
    _timerWassertrupp.cancel();
    setState(() {
      _wassertruippSeconden = 30 * 60;
      _runningWassertrupp = false;
      _alarm10MinutenWassertrupp = false;
    });
  }

  void _playAlarmSound() {
    // Placeholder für Sound - kann später mit audio_players implementiert werden
    debugPrint('ALARM!');
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atemschutzeinsatz'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Einsatzinfo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.einsatz.einsatzart,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.einsatz.adresse,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Angriffstrupp
              _buildTruppCard(
                title: 'Angriffstrupp',
                seconds: _angriffstruppSeconden,
                isRunning: _runningAngriffstrupp,
                onStart: _startAngriffstrupp,
                onStop: _stopAngriffstrupp,
                onReset: _resetAngriffstrupp,
                alarm10Minuten: _alarm10MinutenAngriffstrupp,
              ),
              const SizedBox(height: 24),

              // Wassertrupp
              _buildTruppCard(
                title: 'Wassertrupp',
                seconds: _wassertruippSeconden,
                isRunning: _runningWassertrupp,
                onStart: _startWassertrupp,
                onStop: _stopWassertrupp,
                onReset: _resetWassertrupp,
                alarm10Minuten: _alarm10MinutenWassertrupp,
              ),
              const SizedBox(height: 24),

              // Beenden Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _stopAllAndReturn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Einsatz beenden',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTruppCard({
    required String title,
    required int seconds,
    required bool isRunning,
    required VoidCallback onStart,
    required VoidCallback onStop,
    required VoidCallback onReset,
    required bool alarm10Minuten,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: alarm10Minuten ? Colors.orange : Colors.grey[300]!,
          width: alarm10Minuten ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: alarm10Minuten ? Colors.orange[50] : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Timer Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _formatTime(seconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 8),
                if (alarm10Minuten)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Warnung: 10 Minuten vergangen',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                  onPressed: isRunning ? onStop : onStart,
                  icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(isRunning ? 'Stopp' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _stopAllAndReturn() {
    if (_runningAngriffstrupp) _stopAngriffstrupp();
    if (_runningWassertrupp) _stopWassertrupp();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Einsatz beendet'),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
