import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicle_notifier.dart';
import '../services/notification_service.dart';

const List<String> availableFahrzeugklassen = [
  'Loeschfahrzeug',
  'Hubrettungsfahrzeug',
  'Mannschaftstransportwagen',
  'Einsatzleitwagen',
  'Sonderfahrzeug',
];

const List<String> availableTrupps = [
  'Angriffstrupp',
  'Wassertrupp',
  'Schlauchtrupp',
];

class FleetScreen extends StatefulWidget {
  const FleetScreen({super.key});

  @override
  State<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends State<FleetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<VehicleNotifier>().loadVehicles();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuhrpark'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 50,
      ),
      body: Consumer<VehicleNotifier>(
        builder: (context, vehicleNotifier, child) {
          if (!vehicleNotifier.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicleList = vehicleNotifier.vehicleList;

          return vehicleList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_bus,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text('Kein Fahrzeug vorhanden'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: vehicleList.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicleList[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.fire_truck,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(vehicle.funkrufname),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle.fahrzeugklasse),
                            Text(
                              'Besatzung: Fahrer${vehicle.hasGroupLeader ? ', Gruppenführer' : ''}${vehicle.hasMessenger ? ', Melder' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (vehicle.tuevDate != null)
                              Text(
                                'TÜV: ${vehicle.tuevDate!.day}.${vehicle.tuevDate!.month}.${vehicle.tuevDate!.year}${vehicle.isTuevExpiredNow ? ' (ABGELAUFEN!)' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: vehicle.isTuevExpiredNow
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            if (vehicle.feuerwehrTuevDate != null)
                              Text(
                                'Feuerwehr-TÜV: ${vehicle.feuerwehrTuevDate!.day}.${vehicle.feuerwehrTuevDate!.month}.${vehicle.feuerwehrTuevDate!.year}${vehicle.isFeuerwehrTuevExpiredNow ? ' (ABGELAUFEN!)' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: vehicle.isFeuerwehrTuevExpiredNow
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            if (vehicle.trupps.isNotEmpty)
                              Text(
                                'Trupps: ${vehicle.trupps.join(', ')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showVehicleDialog(context, vehicle, index);
                            } else if (value == 'delete') {
                              _deleteVehicle(context, index);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Bearbeiten'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('Löschen'),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showVehicleDetails(context, vehicle);
                        },
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showVehicleDialog(context, null, -1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showVehicleDialog(
      BuildContext context, Vehicle? vehicle, int index) {
    final nameController = TextEditingController(text: vehicle?.funkrufname ?? '');
    String selectedFahrzeugklasse =
        vehicle?.fahrzeugklasse ?? 'Loeschfahrzeug';
    bool hasGroupLeader = vehicle?.hasGroupLeader ?? false;
    bool hasMessenger = vehicle?.hasMessenger ?? false;
    List<String> selectedTrupps = List.from(vehicle?.trupps ?? []);
    DateTime? tuevDate = vehicle?.tuevDate;
    DateTime? feuerwehrTuevDate = vehicle?.feuerwehrTuevDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(vehicle == null
                  ? 'Fahrzeug hinzufügen'
                  : 'Fahrzeug bearbeiten'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Funkrufname',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFahrzeugklasse,
                      decoration: const InputDecoration(
                        labelText: 'Fahrzeugklasse',
                        border: OutlineInputBorder(),
                      ),
                      items: availableFahrzeugklassen.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedFahrzeugklasse = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Besatzung:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Fahrer'),
                      value: true,
                      onChanged: null, // Always checked and disabled
                      enabled: false,
                    ),
                    CheckboxListTile(
                      title: const Text('Gruppenführer'),
                      value: hasGroupLeader,
                      onChanged: (value) {
                        setState(() {
                          hasGroupLeader = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Melder'),
                      value: hasMessenger,
                      onChanged: (value) {
                        setState(() {
                          hasMessenger = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Trupps:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...availableTrupps.map((trupp) {
                      return CheckboxListTile(
                        title: Text(trupp),
                        value: selectedTrupps.contains(trupp),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedTrupps.add(trupp);
                            } else {
                              selectedTrupps.remove(trupp);
                            }
                          });
                        },
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'TÜV Termine:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('TÜV Datum'),
                      subtitle: Text(
                        tuevDate != null
                            ? '${tuevDate!.day}.${tuevDate!.month}.${tuevDate!.year}'
                            : 'Nicht eingetragen',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tuevDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            tuevDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Feuerwehr-TÜV Datum'),
                      subtitle: Text(
                        feuerwehrTuevDate != null
                            ? '${feuerwehrTuevDate!.day}.${feuerwehrTuevDate!.month}.${feuerwehrTuevDate!.year}'
                            : 'Nicht eingetragen',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: feuerwehrTuevDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            feuerwehrTuevDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bitte Funkrufname eingeben'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (vehicle == null) {
                      final newVehicle = Vehicle(
                        id: DateTime.now().toString(),
                        funkrufname: nameController.text,
                        fahrzeugklasse: selectedFahrzeugklasse,
                        hasGroupLeader: hasGroupLeader,
                        hasMessenger: hasMessenger,
                        trupps: selectedTrupps,
                        tuevDate: tuevDate,
                        feuerwehrTuevDate: feuerwehrTuevDate,
                      );
                      await context
                          .read<VehicleNotifier>()
                          .addVehicle(newVehicle);

                      // Prüfe auf abgelaufene TÜVs und sende Benachrichtigungen
                      final notificationService = NotificationService();
                      if (newVehicle.isTuevExpiredNow) {
                        await notificationService.showTuevWarning(
                            newVehicle.funkrufname, 'TÜV');
                      }
                      if (newVehicle.isFeuerwehrTuevExpiredNow) {
                        await notificationService.showTuevWarning(
                            newVehicle.funkrufname, 'Feuerwehr-TÜV');
                      }
                    } else {
                      final updatedVehicle = Vehicle(
                        id: vehicle.id,
                        funkrufname: nameController.text,
                        fahrzeugklasse: selectedFahrzeugklasse,
                        hasGroupLeader: hasGroupLeader,
                        hasMessenger: hasMessenger,
                        trupps: selectedTrupps,
                        tuevDate: tuevDate,
                        feuerwehrTuevDate: feuerwehrTuevDate,
                      );
                      await context
                          .read<VehicleNotifier>()
                          .updateVehicle(index, updatedVehicle);

                      // Prüfe auf abgelaufene TÜVs und sende Benachrichtigungen
                      final notificationService = NotificationService();
                      if (updatedVehicle.isTuevExpiredNow) {
                        await notificationService.showTuevWarning(
                            updatedVehicle.funkrufname, 'TÜV');
                      }
                      if (updatedVehicle.isFeuerwehrTuevExpiredNow) {
                        await notificationService.showTuevWarning(
                            updatedVehicle.funkrufname, 'Feuerwehr-TÜV');
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(vehicle == null
                              ? 'Fahrzeug hinzugefügt'
                              : 'Fahrzeug aktualisiert'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(vehicle == null ? 'Hinzufügen' : 'Aktualisieren'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showVehicleDetails(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(vehicle.funkrufname),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fahrzeugklasse: ${vehicle.fahrzeugklasse}'),
                const SizedBox(height: 16),
                const Text(
                  'Besatzung:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• Fahrer'),
                if (vehicle.hasGroupLeader) Text('• Gruppenführer'),
                if (vehicle.hasMessenger) Text('• Melder'),
                const SizedBox(height: 16),
                if (vehicle.trupps.isNotEmpty) ...[
                  const Text(
                    'Trupps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...vehicle.trupps.map((trupp) => Text('• $trupp')),
                  const SizedBox(height: 16),
                ],
                if (vehicle.tuevDate != null) ...[
                  const Text(
                    'TÜV Termine:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TÜV: ${vehicle.tuevDate!.day}.${vehicle.tuevDate!.month}.${vehicle.tuevDate!.year}',
                    style: TextStyle(
                      color: vehicle.isTuevExpiredNow
                          ? Colors.red
                          : Colors.green,
                      fontWeight: vehicle.isTuevExpiredNow
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (vehicle.feuerwehrTuevDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Feuerwehr-TÜV: ${vehicle.feuerwehrTuevDate!.day}.${vehicle.feuerwehrTuevDate!.month}.${vehicle.feuerwehrTuevDate!.year}',
                      style: TextStyle(
                        color: vehicle.isFeuerwehrTuevExpiredNow
                            ? Colors.red
                            : Colors.green,
                        fontWeight: vehicle.isFeuerwehrTuevExpiredNow
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }

  void _deleteVehicle(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Fahrzeug löschen'),
          content: const Text(
              'Sind Sie sicher, dass Sie dieses Fahrzeug löschen möchten?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                context.read<VehicleNotifier>().deleteVehicle(index);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fahrzeug gelöscht'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }
}
