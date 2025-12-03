enum GefahrenabwehrStufe {
  eins('Stufe 1 - Lokal begrenzt'),
  zwei('Stufe 2 - Mehrere Ortschaften'),
  drei('Stufe 3 - Überörtlich'),
  vier('Stufe 4 - Katastrophenfall');

  final String label;
  const GefahrenabwehrStufe(this.label);
}

enum EinsatzErgebnis {
  erfolgreich('Erfolgreich'),
  teilweise('Teilweise erfolgreich'),
  erfolglos('Erfolglos');

  final String label;
  const EinsatzErgebnis(this.label);
}

class EinsatzDokumentation {
  final String id;
  final String einsatzId;
  final String einsatzName;
  final GefahrenabwehrStufe gefahrenabwehrStufe;
  final String einsatzort;
  final String einsatzleiter;
  final int anzahlPersonal;
  final List<String> eingesetzteFahrzeuge;
  final String massnahmen;
  final EinsatzErgebnis ergebnis;
  final String besonderheiten;
  final DateTime dokumentiertAm;

  EinsatzDokumentation({
    required this.id,
    required this.einsatzId,
    required this.einsatzName,
    required this.gefahrenabwehrStufe,
    required this.einsatzort,
    required this.einsatzleiter,
    required this.anzahlPersonal,
    this.eingesetzteFahrzeuge = const [],
    required this.massnahmen,
    required this.ergebnis,
    required this.besonderheiten,
    required this.dokumentiertAm,
  });

  EinsatzDokumentation copyWith({
    String? id,
    String? einsatzId,
    String? einsatzName,
    GefahrenabwehrStufe? gefahrenabwehrStufe,
    String? einsatzort,
    String? einsatzleiter,
    int? anzahlPersonal,
    List<String>? eingesetzteFahrzeuge,
    String? massnahmen,
    EinsatzErgebnis? ergebnis,
    String? besonderheiten,
    DateTime? dokumentiertAm,
  }) {
    return EinsatzDokumentation(
      id: id ?? this.id,
      einsatzId: einsatzId ?? this.einsatzId,
      einsatzName: einsatzName ?? this.einsatzName,
      gefahrenabwehrStufe: gefahrenabwehrStufe ?? this.gefahrenabwehrStufe,
      einsatzort: einsatzort ?? this.einsatzort,
      einsatzleiter: einsatzleiter ?? this.einsatzleiter,
      anzahlPersonal: anzahlPersonal ?? this.anzahlPersonal,
      eingesetzteFahrzeuge: eingesetzteFahrzeuge ?? this.eingesetzteFahrzeuge,
      massnahmen: massnahmen ?? this.massnahmen,
      ergebnis: ergebnis ?? this.ergebnis,
      besonderheiten: besonderheiten ?? this.besonderheiten,
      dokumentiertAm: dokumentiertAm ?? this.dokumentiertAm,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'einsatzId': einsatzId,
    'einsatzName': einsatzName,
    'gefahrenabwehrStufe': gefahrenabwehrStufe.name,
    'einsatzort': einsatzort,
    'einsatzleiter': einsatzleiter,
    'anzahlPersonal': anzahlPersonal,
    'eingesetzteFahrzeuge': eingesetzteFahrzeuge,
    'massnahmen': massnahmen,
    'ergebnis': ergebnis.name,
    'besonderheiten': besonderheiten,
    'dokumentiertAm': dokumentiertAm.toIso8601String(),
  };

  factory EinsatzDokumentation.fromJson(Map<String, dynamic> json) =>
      EinsatzDokumentation(
        id: json['id'] as String,
        einsatzId: json['einsatzId'] as String,
        einsatzName: json['einsatzName'] as String,
        gefahrenabwehrStufe:
            GefahrenabwehrStufe.values.byName(json['gefahrenabwehrStufe'] as String),
        einsatzort: json['einsatzort'] as String,
        einsatzleiter: json['einsatzleiter'] as String,
        anzahlPersonal: json['anzahlPersonal'] as int,
        eingesetzteFahrzeuge:
            List<String>.from(json['eingesetzteFahrzeuge'] as List? ?? []),
        massnahmen: json['massnahmen'] as String,
        ergebnis: EinsatzErgebnis.values.byName(json['ergebnis'] as String),
        besonderheiten: json['besonderheiten'] as String,
        dokumentiertAm: DateTime.parse(json['dokumentiertAm'] as String),
      );
}
