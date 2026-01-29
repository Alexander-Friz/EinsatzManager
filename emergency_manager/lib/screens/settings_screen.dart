import 'package:flutter/material.dart';
import '../providers/theme_notifier.dart';
import '../providers/archive_notifier.dart';
import '../providers/personnel_notifier.dart';
import '../providers/vehicle_notifier.dart';
import '../providers/equipment_notifier.dart';
import '../providers/message_notifier.dart';
import '../services/data_export_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _developerOptionsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDeveloperOptions();
    // Überprüfe den Schedule beim Laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ThemeNotifier>().updateScheduleIfNeeded();
      }
    });
  }

  Future<void> _loadDeveloperOptions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _developerOptionsEnabled = prefs.getBool('developer_options_enabled') ?? false;
    });
  }

  Future<void> _saveDeveloperOptions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('developer_options_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 50,
      ),
      body: ListView(
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Sprache',
            subtitle: 'Deutsch',
            onTap: () {
              _showComingSoon(context, 'Sprache');
            },
          ),
          _buildSwitchTile(
            context,
            icon: Icons.brightness_6,
            title: 'Dark Mode',
            subtitle: 'Automatischer Wechsel',
          ),
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              if (!themeNotifier.isAutoScheduleEnabled) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  _buildTimePickerTile(
                    context,
                    icon: Icons.schedule,
                    title: 'Startzeit Dark Mode',
                    time: themeNotifier.darkModeStartHour,
                    minute: themeNotifier.darkModeStartMinute,
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: themeNotifier.darkModeStartHour,
                          minute: themeNotifier.darkModeStartMinute,
                        ),
                      );
                      if (picked != null && context.mounted) {
                        context.read<ThemeNotifier>().setDarkModeStartTime(picked.hour, picked.minute);
                      }
                    },
                  ),
                  _buildTimePickerTile(
                    context,
                    icon: Icons.schedule,
                    title: 'Endzeit Dark Mode',
                    time: themeNotifier.darkModeEndHour,
                    minute: themeNotifier.darkModeEndMinute,
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: themeNotifier.darkModeEndHour,
                          minute: themeNotifier.darkModeEndMinute,
                        ),
                      );
                      if (picked != null && context.mounted) {
                        context.read<ThemeNotifier>().setDarkModeEndTime(picked.hour, picked.minute);
                      }
                    },
                  ),
                ],
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info,
            title: 'Über die App',
            subtitle: 'Version 1.0.0',
            onTap: () {
              _showComingSoon(context, 'Über die App');
            },
          ),
          const Divider(height: 32),
          // Entwickleroptionen Switch
          _buildSwitchTile(
            context,
            icon: Icons.developer_mode,
            title: 'Entwickleroptionen',
            subtitle: 'Erweiterte Funktionen aktivieren',
            value: _developerOptionsEnabled,
            onChanged: (value) {
              setState(() {
                _developerOptionsEnabled = value;
              });
              _saveDeveloperOptions(value);
            },
          ),
          // Daten-Management Sektion (nur wenn Entwickleroptionen aktiviert)
          if (_developerOptionsEnabled) ...[
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Datenverwaltung',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.upload_file,
              title: 'Daten exportieren',
              subtitle: 'Backup aller Daten erstellen',
              onTap: _isExporting ? () {} : () => _showExportOptions(),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.download,
              title: 'Daten importieren',
              subtitle: 'Backup wiederherstellen',
              onTap: _isImporting ? () {} : () => _importData(),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.delete_forever,
              title: 'Alle Daten löschen',
              subtitle: 'App zurücksetzen (mit Vorsicht!)',
              onTap: () => _showDeleteConfirmation(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showExportOptions() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daten exportieren'),
        content: const Text('Wie möchten Sie die Daten exportieren?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'save'),
            icon: const Icon(Icons.save),
            label: const Text('Speichern unter'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'share'),
            icon: const Icon(Icons.share),
            label: const Text('Teilen'),
          ),
        ],
      ),
    );
    
    if (choice == 'save') {
      await _exportDataWithSave();
    } else if (choice == 'share') {
      await _exportData();
    }
  }

  Future<void> _exportDataWithSave() async {
    setState(() => _isExporting = true);
    
    try {
      // Zeige Zusammenfassung vor dem Export
      final summary = await DataExportService.getDataSummary();
      if (!mounted) return;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daten exportieren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Folgende Daten werden exportiert:'),
              const SizedBox(height: 16),
              _buildSummaryRow('Einsätze', summary['operations'] ?? 0),
              _buildSummaryRow('Personal', summary['personnel'] ?? 0),
              _buildSummaryRow('Fahrzeuge', summary['vehicles'] ?? 0),
              _buildSummaryRow('Ausrüstung', summary['equipment'] ?? 0),
              _buildSummaryRow('Nachrichten', summary['messages'] ?? 0),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Speichern'),
            ),
          ],
        ),
      );
      
      if (confirmed != true || !mounted) {
        setState(() => _isExporting = false);
        return;
      }
      
      // Export mit Speichern-Dialog
      final success = await DataExportService.exportAllDataWithSave();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daten erfolgreich im Download-Ordner gespeichert'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Speichern'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      // Zeige Zusammenfassung vor dem Export
      final summary = await DataExportService.getDataSummary();
      if (!mounted) return;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daten exportieren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Folgende Daten werden exportiert:'),
              const SizedBox(height: 16),
              _buildSummaryRow('Einsätze', summary['operations'] ?? 0),
              _buildSummaryRow('Personal', summary['personnel'] ?? 0),
              _buildSummaryRow('Fahrzeuge', summary['vehicles'] ?? 0),
              _buildSummaryRow('Ausrüstung', summary['equipment'] ?? 0),
              _buildSummaryRow('Nachrichten', summary['messages'] ?? 0),
              const SizedBox(height: 16),
              const Text(
                'Die Daten werden als JSON-Datei exportiert, die Sie teilen oder sichern können.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exportieren'),
            ),
          ],
        ),
      );
      
      if (confirmed != true || !mounted) {
        setState(() => _isExporting = false);
        return;
      }
      
      // Export durchführen
      final filePath = await DataExportService.exportAllData();
      
      if (filePath != null && mounted) {
        // Teile die Datei
        final shared = await DataExportService.shareExportedData(filePath);
        
        if (shared && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daten erfolgreich exportiert'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Exportieren der Daten'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daten importieren'),
          content: const Text(
            'Beim Import werden ALLE aktuellen Daten überschrieben. '
            'Stellen Sie sicher, dass Sie vorher ein Backup erstellt haben.\n\n'
            'Möchten Sie fortfahren?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Importieren'),
            ),
          ],
        ),
      );
      
      if (confirmed != true || !mounted) {
        setState(() => _isImporting = false);
        return;
      }
      
      final success = await DataExportService.importData();
      
      if (success && mounted) {
        // Lade alle Provider neu
        await context.read<ArchiveNotifier>().loadArchivedOperations();
        await context.read<PersonnelNotifier>().loadPersonnel();
        await context.read<VehicleNotifier>().loadVehicles();
        await context.read<EquipmentNotifier>().loadEquipment();
        await context.read<MessageNotifier>().loadMessages();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daten erfolgreich importiert'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import abgebrochen oder fehlgeschlagen'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Daten löschen'),
        content: const Text(
          'WARNUNG: Diese Aktion löscht ALLE App-Daten unwiderruflich!\n\n'
          'Dazu gehören:\n'
          '• Alle Einsätze\n'
          '• Personal-Daten\n'
          '• Fahrzeuge\n'
          '• Ausrüstung\n'
          '• Nachrichten\n'
          '• Einstellungen\n\n'
          'Erstellen Sie vorher unbedingt ein Backup!\n\n'
          'Sind Sie ABSOLUT SICHER?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Alles löschen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      final doubleConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('LETZTE WARNUNG'),
          content: const Text(
            'Dies ist Ihre letzte Chance!\n\n'
            'Wirklich ALLE Daten unwiderruflich löschen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('JA, ALLES LÖSCHEN'),
            ),
          ],
        ),
      );
      
      if (doubleConfirmed == true && mounted) {
        // Zeige Loading-Anzeige
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        final success = await DataExportService.clearAllData();
        
        if (success && mounted) {
          // Leere alle Provider direkt (ohne Standarddaten zu laden)
          try {
            final archiveNotifier = context.read<ArchiveNotifier>();
            final personnelNotifier = context.read<PersonnelNotifier>();
            final vehicleNotifier = context.read<VehicleNotifier>();
            final equipmentNotifier = context.read<EquipmentNotifier>();
            final messageNotifier = context.read<MessageNotifier>();
            
            // Lösche die Listen direkt in den Notifiern
            archiveNotifier.clearAll();
            personnelNotifier.clearAll();
            vehicleNotifier.clearAll();
            equipmentNotifier.clearAll();
            messageNotifier.clearAll();
          } catch (e) {
            print('Fehler beim Leeren der Provider: $e');
          }
          
          // Schließe Loading-Dialog
          if (mounted) {
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alle Daten wurden gelöscht'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else if (mounted) {
          // Schließe Loading-Dialog
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fehler beim Löschen der Daten'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildSummaryRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int time,
    int minute = 0,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text('${time.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} Uhr'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool? value,
    Function(bool)? onChanged,
  }) {
    // Wenn value und onChanged angegeben sind, verwende diese
    if (value != null && onChanged != null) {
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
      );
    }
    
    // Sonst verwende ThemeNotifier für Dark Mode
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Switch(
            value: themeNotifier.isAutoScheduleEnabled,
            onChanged: (value) {
              themeNotifier.setAutoSchedule(value);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(value
                      ? 'Automatischer Dark Mode aktiviert (21:00 - 06:00 Uhr)'
                      : 'Automatischer Dark Mode deaktiviert'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Diese Funktion wird noch implementiert'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
