import 'package:flutter/foundation.dart';
import '../models/einsatz.dart';

class EinsatzService extends ChangeNotifier {
  final List<Einsatz> _einsaetze = [];
  
  List<Einsatz> get einsaetze => _einsaetze;
  
  List<Einsatz> get activeEinsaetze => _einsaetze
      .where((e) => e.status == EinsatzStatus.active)
      .toList()
      ..sort((a, b) => a.priority.priority.compareTo(b.priority.priority));
  
  List<Einsatz> get pendingEinsaetze => _einsaetze
      .where((e) => e.status == EinsatzStatus.pending)
      .toList()
      ..sort((a, b) => a.priority.priority.compareTo(b.priority.priority));
  
  List<Einsatz> get completedEinsaetze => _einsaetze
      .where((e) => e.status == EinsatzStatus.completed)
      .toList()
      ..sort((a, b) => b.completedAt?.compareTo(a.completedAt ?? DateTime.now()) ?? 0);

  // Neuen Einsatz hinzufügen
  void addEinsatz(Einsatz einsatz) {
    _einsaetze.add(einsatz);
    notifyListeners();
  }

  // Einsatz aktualisieren
  void updateEinsatz(Einsatz einsatz) {
    final index = _einsaetze.indexWhere((e) => e.id == einsatz.id);
    if (index != -1) {
      _einsaetze[index] = einsatz;
      notifyListeners();
    }
  }

  // Einsatz löschen
  void deleteEinsatz(String id) {
    _einsaetze.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Einsatz nach ID abrufen
  Einsatz? getEinsatzById(String id) {
    try {
      return _einsaetze.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Status aktualisieren
  void updateStatus(String id, EinsatzStatus status) {
    final einsatz = getEinsatzById(id);
    if (einsatz != null) {
      DateTime? startedAt = einsatz.startedAt;
      DateTime? completedAt = einsatz.completedAt;

      if (status == EinsatzStatus.active && startedAt == null) {
        startedAt = DateTime.now();
      }
      if (status == EinsatzStatus.completed && completedAt == null) {
        completedAt = DateTime.now();
      }

      updateEinsatz(einsatz.copyWith(
        status: status,
        startedAt: startedAt,
        completedAt: completedAt,
      ));
    }
  }

  // Personal zuweisen
  void assignPersonnel(String id, String personnelName) {
    final einsatz = getEinsatzById(id);
    if (einsatz != null && !einsatz.assignedPersonnel.contains(personnelName)) {
      final updated = einsatz.copyWith(
        assignedPersonnel: [...einsatz.assignedPersonnel, personnelName],
      );
      updateEinsatz(updated);
    }
  }

  // Personal entfernen
  void removePersonnel(String id, String personnelName) {
    final einsatz = getEinsatzById(id);
    if (einsatz != null) {
      final updated = einsatz.copyWith(
        assignedPersonnel: einsatz.assignedPersonnel
            .where((p) => p != personnelName)
            .toList(),
      );
      updateEinsatz(updated);
    }
  }

  // Einsätze nach Typ filtern
  List<Einsatz> filterByType(EinsatzType type) {
    return _einsaetze.where((e) => e.type == type).toList();
  }

  // Einsatze nach Priorität filtern
  List<Einsatz> filterByPriority(EinsatzPriority priority) {
    return _einsaetze.where((e) => e.priority == priority).toList();
  }

  // Statistiken
  Map<String, int> getStatistics() {
    return {
      'total': _einsaetze.length,
      'active': activeEinsaetze.length,
      'pending': pendingEinsaetze.length,
      'completed': completedEinsaetze.length,
    };
  }
}
