import 'package:flutter/material.dart';

// Vordefinierte Einsatzarten
const List<String> vordefinierteEinsatzarten = [
  'Wohnhausbrand',
  'Fahrzeugbrand',
  'Containerfeuer',
  'Flächenbrand',
  'Verkehrsunfall mit Personenschaden',
  'Verkehrsunfall ohne Personenschaden',
  'Technische Hilfeleistung',
  'Person in Notlage',
  'Rettung aus Höhe',
  'Rettung aus Gewässer',
  'Gefahrenstoffunfall',
  'Garuchwahr',
  'Brandsicherungswache',
  'Sonstiges',
];

// Atemschutz-Eintrag für Protokollierung
class AtemschutzEintrag {
  final String fahrzeugId;
  final String fahrzeugName;
  final String truppName; // "Angriffstrupp" oder "Wassertrupp"
  final DateTime zeitpunkt;
  final String ereignis; // "START", "20MIN_ALARM", "10MIN_ALARM", "STOP"
  final int? druck; // in bar

  AtemschutzEintrag({
    required this.fahrzeugId,
    required this.fahrzeugName,
    required this.truppName,
    required this.zeitpunkt,
    required this.ereignis,
    this.druck,
  });

  Map<String, dynamic> toJson() => {
    'fahrzeugId': fahrzeugId,
    'fahrzeugName': fahrzeugName,
    'truppName': truppName,
    'zeitpunkt': zeitpunkt.toIso8601String(),
    'ereignis': ereignis,
    'druck': druck,
  };

  factory AtemschutzEintrag.fromJson(Map<String, dynamic> json) => AtemschutzEintrag(
    fahrzeugId: json['fahrzeugId'] as String,
    fahrzeugName: json['fahrzeugName'] as String,
    truppName: json['truppName'] as String,
    zeitpunkt: DateTime.parse(json['zeitpunkt'] as String),
    ereignis: json['ereignis'] as String,
    druck: json['druck'] as int?,
  );
}

enum TruppPosition {
  gruppenfuehrer('Gruppenführer'),
  maschinist('Maschinist'),
  melder('Melder'),
  schlauchtruppfuehrer('Schlauchtrupp Führer'),
  schlauchtruppmann('Schlauchtrupp Mann'),
  wassertrupp_fuehrer('Wassertrupp Führer'),
  wassertrupp_mann('Wassertrupp Mann'),
  angriffstruppfuehrer('Angriffstrupp Führer'),
  angriffstruppmann('Angriffstrupp Mann');

  final String label;
  const TruppPosition(this.label);
}

class Besatzung {
  final TruppPosition position;
  final String personName;

  Besatzung({
    required this.position,
    required this.personName,
  });

  Besatzung copyWith({
    TruppPosition? position,
    String? personName,
  }) {
    return Besatzung(
      position: position ?? this.position,
      personName: personName ?? this.personName,
    );
  }

  Map<String, dynamic> toJson() => {
    'position': position.name,
    'personName': personName,
  };

  factory Besatzung.fromJson(Map<String, dynamic> json) => Besatzung(
    position: TruppPosition.values.byName(json['position'] as String),
    personName: json['personName'] as String,
  );
}

class Fahrzeug {
  final String id;
  final String name;
  final List<Besatzung> besatzung;
  final bool atemschutzEinsatz;
  final int? angriffstruppZeit; // in Sekunden
  final int? wassertruippZeit; // in Sekunden

  Fahrzeug({
    required this.id,
    required this.name,
    this.besatzung = const [],
    this.atemschutzEinsatz = false,
    this.angriffstruppZeit,
    this.wassertruippZeit,
  });

  Fahrzeug copyWith({
    String? id,
    String? name,
    List<Besatzung>? besatzung,
    bool? atemschutzEinsatz,
    int? angriffstruppZeit,
    int? wassertruippZeit,
  }) {
    return Fahrzeug(
      id: id ?? this.id,
      name: name ?? this.name,
      besatzung: besatzung ?? this.besatzung,
      atemschutzEinsatz: atemschutzEinsatz ?? this.atemschutzEinsatz,
      angriffstruppZeit: angriffstruppZeit ?? this.angriffstruppZeit,
      wassertruippZeit: wassertruippZeit ?? this.wassertruippZeit,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'besatzung': besatzung.map((b) => b.toJson()).toList(),
    'atemschutzEinsatz': atemschutzEinsatz,
    'angriffstruppZeit': angriffstruppZeit,
    'wassertruippZeit': wassertruippZeit,
  };

  factory Fahrzeug.fromJson(Map<String, dynamic> json) => Fahrzeug(
    id: json['id'] as String,
    name: json['name'] as String,
    besatzung: (json['besatzung'] as List?)
        ?.map((b) => Besatzung.fromJson(b as Map<String, dynamic>))
        .toList() ??
        [],
    atemschutzEinsatz: json['atemschutzEinsatz'] as bool? ?? false,
    angriffstruppZeit: json['angriffstruppZeit'] as int?,
    wassertruippZeit: json['wassertruippZeit'] as int?,
  );
}

class Einsatz {
  final String id;
  final String einsatzart;
  final DateTime datum;
  final TimeOfDay uhrzeit;
  final String adresse;
  final double? latitude;
  final double? longitude;
  final List<Fahrzeug> fahrzeuge;
  final DateTime erstelltAm;
  final DateTime? beendetAm;
  final String? notizen;
  final Map<String, int>? atemschutzZeiten; // fahrzeugId -> verbrauchte Sekunden
  final List<AtemschutzEintrag>? atemschutzProtokoll; // Detailliertes Protokoll

  Einsatz({
    required this.id,
    required this.einsatzart,
    required this.datum,
    required this.uhrzeit,
    required this.adresse,
    this.latitude,
    this.longitude,
    this.fahrzeuge = const [],
    required this.erstelltAm,
    this.beendetAm,
    this.notizen,
    this.atemschutzZeiten,
    this.atemschutzProtokoll,
  });

  Einsatz copyWith({
    String? id,
    String? einsatzart,
    DateTime? datum,
    TimeOfDay? uhrzeit,
    String? adresse,
    double? latitude,
    double? longitude,
    List<Fahrzeug>? fahrzeuge,
    DateTime? erstelltAm,
    DateTime? beendetAm,
    String? notizen,
    Map<String, int>? atemschutzZeiten,
    List<AtemschutzEintrag>? atemschutzProtokoll,
  }) {
    return Einsatz(
      id: id ?? this.id,
      einsatzart: einsatzart ?? this.einsatzart,
      datum: datum ?? this.datum,
      uhrzeit: uhrzeit ?? this.uhrzeit,
      adresse: adresse ?? this.adresse,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fahrzeuge: fahrzeuge ?? this.fahrzeuge,
      erstelltAm: erstelltAm ?? this.erstelltAm,
      beendetAm: beendetAm ?? this.beendetAm,
      notizen: notizen ?? this.notizen,
      atemschutzZeiten: atemschutzZeiten ?? this.atemschutzZeiten,
      atemschutzProtokoll: atemschutzProtokoll ?? this.atemschutzProtokoll,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'einsatzart': einsatzart,
    'datum': datum.toIso8601String(),
    'uhrzeit': '${uhrzeit.hour.toString().padLeft(2, '0')}:${uhrzeit.minute.toString().padLeft(2, '0')}',
    'adresse': adresse,
    'latitude': latitude,
    'longitude': longitude,
    'fahrzeuge': fahrzeuge.map((f) => f.toJson()).toList(),
    'erstelltAm': erstelltAm.toIso8601String(),
    'beendetAm': beendetAm?.toIso8601String(),
    'notizen': notizen,
    'atemschutzZeiten': atemschutzZeiten,
    'atemschutzProtokoll': atemschutzProtokoll?.map((e) => e.toJson()).toList(),
  };

  factory Einsatz.fromJson(Map<String, dynamic> json) {
    final zeitParts = (json['uhrzeit'] as String).split(':');
    return Einsatz(
      id: json['id'] as String,
      einsatzart: json['einsatzart'] as String,
      datum: DateTime.parse(json['datum'] as String),
      uhrzeit: TimeOfDay(
        hour: int.parse(zeitParts[0]),
        minute: int.parse(zeitParts[1]),
      ),
      adresse: json['adresse'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      fahrzeuge: (json['fahrzeuge'] as List?)
          ?.map((f) => Fahrzeug.fromJson(f as Map<String, dynamic>))
          .toList() ??
          [],
      erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      beendetAm: json['beendetAm'] != null ? DateTime.parse(json['beendetAm'] as String) : null,
      notizen: json['notizen'] as String?,
      atemschutzZeiten: (json['atemschutzZeiten'] as Map?)?.cast<String, int>(),
      atemschutzProtokoll: (json['atemschutzProtokoll'] as List?)
          ?.map((e) => AtemschutzEintrag.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String toFormattedString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
