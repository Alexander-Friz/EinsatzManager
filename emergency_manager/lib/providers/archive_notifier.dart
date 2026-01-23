import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/operation.dart';

class ArchiveNotifier extends ChangeNotifier {
  List<Operation> _archivedOperations = [];
  late SharedPreferences _prefs;
  bool _isLoaded = false;

  List<Operation> get archivedOperations => _archivedOperations;
  bool get isLoaded => _isLoaded;

  Future<void> loadArchivedOperations() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs.getString('archived_operations_list');

    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _archivedOperations = jsonList
          .map((item) => Operation.fromJson(item as Map<String, dynamic>))
          .toList();
      // Sortiere nach Einsatzzeit (neuste zuerst)
      _archivedOperations.sort((a, b) => b.einsatzTime.compareTo(a.einsatzTime));
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveArchivedOperations() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonList =
        _archivedOperations.map((operation) => operation.toJson()).toList();
    await _prefs.setString('archived_operations_list', jsonEncode(jsonList));
  }

  Future<void> archiveOperation(Operation operation) async {
    await loadArchivedOperations(); // Stelle sicher, dass wir die aktuellen Daten haben
    _archivedOperations.add(operation);
    // Sortiere nach Einsatzzeit (neuste zuerst)
    _archivedOperations.sort((a, b) => b.einsatzTime.compareTo(a.einsatzTime));
    await _saveArchivedOperations();
    notifyListeners();
  }

  Future<void> deleteArchivedOperation(int index) async {
    if (index >= 0 && index < _archivedOperations.length) {
      _archivedOperations.removeAt(index);
      await _saveArchivedOperations();
      notifyListeners();
    }
  }

  Future<void> updateArchivedOperation(int index, Operation updatedOperation) async {
    if (index >= 0 && index < _archivedOperations.length) {
      _archivedOperations[index] = updatedOperation;
      // Sortiere nach Einsatzzeit (neuste zuerst)
      _archivedOperations.sort((a, b) => b.einsatzTime.compareTo(a.einsatzTime));
      await _saveArchivedOperations();
      notifyListeners();
    }
  }
}
