import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/administration_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/operation_create_screen.dart';
import 'screens/device_manager_screen.dart';
import 'screens/past_operations_screen.dart';
import 'providers/theme_notifier.dart';
import 'providers/personnel_notifier.dart';
import 'providers/message_notifier.dart';
import 'providers/vehicle_notifier.dart';
import 'providers/archive_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeNotifier()),
        ChangeNotifierProvider(create: (context) => PersonnelNotifier()),
        ChangeNotifierProvider(create: (context) => MessageNotifier()),
        ChangeNotifierProvider(create: (context) => VehicleNotifier()),
        ChangeNotifierProvider(create: (context) => ArchiveNotifier()),
      ],
      child: const EmergencyManagerApp(),
    ),
  );
}

class EmergencyManagerApp extends StatelessWidget {
  const EmergencyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Feuerwehr Einsatzmanager',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.red,
              brightness: Brightness.dark,
              surface: const Color(0xFF2B2B2B),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          ),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Lade alle Daten und prüfe auf abgelaufene Items
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeAppData();
      }
    });
  }

  Future<void> _initializeAppData() async {
    // Lade Personal
    if (!mounted) return;
    final personnelNotifier = context.read<PersonnelNotifier>();
    await personnelNotifier.loadPersonnel();
    
    // Lade Fahrzeuge
    if (!mounted) return;
    final vehicleNotifier = context.read<VehicleNotifier>();
    await vehicleNotifier.loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feuerwehr Einsatzmanager'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        toolbarHeight: 50,
        actions: [
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return IconButton(
                icon: Icon(
                  themeNotifier.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: 'Dark Mode ${themeNotifier.isDarkMode ? 'aus' : 'an'}schalten',
                onPressed: () {
                  themeNotifier.setDarkMode(!themeNotifier.isDarkMode);
                },
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildMenuTile(
              context,
              icon: Icons.add_circle,
              title: 'Einsatz anlegen',
              color: Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OperationCreateScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.history,
              title: 'Vergangene Einsätze',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PastOperationsScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.people,
              title: 'Verwaltung',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdministrationScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.local_fire_department,
              title: 'Gerätewart',
              color: Colors.deepOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeviceManagerScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.settings,
              title: 'Einstellungen',
              color: Colors.grey,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.sync,
              title: 'Synchronisieren',
              color: Colors.purple,
              onTap: () {
                // TODO: Synchronisierung starten
                _showComingSoon(context, 'Synchronisieren');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.7),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
