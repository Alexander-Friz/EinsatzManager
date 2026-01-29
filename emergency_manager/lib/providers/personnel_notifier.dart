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
  final String? imageBase64;

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
    this.imageBase64,
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
      'imageBase64': imageBase64,
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
      imageBase64: json['imageBase64'] as String?,
    );
  }

  PersonalData copyWith({
    DateTime? geburtstag,
    DateTime? g263Datum,
    DateTime? untersuchungAblaufdatum,
    bool? inaktivAgt,
    String? imageBase64,
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
      imageBase64: imageBase64 ?? this.imageBase64,
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
      // Keine Daten vorhanden - Liste bleibt leer
      _personnelList = [];
    }
    
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

  void clearAll() {
    _personnelList.clear();
    notifyListeners();
  }
}
