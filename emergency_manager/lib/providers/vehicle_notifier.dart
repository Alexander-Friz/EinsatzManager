import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Vehicle {
  final String id;
  final String funkrufname;
  final String fahrzeugklasse;
  final bool hasGroupLeader;
  final bool hasMessenger;
  final List<String> trupps;
  final DateTime? tuevDate;
  final DateTime? feuerwehrTuevDate;
  final String? imageBase64;

  Vehicle({
    required this.id,
    required this.funkrufname,
    required this.fahrzeugklasse,
    required this.hasGroupLeader,
    required this.hasMessenger,
    required this.trupps,
    this.tuevDate,
    this.feuerwehrTuevDate,
    this.imageBase64,
  });

  // Überprüfung, ob ein TÜV abgelaufen ist
  bool isTuevExpired(DateTime? date) {
    if (date == null) return false;
    return DateTime.now().isAfter(date);
  }

  bool get isTuevExpiredNow => isTuevExpired(tuevDate);
  bool get isFeuerwehrTuevExpiredNow => isTuevExpired(feuerwehrTuevDate);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'funkrufname': funkrufname,
      'fahrzeugklasse': fahrzeugklasse,
      'hasGroupLeader': hasGroupLeader,
      'hasMessenger': hasMessenger,
      'trupps': trupps,
      'tuevDate': tuevDate?.toIso8601String(),
      'feuerwehrTuevDate': feuerwehrTuevDate?.toIso8601String(),
      'imageBase64': imageBase64,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      funkrufname: (json['funkrufname'] ?? json['name']) as String,
      fahrzeugklasse: json['fahrzeugklasse'] as String,
      hasGroupLeader: json['hasGroupLeader'] as bool? ?? false,
      hasMessenger: json['hasMessenger'] as bool? ?? false,
      trupps: List<String>.from(json['trupps'] as List? ?? []),
      tuevDate: json['tuevDate'] != null
          ? DateTime.parse(json['tuevDate'] as String)
          : null,
      feuerwehrTuevDate: json['feuerwehrTuevDate'] != null
          ? DateTime.parse(json['feuerwehrTuevDate'] as String)
          : null,
      imageBase64: json['imageBase64'] as String?,
    );
  }

  Vehicle copyWith({
    String? id,
    String? funkrufname,
    String? fahrzeugklasse,
    bool? hasGroupLeader,
    bool? hasMessenger,
    List<String>? trupps,
    DateTime? tuevDate,
    DateTime? feuerwehrTuevDate,
    String? imageBase64,
  }) {
    return Vehicle(
      id: id ?? this.id,
      funkrufname: funkrufname ?? this.funkrufname,
      fahrzeugklasse: fahrzeugklasse ?? this.fahrzeugklasse,
      hasGroupLeader: hasGroupLeader ?? this.hasGroupLeader,
      hasMessenger: hasMessenger ?? this.hasMessenger,
      trupps: trupps ?? this.trupps,
      tuevDate: tuevDate ?? this.tuevDate,
      feuerwehrTuevDate: feuerwehrTuevDate ?? this.feuerwehrTuevDate,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}

class VehicleNotifier extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  late SharedPreferences _prefs;
  bool _isLoaded = false;

  List<Vehicle> get vehicleList => _vehicles;
  bool get isLoaded => _isLoaded;

  // Stelle sicher, dass _prefs initialisiert ist
  Future<void> _ensurePrefsInitialized() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> loadVehicles() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs.getString('vehicles_list');

    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _vehicles = jsonList
          .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveVehicles() async {
    await _ensurePrefsInitialized();
    final jsonList = _vehicles.map((vehicle) => vehicle.toJson()).toList();
    await _prefs.setString('vehicles_list', jsonEncode(jsonList));
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles.add(vehicle);
    await _saveVehicles();
    notifyListeners();
  }

  Future<void> updateVehicle(int index, Vehicle vehicle) async {
    if (index >= 0 && index < _vehicles.length) {
      _vehicles[index] = vehicle;
      await _saveVehicles();
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(int index) async {
    if (index >= 0 && index < _vehicles.length) {
      _vehicles.removeAt(index);
      await _saveVehicles();
      notifyListeners();
    }
  }

  // Getter für Fahrzeuge mit abgelaufenem TÜV
  List<Vehicle> get vehiclesWithExpiredTuev {
    return _vehicles.where((vehicle) => vehicle.isTuevExpiredNow).toList();
  }

  // Getter für Fahrzeuge mit abgelaufenem Feuerwehr-TÜV
  List<Vehicle> get vehiclesWithExpiredFeuerwehrTuev {
    return _vehicles.where((vehicle) => vehicle.isFeuerwehrTuevExpiredNow).toList();
  }

  void clearAll() {
    _vehicles.clear();
    _isLoaded = true;
    notifyListeners();
  }
}
