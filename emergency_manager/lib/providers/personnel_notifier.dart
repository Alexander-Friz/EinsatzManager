import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PersonalData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String position;
  final String dienstgrad;
  final List<String> lehrgaenge;
  final DateTime? geburtstag;
  final DateTime? g263Datum;
  final DateTime? untersuchungAblaufdatum;
  final bool inaktivAgt;

  PersonalData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.dienstgrad,
    required this.lehrgaenge,
    this.geburtstag,
    this.g263Datum,
    this.untersuchungAblaufdatum,
    this.inaktivAgt = false,
  });

  bool get hasAGTLehrgang => lehrgaenge.contains('Atemschutzgeräteträger');
  bool get isAGTActive => hasAGTLehrgang && !inaktivAgt;
  bool get agtUntersuchungAbgelaufen =>
      isAGTActive &&
      untersuchungAblaufdatum != null &&
      untersuchungAblaufdatum!.isBefore(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'dienstgrad': dienstgrad,
      'lehrgaenge': lehrgaenge,
      'geburtstag': geburtstag?.toIso8601String(),
      'g263Datum': g263Datum?.toIso8601String(),
      'untersuchungAblaufdatum': untersuchungAblaufdatum?.toIso8601String(),
      'inaktivAgt': inaktivAgt,
    };
  }

  factory PersonalData.fromJson(Map<String, dynamic> json) {
    return PersonalData(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String,
      position: json['position'] as String,
      dienstgrad: json['dienstgrad'] as String? ?? '',
      lehrgaenge: List<String>.from(json['lehrgaenge'] as List? ?? []),
      geburtstag: json['geburtstag'] != null
          ? DateTime.parse(json['geburtstag'] as String)
          : null,
      g263Datum: json['g263Datum'] != null
          ? DateTime.parse(json['g263Datum'] as String)
          : null,
      untersuchungAblaufdatum: json['untersuchungAblaufdatum'] != null
          ? DateTime.parse(json['untersuchungAblaufdatum'] as String)
          : null,
      inaktivAgt: json['inaktivAgt'] as bool? ?? false,
    );
  }

  PersonalData copyWith({
    DateTime? geburtstag,
    DateTime? g263Datum,
    DateTime? untersuchungAblaufdatum,
    bool? inaktivAgt,
  }) {
    return PersonalData(
      id: id,
      name: name,
      email: email,
      phone: phone,
      position: position,
      dienstgrad: dienstgrad,
      lehrgaenge: lehrgaenge,
      geburtstag: geburtstag ?? this.geburtstag,
      g263Datum: g263Datum ?? this.g263Datum,
      untersuchungAblaufdatum:
          untersuchungAblaufdatum ?? this.untersuchungAblaufdatum,
      inaktivAgt: inaktivAgt ?? this.inaktivAgt,
    );
  }
}

class PersonnelNotifier extends ChangeNotifier {
  List<PersonalData> _personnelList = [];
  late SharedPreferences _prefs;
  bool _isLoaded = false;

  List<PersonalData> get personnelList => _personnelList;
  bool get isLoaded => _isLoaded;

  // Gibt alle AGT mit abgelaufener Untersuchung zurück
  List<PersonalData> get agtWithExpiredExamination =>
      _personnelList.where((p) => p.agtUntersuchungAbgelaufen).toList();

  Future<void> loadPersonnel() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs.getString('personnel_list');
    
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _personnelList = jsonList
          .map((item) => PersonalData.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Standard-Daten wenn keine gespeichert
      _personnelList = [
        PersonalData(
          id: '1',
          name: 'Max Müller',
          email: 'max.mueller@feuerwehr.de',
          phone: '0123 456789',
          position: 'Brandmeister',
          dienstgrad: 'Hauptbrandmeister',
          lehrgaenge: ['Truppmann', 'Truppführer', 'Atemschutzgeräteträger'],
          geburtstag: DateTime(1985, 6, 15),
          g263Datum: DateTime.now().subtract(const Duration(days: 30)),
          untersuchungAblaufdatum: DateTime.now().add(const Duration(days: 100)),
          inaktivAgt: false,
        ),
        PersonalData(
          id: '2',
          name: 'Anna Schmidt',
          email: 'anna.schmidt@feuerwehr.de',
          phone: '0123 456790',
          position: 'Feuerwehrfrau',
          dienstgrad: 'Oberbrandmeisterin',
          lehrgaenge: ['Truppmann', 'Atemschutzgeräteträger'],
          geburtstag: DateTime(1992, 3, 22),
          g263Datum: null,
          untersuchungAblaufdatum: null,
          inaktivAgt: false,
        ),
        PersonalData(
          id: '3',
          name: 'Peter Hoffmann',
          email: 'peter.hoffmann@feuerwehr.de',
          phone: '0123 456791',
          position: 'Feuerwehrmann',
          dienstgrad: 'Hauptfeuerwehrmann',
          lehrgaenge: ['Truppmann', 'Truppführer', 'Kettensägen-Lehrgang'],
          geburtstag: DateTime(1988, 11, 8),
          g263Datum: null,
          untersuchungAblaufdatum: null,
          inaktivAgt: false,
        ),
        PersonalData(
          id: '4',
          name: 'Sandra Bauer',
          email: 'sandra.bauer@feuerwehr.de',
          phone: '0123 456792',
          position: 'Ausschuss',
          dienstgrad: 'Brandmeister',
          lehrgaenge: ['Truppmann', 'Truppführer', 'Atemschutzgeräteträger', 'Gruppenführer'],
          geburtstag: DateTime(1990, 5, 17),
          g263Datum: DateTime(2024, 1, 10),
          untersuchungAblaufdatum: DateTime(2026, 1, 10),
          inaktivAgt: false,
        ),
        PersonalData(
          id: '5',
          name: 'Klaus Meier',
          email: 'klaus.meier@feuerwehr.de',
          phone: '0123 456793',
          position: 'Feuerwehrmann',
          dienstgrad: 'Feuerwehrmann',
          lehrgaenge: ['Truppmann'],
          geburtstag: DateTime(2000, 9, 3),
          g263Datum: null,
          untersuchungAblaufdatum: null,
          inaktivAgt: false,
        ),
        PersonalData(
          id: '6',
          name: 'Katharina Fischer',
          email: 'katharina.fischer@feuerwehr.de',
          phone: '0123 456794',
          position: 'Kommandant',
          dienstgrad: 'Leitender Hauptbrandmeister',
          lehrgaenge: ['Truppmann', 'Truppführer', 'Atemschutzgeräteträger', 'Gruppenführer', 'Zugführer'],
          geburtstag: DateTime(1980, 2, 28),
          g263Datum: DateTime(2023, 8, 15),
          untersuchungAblaufdatum: DateTime(2025, 8, 15),
          inaktivAgt: false,
        ),
        PersonalData(
          id: '7',
          name: 'Thomas Wagner',
          email: 'thomas.wagner@feuerwehr.de',
          phone: '0123 456795',
          position: 'Feuerwehrmann',
          dienstgrad: 'Oberfeuerwehrmann',
          lehrgaenge: ['Truppmann', 'Truppführer'],
          geburtstag: DateTime(1995, 7, 21),
          g263Datum: null,
          untersuchungAblaufdatum: null,
          inaktivAgt: false,
        ),
        PersonalData(
          id: '8',
          name: 'Julia Richter',
          email: 'julia.richter@feuerwehr.de',
          phone: '0123 456796',
          position: 'Ausschuss',
          dienstgrad: 'Oberlöschmeister',
          lehrgaenge: ['Truppmann', 'Truppführer', 'Atemschutzgeräteträger', 'Verbandführer'],
          geburtstag: DateTime(1987, 12, 14),
          g263Datum: DateTime.now().subtract(const Duration(days: 60)),
          untersuchungAblaufdatum: DateTime.now().add(const Duration(days: 70)),
          inaktivAgt: false,
        ),
        PersonalData(
          id: '9',
          name: 'Robert König',
          email: 'robert.koenig@feuerwehr.de',
          phone: '0123 456797',
          position: 'Stv. Kommandant',
          dienstgrad: 'Oberbrandmeister',
          lehrgaenge: ['Truppmann', 'Truppführer', 'Atemschutzgeräteträger', 'Gruppenführer', 'Zugführer'],
          geburtstag: DateTime(1982, 4, 9),
          g263Datum: DateTime(2024, 3, 20),
          untersuchungAblaufdatum: DateTime(2026, 3, 20),
          inaktivAgt: false,
        ),
        PersonalData(
          id: '10',
          name: 'Daniela Krämer',
          email: 'daniela.kraemer@feuerwehr.de',
          phone: '0123 456798',
          position: 'Feuerwehrfrau',
          dienstgrad: 'Löschmeister',
          lehrgaenge: ['Truppmann', 'Truppführer', 'Atemschutzgeräteträger'],
          geburtstag: DateTime(1993, 8, 5),
          g263Datum: null,
          untersuchungAblaufdatum: null,
          inaktivAgt: false,
        ),
      ];
      await _savePersonnel();
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _savePersonnel() async {
    final jsonList = _personnelList.map((person) => person.toJson()).toList();
    await _prefs.setString('personnel_list', jsonEncode(jsonList));
  }

  Future<void> addPersonal(PersonalData person) async {
    _personnelList.add(person);
    await _savePersonnel();
    notifyListeners();
  }

  Future<void> updatePersonal(int index, PersonalData person) async {
    if (index >= 0 && index < _personnelList.length) {
      _personnelList[index] = person;
      await _savePersonnel();
      notifyListeners();
    }
  }

  Future<void> deletePersonal(int index) async {
    if (index >= 0 && index < _personnelList.length) {
      _personnelList.removeAt(index);
      await _savePersonnel();
      notifyListeners();
    }
  }
}
