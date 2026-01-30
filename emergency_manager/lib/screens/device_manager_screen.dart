import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../providers/equipment_notifier.dart';
import '../providers/message_notifier.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  @override
  State<DeviceManagerScreen> createState() => _DeviceManagerScreenState();
}

class _DeviceManagerScreenState extends State<DeviceManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EquipmentNotifier>().loadEquipment();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerätewart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 50,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: const Text('Hinzufügen'),
              onPressed: () {
                _showEquipmentDialog(context, null, -1);
              },
            ),
          ),
        ],
      ),
      body: Consumer<EquipmentNotifier>(
        builder: (context, equipmentNotifier, child) {
          if (!equipmentNotifier.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final equipmentList = equipmentNotifier.equipmentList;

          return equipmentList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.construction,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text('Kein Gerät vorhanden'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: equipmentList.length,
                  itemBuilder: (context, index) {
                    final equipment = equipmentList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: equipment.imageBase64 != null && equipment.imageBase64!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(equipment.imageBase64!),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.construction,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 40,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.construction,
                                color: Theme.of(context).colorScheme.primary,
                                size: 40,
                              ),
                        title: Text(equipment.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nr.: ${equipment.number}'),
                            if (equipment.inspectionDate != null)
                              Text(
                                'Prüfdatum: ${equipment.inspectionDate!.day}.${equipment.inspectionDate!.month}.${equipment.inspectionDate!.year}${equipment.isInspectionExpired ? ' (ABGELAUFEN!)' : ''}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: equipment.isInspectionExpired
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (equipment.notes.isNotEmpty)
                              Text(
                                equipment.notes,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEquipmentDialog(context, equipment, index);
                            } else if (value == 'delete') {
                              _deleteEquipment(context, index);
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
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  void _showEquipmentDialog(
      BuildContext context, Equipment? equipment, int index) {
    final nameController = TextEditingController(text: equipment?.name ?? '');
    final numberController =
        TextEditingController(text: equipment?.number ?? '');
    final notesController = TextEditingController(text: equipment?.notes ?? '');
    DateTime? inspectionDate = equipment?.inspectionDate;
    String? imageBase64 = equipment?.imageBase64;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(equipment == null
                  ? 'Gerät hinzufügen'
                  : 'Gerät bearbeiten'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Bezeichnung',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Nummer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Prüfdatum'),
                      subtitle: Text(
                        inspectionDate != null
                            ? '${inspectionDate!.day}.${inspectionDate!.month}.${inspectionDate!.year}'
                            : 'Nicht eingetragen',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: inspectionDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            inspectionDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notizen',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Gerätebild:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (imageBase64 != null && imageBase64!.isNotEmpty)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(imageBase64!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 70,
                            );
                            if (image != null) {
                              final bytes =
                                  await File(image.path).readAsBytes();
                              setState(() {
                                imageBase64 = base64Encode(bytes);
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Kamera'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (image != null) {
                              final bytes =
                                  await File(image.path).readAsBytes();
                              setState(() {
                                imageBase64 = base64Encode(bytes);
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galerie'),
                        ),
                        if (imageBase64 != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                imageBase64 = null;
                              });
                            },
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            tooltip: 'Bild entfernen',
                          ),
                      ],
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
                    if (nameController.text.isEmpty ||
                        numberController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Bitte Bezeichnung und Nummer eingeben'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (equipment == null) {
                      final newEquipment = Equipment(
                        id: DateTime.now().toString(),
                        name: nameController.text,
                        number: numberController.text,
                        inspectionDate: inspectionDate,
                        notes: notesController.text,
                        imageBase64: imageBase64,
                      );
                      await context
                          .read<EquipmentNotifier>()
                          .addEquipment(newEquipment);

                      // Prüfe auf abgelaufene Prüfung und sende Nachricht ins Zentrum
                      if (newEquipment.isInspectionExpired && context.mounted) {
                        await context
                            .read<MessageNotifier>()
                            .addEquipmentInspectionWarning(
                                newEquipment.name, newEquipment.number);
                      }
                    } else {
                      final updatedEquipment = Equipment(
                        id: equipment.id,
                        name: nameController.text,
                        number: numberController.text,
                        inspectionDate: inspectionDate,
                        notes: notesController.text,
                        imageBase64: imageBase64,
                      );
                      await context
                          .read<EquipmentNotifier>()
                          .updateEquipment(index, updatedEquipment);

                      // Prüfe auf abgelaufene Prüfung und sende Nachricht ins Zentrum
                      if (updatedEquipment.isInspectionExpired && context.mounted) {
                        await context
                            .read<MessageNotifier>()
                            .addEquipmentInspectionWarning(
                                updatedEquipment.name, updatedEquipment.number);
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteEquipment(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Gerät löschen'),
          content: const Text('Möchten Sie dieses Gerät wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                await context.read<EquipmentNotifier>().deleteEquipment(index);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }
}
