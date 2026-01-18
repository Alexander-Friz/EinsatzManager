import 'package:flutter/material.dart';
import '../providers/theme_notifier.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Überprüfe den Schedule beim Laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ThemeNotifier>().updateScheduleIfNeeded();
      }
    });
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
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: themeNotifier.darkModeStartHour,
                          minute: 0,
                        ),
                      );
                      if (picked != null && context.mounted) {
                        context.read<ThemeNotifier>().setDarkModeStartHour(picked.hour);
                      }
                    },
                  ),
                  _buildTimePickerTile(
                    context,
                    icon: Icons.schedule,
                    title: 'Endzeit Dark Mode',
                    time: themeNotifier.darkModeEndHour,
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: themeNotifier.darkModeEndHour,
                          minute: 0,
                        ),
                      );
                      if (picked != null && context.mounted) {
                        context.read<ThemeNotifier>().setDarkModeEndHour(picked.hour);
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
        ],
      ),
    );
  }

  Widget _buildTimePickerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int time,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text('${time.toString().padLeft(2, '0')}:00 Uhr'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
