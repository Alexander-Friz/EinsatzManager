import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/administration_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/operation_create_screen.dart';
import 'screens/device_manager_screen.dart';
import 'screens/past_operations_screen.dart';
import 'screens/message_center_screen.dart';
import 'screens/statistics_screen.dart';
import 'providers/theme_notifier.dart';
import 'providers/personnel_notifier.dart';
import 'providers/message_notifier.dart';
import 'providers/vehicle_notifier.dart';
import 'providers/archive_notifier.dart';
import 'providers/equipment_notifier.dart';

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
        ChangeNotifierProvider(create: (context) => EquipmentNotifier()),
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
          title: 'FireManager',
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

    // Lade Geräte
    if (!mounted) return;
    final equipmentNotifier = context.read<EquipmentNotifier>();
    await equipmentNotifier.loadEquipment();

    // Lade Nachrichten
    if (!mounted) return;
    final messageNotifier = context.read<MessageNotifier>();
    await messageNotifier.loadMessages();

    // Prüfe auf abgelaufene Untersuchungen, TÜVs und Geräteprüfungen
    if (!mounted) return;
    await _checkForExpiredItems();
  }

  Future<void> _checkForExpiredItems() async {
    final messageNotifier = context.read<MessageNotifier>();
    final personnelNotifier = context.read<PersonnelNotifier>();
    final vehicleNotifier = context.read<VehicleNotifier>();
    final equipmentNotifier = context.read<EquipmentNotifier>();

    // Prüfe Personal auf abgelaufene AGT-Untersuchungen
    for (final person in personnelNotifier.personnelList) {
      if (person.agtUntersuchungAbgelaufen) {
        await messageNotifier.addAGTExaminationWarning(person.name);
      }
    }

    // Prüfe Fahrzeuge auf abgelaufene TÜVs
    for (final vehicle in vehicleNotifier.vehicleList) {
      if (vehicle.isTuevExpiredNow) {
        await messageNotifier.addTuevWarning(vehicle.funkrufname, 'TÜV');
      }
      if (vehicle.isFeuerwehrTuevExpiredNow) {
        await messageNotifier.addTuevWarning(
            vehicle.funkrufname, 'Feuerwehr-TÜV');
      }
    }

    // Prüfe Geräte auf abgelaufene Prüfungen
    for (final equipment in equipmentNotifier.equipmentList) {
      if (equipment.isInspectionExpired) {
        await messageNotifier.addEquipmentInspectionWarning(
            equipment.name, equipment.number);
      }
    }
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
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
              isLarge: true,
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
              color: Colors.teal,
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
              icon: Icons.build,
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
            Consumer<MessageNotifier>(
              builder: (context, messageNotifier, child) {
                final unreadCount = messageNotifier.unreadCount;
                return _buildMenuTile(
                  context,
                  icon: Icons.message,
                  title: 'Nachrichtenzentrum',
                  subtitle: unreadCount > 0 ? '$unreadCount ungelesen' : null,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessageCenterScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            _buildMenuTile(
              context,
              icon: Icons.bar_chart,
              title: 'Statistiken',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
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
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return Card(
      elevation: isLarge ? 4 : 2,
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
                size: isLarge ? 48 : 32,
                color: Colors.white,
              ),
              SizedBox(height: isLarge ? 12 : 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isLarge ? 14 : 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
