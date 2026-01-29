import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataExportService {
  /// Exportiert alle App-Daten als JSON-Datei
  static Future<String?> exportAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Sammle alle Daten
      final Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data': <String, dynamic>{},
      };
      
      // Alle SharedPreferences Daten sammeln
      for (String key in allKeys) {
        final value = prefs.get(key);
        if (value is String) {
          // Versuche zu erkennen, ob es JSON ist
          try {
            final decoded = jsonDecode(value);
            exportData['data'][key] = decoded;
          } catch (e) {
            // Kein JSON, speichere als String
            exportData['data'][key] = value;
          }
        } else {
          exportData['data'][key] = value;
        }
      }
      
      // JSON schön formatieren
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Erstelle Dateinamen mit Zeitstempel
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'einsatzmanager_backup_$timestamp.json';
      
      // Speichere temporär
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      print('Fehler beim Exportieren: $e');
      return null;
    }
  }
  
  /// Teilt die Export-Datei über das System-Share-Dialog
  static Future<bool> shareExportedData(String filePath) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'EinsatzManager Backup',
        text: 'Backup aller EinsatzManager Daten',
      );
      
      return result.status == ShareResultStatus.success;
    } catch (e) {
      print('Fehler beim Teilen: $e');
      return false;
    }
  }
  
  /// Exportiert Daten mit direktem Speichern im Downloads-Ordner
  static Future<bool> exportAllDataWithSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Sammle alle Daten
      final Map<String, dynamic> exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data': <String, dynamic>{},
      };
      
      // Alle SharedPreferences Daten sammeln
      for (String key in allKeys) {
        final value = prefs.get(key);
        if (value is String) {
          // Versuche zu erkennen, ob es JSON ist
          try {
            final decoded = jsonDecode(value);
            exportData['data'][key] = decoded;
          } catch (e) {
            // Kein JSON, speichere als String
            exportData['data'][key] = value;
          }
        } else {
          exportData['data'][key] = value;
        }
      }
      
      // JSON schön formatieren
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Erstelle Dateinamen mit Zeitstempel
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'einsatzmanager_backup_$timestamp.json';
      
      // Versuche Downloads-Ordner zu finden
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Für Android: Verwende externe Speicher mit Downloads
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // Für iOS: Verwende Documents-Verzeichnis
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Für Desktop: Verwende Downloads oder Documents
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        return false;
      }
      
      // Speichere die Datei
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      
      return true;
    } catch (e) {
      print('Fehler beim Exportieren mit Speichern: $e');
      return false;
    }
  }
  
  /// Importiert Daten aus einer JSON-Datei
  static Future<bool> importData() async {
    try {
      // Öffne Dateiauswahl
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result == null || result.files.single.path == null) {
        return false;
      }
      
      // Lese Datei
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> importData = jsonDecode(jsonString);
      
      // Validiere Struktur
      if (!importData.containsKey('data')) {
        throw Exception('Ungültiges Backup-Format');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final data = importData['data'] as Map<String, dynamic>;
      
      // Importiere alle Daten
      for (var entry in data.entries) {
        final key = entry.key;
        final value = entry.value;
        
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is List<String>) {
          await prefs.setStringList(key, value);
        } else {
          // Komplexe Datentypen als JSON-String speichern
          await prefs.setString(key, jsonEncode(value));
        }
      }
      
      return true;
    } catch (e) {
      print('Fehler beim Importieren: $e');
      return false;
    }
  }
  
  /// Löscht alle App-Daten (für Reset-Funktion)
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      print('Fehler beim Löschen: $e');
      return false;
    }
  }
  
  /// Gibt eine Zusammenfassung der gespeicherten Daten zurück
  static Future<Map<String, int>> getDataSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      int operations = 0;
      int personnel = 0;
      int vehicles = 0;
      int equipment = 0;
      int messages = 0;
      
      // Zähle archivierte Operationen
      final archivedOpsString = prefs.getString('archived_operations_list');
      if (archivedOpsString != null) {
        final List<dynamic> list = jsonDecode(archivedOpsString);
        operations = list.length;
      }
      
      // Zähle Personal
      final personnelString = prefs.getString('personnel_list');
      if (personnelString != null) {
        final List<dynamic> list = jsonDecode(personnelString);
        personnel = list.length;
      }
      
      // Zähle Fahrzeuge
      final vehiclesString = prefs.getString('vehicles_list');
      if (vehiclesString != null) {
        final List<dynamic> list = jsonDecode(vehiclesString);
        vehicles = list.length;
      }
      
      // Zähle Ausrüstung
      final equipmentString = prefs.getString('equipment_list');
      if (equipmentString != null) {
        final List<dynamic> list = jsonDecode(equipmentString);
        equipment = list.length;
      }
      
      // Zähle Nachrichten
      final messagesString = prefs.getString('messages_list');
      if (messagesString != null) {
        final List<dynamic> list = jsonDecode(messagesString);
        messages = list.length;
      }
      
      return {
        'operations': operations,
        'personnel': personnel,
        'vehicles': vehicles,
        'equipment': equipment,
        'messages': messages,
      };
    } catch (e) {
      print('Fehler beim Abrufen der Zusammenfassung: $e');
      return {};
    }
  }
}
