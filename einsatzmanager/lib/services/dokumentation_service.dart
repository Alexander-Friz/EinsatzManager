import 'package:flutter/foundation.dart';
import '../models/einsatz_documentation.dart';

class DokumentationService extends ChangeNotifier {
  final List<EinsatzDokumentation> _dokumentationen = [];

  List<EinsatzDokumentation> get dokumentationen => _dokumentationen;

  void addDokumentation(EinsatzDokumentation doku) {
    _dokumentationen.add(doku);
    notifyListeners();
  }

  void updateDokumentation(EinsatzDokumentation doku) {
    final index = _dokumentationen.indexWhere((d) => d.id == doku.id);
    if (index != -1) {
      _dokumentationen[index] = doku;
      notifyListeners();
    }
  }

  void deleteDokumentation(String id) {
    _dokumentationen.removeWhere((d) => d.id == id);
    notifyListeners();
  }

  EinsatzDokumentation? getDokumentationByEinsatzId(String einsatzId) {
    try {
      return _dokumentationen.firstWhere((d) => d.einsatzId == einsatzId);
    } catch (e) {
      return null;
    }
  }

  List<EinsatzDokumentation> getDokumentationenByMonth(int month, int year) {
    return _dokumentationen.where((d) {
      return d.dokumentiertAm.month == month && d.dokumentiertAm.year == year;
    }).toList()
      ..sort((a, b) => b.dokumentiertAm.compareTo(a.dokumentiertAm));
  }
}
