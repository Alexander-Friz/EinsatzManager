import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../providers/personnel_notifier.dart';
import '../services/notification_service.dart';

const List<String> availableLehrgaenge = [
  'Truppmann',
  'Truppführer',
  'Atemschutzgeräteträger',
  'Gruppenführer',
  'Zugführer',
  'Verbandführer',
  'Kettensägen-Lehrgang',
];

const List<String> availableAmts = [
  'Mannschaft',
  'Ausschuss',
  'Kommandant',
  'Stv. Kommandant',
];

const List<String> availableDienstgrade = [
  'Anwärter',
  'Feuerwehrmann',
  'Oberfeuerwehrmann',
  'Hauptfeuerwehrmann',
  'Löschmeister',
  'Oberlöschmeister',
  'Hauptlöschmeister',
  'Brandmeister',
  'Oberbrandmeister',
  'Hauptbrandmeister',
  'Leitender Hauptbrandmeister',
];

class PersonnelScreen extends StatefulWidget {
  const PersonnelScreen({super.key});

  @override
  State<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends State<PersonnelScreen> {
  @override
  void initState() {
    super.initState();
    // Lade die Personneldaten beim ersten Laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PersonnelNotifier>().loadPersonnel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalverwaltung'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        toolbarHeight: 50,
      ),
      body: Consumer<PersonnelNotifier>(
        builder: (context, personnelNotifier, child) {
          if (!personnelNotifier.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final personnelList = [...personnelNotifier.personnelList]..sort((a, b) => a.name.compareTo(b.name));

          return personnelList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text('Kein Personal vorhanden'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: personnelList.length,
                  itemBuilder: (context, index) {
                    final person = personnelList[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: person.imageBase64 != null
                            ? CircleAvatar(
                                radius: 28,
                                backgroundImage: MemoryImage(
                                  base64Decode(person.imageBase64!),
                                ),
                              )
                            : CircleAvatar(
                                radius: 28,
                                child: Text(
                                  person.name[0],
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                        title: Text(person.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${person.dienstgrad} - ${person.position}'),
                            Text(
                              person.lehrgaenge.isNotEmpty
                                  ? person.lehrgaenge.join(', ')
                                  : 'Keine Lehrgänge',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (person.hasAGTLehrgang)
                              Text(
                                'Status: ${person.inaktivAgt ? 'Inaktiv' : (person.agtUntersuchungAbgelaufen ? 'UNTERSUCHUNG ABGELAUFEN!' : 'Aktiv')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: person.agtUntersuchungAbgelaufen
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showPersonnelDialog(context, person, index);
                            } else if (value == 'delete') {
                              _deletePerson(context, person, index);
                            } else if (value == 'details') {
                              _showPersonnelDetails(context, person);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'details',
                              child: Text('Details'),
                            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPersonnelDialog(context, null, -1),
        tooltip: 'Personal hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPersonnelDialog(
      BuildContext context, PersonalData? person, int index) {
    final nameController = TextEditingController(text: person?.name ?? '');
    final emailController = TextEditingController(text: person?.email ?? '');
    final phoneController = TextEditingController(text: person?.phone ?? '');
    String selectedAmt = availableAmts.contains(person?.position)
        ? person!.position
        : 'Mannschaft';
    String selectedDienstgrad = availableDienstgrade.contains(person?.dienstgrad)
        ? person!.dienstgrad
        : 'Anwärter';
    List<String> selectedLehrgaenge = List.from(person?.lehrgaenge ?? []);
    DateTime? geburtstag = person?.geburtstag;
    DateTime? g263Datum = person?.g263Datum;
    DateTime? untersuchungAblaufdatum = person?.untersuchungAblaufdatum;
    bool inaktivAgt = person?.inaktivAgt ?? false;
    String? imageBase64 = person?.imageBase64;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool hasAGTLehrgang =
                selectedLehrgaenge.contains('Atemschutzgeräteträger');

            return AlertDialog(
              title: Text(person == null
                  ? 'Personal hinzufügen'
                  : 'Personal bearbeiten'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefonnummer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAmt,
                      decoration: const InputDecoration(
                        labelText: 'Amt',
                        border: OutlineInputBorder(),
                      ),
                      items: availableAmts.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedAmt = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDienstgrad,
                      decoration: const InputDecoration(
                        labelText: 'Dienstgrad',
                        border: OutlineInputBorder(),
                      ),
                      items: availableDienstgrade.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedDienstgrad = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Geburtstag'),
                      subtitle: Text(
                        geburtstag != null
                            ? '${geburtstag!.day}.${geburtstag!.month}.${geburtstag!.year}'
                            : 'Nicht eingetragen',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: geburtstag ?? DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            geburtstag = picked;
                          });
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lehrgänge:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...availableLehrgaenge.map((lehrgang) {
                      return CheckboxListTile(
                        title: Text(lehrgang),
                        value: selectedLehrgaenge.contains(lehrgang),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedLehrgaenge.add(lehrgang);
                            } else {
                              selectedLehrgaenge.remove(lehrgang);
                            }
                          });
                        },
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      );
                    }),
                    if (hasAGTLehrgang) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Atemschutzgeräteträger (AGT):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: const Text('G26.3 Untersuchung'),
                        subtitle: Text(
                          g263Datum != null
                              ? '${g263Datum!.day}.${g263Datum!.month}.${g263Datum!.year}'
                              : 'Nicht eingetragen',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: g263Datum ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              g263Datum = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        title: const Text('Untersuchung gültig bis'),
                        subtitle: Text(
                          untersuchungAblaufdatum != null
                              ? '${untersuchungAblaufdatum!.day}.${untersuchungAblaufdatum!.month}.${untersuchungAblaufdatum!.year}'
                              : 'Nicht eingetragen',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                untersuchungAblaufdatum ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              untersuchungAblaufdatum = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Kein aktiver AGT'),
                        value: inaktivAgt,
                        onChanged: (value) {
                          setState(() {
                            inaktivAgt = value ?? false;
                          });
                        },
                      ),
                    ],
                  const SizedBox(height: 24),
                  const Text(
                    'Personenbild:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (imageBase64 != null)
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
                            final bytes = await File(image.path).readAsBytes();
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
                            final bytes = await File(image.path).readAsBytes();
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
                        emailController.text.isEmpty ||
                        phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bitte alle Felder ausfüllen'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (hasAGTLehrgang &&
                        (g263Datum == null || untersuchungAblaufdatum == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Bitte AGT-Daten (G26.3 und Ablaufdatum) eintragen'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    if (person == null) {
                      // Neues Personal hinzufügen
                      final newPerson = PersonalData(
                        id: DateTime.now().toString(),
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        position: selectedAmt,
                        dienstgrad: selectedDienstgrad,
                        lehrgaenge: selectedLehrgaenge,
                        geburtstag: geburtstag,
                        g263Datum: g263Datum,
                        untersuchungAblaufdatum: untersuchungAblaufdatum,
                        inaktivAgt: inaktivAgt,
                        imageBase64: imageBase64,
                      );
                      await context
                          .read<PersonnelNotifier>()
                          .addPersonal(newPerson);

                      // Prüfe auf abgelaufene Untersuchung und sende Benachrichtigung
                      if (newPerson.agtUntersuchungAbgelaufen) {
                        final notificationService = NotificationService();
                        await notificationService.showAGTWarning(newPerson.name);
                      }
                    } else {
                      // Bestehendes Personal aktualisieren
                      final updatedPerson = PersonalData(
                        id: person.id,
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                        position: selectedAmt,
                        dienstgrad: selectedDienstgrad,
                        lehrgaenge: selectedLehrgaenge,
                        geburtstag: geburtstag,
                        g263Datum: g263Datum,
                        untersuchungAblaufdatum: untersuchungAblaufdatum,
                        inaktivAgt: inaktivAgt,
                        imageBase64: imageBase64,
                      );
                      await context
                          .read<PersonnelNotifier>()
                          .updatePersonal(index, updatedPerson);

                      // Prüfe auf abgelaufene Untersuchung und sende Benachrichtigung
                      if (updatedPerson.agtUntersuchungAbgelaufen) {
                        final notificationService = NotificationService();
                        await notificationService.showAGTWarning(updatedPerson.name);
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(person == null
                              ? 'Personal hinzugefügt'
                              : 'Personal aktualisiert'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child:
                      Text(person == null ? 'Hinzufügen' : 'Aktualisieren'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deletePerson(BuildContext context, PersonalData person, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Personal löschen'),
          content: Text('Möchten Sie "${person.name}" wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                await context.read<PersonnelNotifier>().deletePersonal(index);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Personal gelöscht'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }

  void _showPersonnelDetails(BuildContext context, PersonalData person) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Mitarbeiterdetails'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${person.name}'),
                const SizedBox(height: 8),
                Text('E-Mail: ${person.email}'),
                const SizedBox(height: 8),
                Text('Telefon: ${person.phone}'),
                const SizedBox(height: 8),
                Text('Amt: ${person.position}'),
                const SizedBox(height: 8),
                Text('Dienstgrad: ${person.dienstgrad}'),
                const SizedBox(height: 8),
                Text(
                  'Geburtstag: ${person.geburtstag != null ? '${person.geburtstag!.day}.${person.geburtstag!.month}.${person.geburtstag!.year}' : 'Nicht eingetragen'}',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lehrgänge:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (person.lehrgaenge.isEmpty)
                  const Text('Keine Lehrgänge vorhanden')
                else
                  ...person.lehrgaenge.map((lehrgang) => Text('• $lehrgang')),
                if (person.hasAGTLehrgang) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'AGT-Informationen:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'G26.3 Datum: ${person.g263Datum != null ? '${person.g263Datum!.day}.${person.g263Datum!.month}.${person.g263Datum!.year}' : 'Nicht eingetragen'}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Untersuchung gültig bis: ${person.untersuchungAblaufdatum != null ? '${person.untersuchungAblaufdatum!.day}.${person.untersuchungAblaufdatum!.month}.${person.untersuchungAblaufdatum!.year}' : 'Nicht eingetragen'}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${person.inaktivAgt ? 'Inaktiv' : (person.agtUntersuchungAbgelaufen ? 'UNTERSUCHUNG ABGELAUFEN!' : 'Aktiv')}',
                    style: TextStyle(
                      color: person.agtUntersuchungAbgelaufen
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
}
