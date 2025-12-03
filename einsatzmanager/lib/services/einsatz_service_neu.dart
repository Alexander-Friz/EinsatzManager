import 'package:flutter/foundation.dart';
import '../models/einsatz_neu.dart';

class EinsatzService extends ChangeNotifier {
  final List<Einsatz> _einsaetze = [];
  
  List<Einsatz> get einsaetze => _einsaetze;

  void addEinsatz(Einsatz einsatz) {
    _einsaetze.add(einsatz);
    notifyListeners();
  }

  void updateEinsatz(Einsatz einsatz) {
    final index = _einsaetze.indexWhere((e) => e.id == einsatz.id);
    if (index != -1) {
      _einsaetze[index] = einsatz;
      notifyListeners();
    }
  }

  void deleteEinsatz(String id) {
    _einsaetze.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Einsatz? getEinsatzById(String id) {
    try {
      return _einsaetze.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
