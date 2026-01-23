import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  final Logger logger = Logger();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Prüft und fordert Mikrofonberechtigung an
  Future<bool> checkAndRequestPermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        logger.w('Mikrofonberechtigung dauerhaft verweigert');
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      logger.e('Fehler beim Prüfen der Mikrofonberechtigung: $e');
      return false;
    }
  }

  /// Startet die Audioaufnahme
  Future<void> startRecording() async {
    try {
      if (_isRecording) {
        logger.w('Aufnahme läuft bereits');
        return;
      }

      // Berechtigung prüfen
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Mikrofonberechtigung nicht erteilt');
      }

      // Prüfe ob Recorder verfügbar ist
      if (!await _recorder.hasPermission()) {
        throw Exception('Keine Berechtigung für Audioaufnahme');
      }

      // Temporären Pfad für die Aufnahme erstellen
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/voice_note_$timestamp.m4a';

      // Konfiguration für die Aufnahme
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: path);
      _isRecording = true;
      logger.i('Aufnahme gestartet: $path');
    } catch (e) {
      logger.e('Fehler beim Starten der Aufnahme: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Stoppt die Aufnahme und gibt den Pfad zur Datei zurück
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        logger.w('Keine laufende Aufnahme');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path != null) {
        // Datei in den dauerhaften Speicher verschieben
        final permanentPath = await _moveToAppDirectory(path);
        logger.i('Aufnahme gestoppt und gespeichert: $permanentPath');
        return permanentPath;
      }

      return null;
    } catch (e) {
      logger.e('Fehler beim Stoppen der Aufnahme: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Bricht die aktuelle Aufnahme ab
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        logger.i('Aufnahme abgebrochen');
      }
    } catch (e) {
      logger.e('Fehler beim Abbrechen der Aufnahme: $e');
      _isRecording = false;
    }
  }

  /// Verschiebt die temporäre Datei in das App-Verzeichnis
  Future<String> _moveToAppDirectory(String tempPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${appDir.path}/audio');

      // Erstelle Audio-Ordner falls nicht vorhanden
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final fileName = tempPath.split('/').last;
      final newPath = '${audioDir.path}/$fileName';

      final tempFile = File(tempPath);
      await tempFile.copy(newPath);
      await tempFile.delete(); // Temp-Datei löschen

      return newPath;
    } catch (e) {
      logger.e('Fehler beim Verschieben der Audio-Datei: $e');
      return tempPath; // Im Fehlerfall den temp Pfad zurückgeben
    }
  }

  /// Löscht eine Audio-Datei
  Future<void> deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        logger.i('Audio-Datei gelöscht: $path');
      }
    } catch (e) {
      logger.e('Fehler beim Löschen der Audio-Datei: $e');
    }
  }

  /// Gibt Informationen über eine Audio-Datei zurück
  Future<Map<String, dynamic>?> getAudioInfo(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final sizeInBytes = stat.size;
      final sizeInKB = (sizeInBytes / 1024).toStringAsFixed(2);

      return {
        'path': path,
        'size': sizeInKB,
        'sizeUnit': 'KB',
        'modified': stat.modified,
      };
    } catch (e) {
      logger.e('Fehler beim Abrufen der Audio-Informationen: $e');
      return null;
    }
  }

  /// Aufräumen
  void dispose() {
    _recorder.dispose();
  }
}
