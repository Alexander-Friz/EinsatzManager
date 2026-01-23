import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Equipment {
  final String id;
  final String name;
  final String number;
  final DateTime? inspectionDate;
  final String notes;
  final String? imageBase64;

  Equipment({
    required this.id,
    required this.name,
    required this.number,
    this.inspectionDate,
    required this.notes,
    this.imageBase64,
  });

  bool get isInspectionExpired =>
      inspectionDate != null && inspectionDate!.isBefore(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'inspectionDate': inspectionDate?.toIso8601String(),
      'notes': notes,
      'imageBase64': imageBase64,
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] as String,
      name: json['name'] as String,
      number: json['number'] as String,
      inspectionDate: json['inspectionDate'] != null
          ? DateTime.parse(json['inspectionDate'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
      imageBase64: json['imageBase64'] as String?,
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? number,
    DateTime? inspectionDate,
    String? notes,
    String? imageBase64,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      notes: notes ?? this.notes,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }
}

class EquipmentNotifier extends ChangeNotifier {
  List<Equipment> _equipmentList = [];
  late SharedPreferences _prefs;
  bool _isLoaded = false;

  List<Equipment> get equipmentList => _equipmentList;
  bool get isLoaded => _isLoaded;

  Future<void> _ensurePrefsInitialized() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> loadEquipment() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs.getString('equipment_list');

    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _equipmentList = jsonList
          .map((item) => Equipment.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveEquipment() async {
    await _ensurePrefsInitialized();
    final jsonList = _equipmentList.map((equipment) => equipment.toJson()).toList();
    await _prefs.setString('equipment_list', jsonEncode(jsonList));
  }

  Future<void> addEquipment(Equipment equipment) async {
    _equipmentList.add(equipment);
    await _saveEquipment();
    notifyListeners();
  }

  Future<void> updateEquipment(int index, Equipment equipment) async {
    if (index >= 0 && index < _equipmentList.length) {
      _equipmentList[index] = equipment;
      await _saveEquipment();
      notifyListeners();
    }
  }

  Future<void> deleteEquipment(int index) async {
    if (index >= 0 && index < _equipmentList.length) {
      _equipmentList.removeAt(index);
      await _saveEquipment();
      notifyListeners();
    }
  }

  List<Equipment> get expiredEquipment {
    return _equipmentList.where((equipment) => equipment.isInspectionExpired).toList();
  }
}
