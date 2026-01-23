class ProtocolEntry {
  final String text;
  final DateTime timestamp;
  final String? imageBase64; // Bild als Base64 kodierter String (optional)
  final String? audioPath; // Pfad zur Audioaufnahme (optional)

  ProtocolEntry({
    required this.text,
    required this.timestamp,
    this.imageBase64,
    this.audioPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'imageBase64': imageBase64,
      'audioPath': audioPath,
    };
  }

  factory ProtocolEntry.fromJson(Map<String, dynamic> json) {
    return ProtocolEntry(
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageBase64: json['imageBase64'] as String?,
      audioPath: json['audioPath'] as String?,
    );
  }
}

class AtemschutzTrupp {
  final String id; // Eindeutige ID für den Trupp
  final String name; // Name des Trupps (z.B. "Angriffstrupp", "Wassertrupp")
  final String?
  vehicleId; // Fahzeug-ID wenn fahrzeuggebunden, null wenn Großschadenslagen
  final String person1Id; // ID der ersten Person
  final String person2Id; // ID der zweiten Person
  final DateTime createdAt; // Zeitstempel für Sortierung
  final DateTime? startTime; // Startzeitpunkt der Stoppuhr
  final Duration? pausedDuration; // Akkumulierte Pausenzeit
  final int? lowestPressure; // Niedrigster Druck in bar
  final bool isActive; // Ob die Stoppuhr läuft
  final bool pressure10MinChecked; // Ob Druckabfrage bei 10 Min erfolgt ist
  final bool pressure20MinChecked; // Ob Druckabfrage bei 20 Min erfolgt ist
  final bool isCompleted; // Ob der Einsatz beendet wurde
  final int roundNumber; // Durchgangsnummer (1 oder 2)

  AtemschutzTrupp({
    required this.name,
    this.vehicleId,
    required this.person1Id,
    required this.person2Id,
    DateTime? createdAt,
    String? id,
    this.startTime,
    this.pausedDuration,
    this.lowestPressure,
    this.isActive = false,
    this.pressure10MinChecked = false,
    this.pressure20MinChecked = false,
    this.isCompleted = false,
    this.roundNumber = 1,
  }) : id =
           id ??
           '${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond)}',
       createdAt = createdAt ?? DateTime.now();

  bool get isVehicleLinked => vehicleId != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'vehicleId': vehicleId,
      'person1Id': person1Id,
      'person2Id': person2Id,
      'createdAt': createdAt.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'pausedDuration': pausedDuration?.inSeconds,
      'lowestPressure': lowestPressure,
      'isActive': isActive,
      'pressure10MinChecked': pressure10MinChecked,
      'pressure20MinChecked': pressure20MinChecked,
      'isCompleted': isCompleted,
      'roundNumber': roundNumber,
    };
  }

  factory AtemschutzTrupp.fromJson(Map<String, dynamic> json) {
    return AtemschutzTrupp(
      id: json['id'] as String? ?? 'unknown',
      name: json['name'] as String,
      vehicleId: json['vehicleId'] as String?,
      person1Id: json['person1Id'] as String,
      person2Id: json['person2Id'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      pausedDuration: json['pausedDuration'] != null
          ? Duration(seconds: json['pausedDuration'] as int)
          : null,
      lowestPressure: json['lowestPressure'] as int?,
      isActive: json['isActive'] as bool? ?? false,
      pressure10MinChecked: json['pressure10MinChecked'] as bool? ?? false,
      pressure20MinChecked: json['pressure20MinChecked'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      roundNumber: json['roundNumber'] as int? ?? 1,
    );
  }

  AtemschutzTrupp copyWith({
    String? name,
    String? vehicleId,
    String? person1Id,
    String? person2Id,
    DateTime? createdAt,
    DateTime? startTime,
    Duration? pausedDuration,
    int? lowestPressure,
    bool? isActive,
    bool? pressure10MinChecked,
    bool? pressure20MinChecked,
    bool? isCompleted,
    int? roundNumber,
  }) {
    return AtemschutzTrupp(
      id: id,
      name: name ?? this.name,
      vehicleId: vehicleId ?? this.vehicleId,
      person1Id: person1Id ?? this.person1Id,
      person2Id: person2Id ?? this.person2Id,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      lowestPressure: lowestPressure ?? this.lowestPressure,
      isActive: isActive ?? this.isActive,
      pressure10MinChecked: pressure10MinChecked ?? this.pressure10MinChecked,
      pressure20MinChecked: pressure20MinChecked ?? this.pressure20MinChecked,
      isCompleted: isCompleted ?? this.isCompleted,
      roundNumber: roundNumber ?? this.roundNumber,
    );
  }
}

class RespiratoryTrupp {
  final String
  name; // Name des Trupps (z.B. "Angriffstrupp", "Wassertrupp" oder GS-Name)
  final String? person1Id; // Erste Person im Trupp (optional)
  final String? person2Id; // Zweite Person im Trupp (optional)
  final DateTime createdAt; // Zeitstempel für Sortierung

  RespiratoryTrupp({
    required this.name,
    this.person1Id,
    this.person2Id,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'person1Id': person1Id,
      'person2Id': person2Id,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RespiratoryTrupp.fromJson(Map<String, dynamic> json) {
    return RespiratoryTrupp(
      name:
          json['name'] as String? ??
          json['angriffstrupp'] as String? ??
          'Unbekannt',
      person1Id: json['person1Id'] as String?,
      person2Id: json['person2Id'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

class Operation {
  final String? id;
  final String alarmstichwort;
  final String adresseOrGps;
  final List<String> vehicleIds;
  final List<String> vehicleNames;
  // vehicleId -> { personelId -> trupp/function }
  final Map<String, Map<String, String>> vehiclePersonnelAssignment;
  final DateTime einsatzTime;
  final List<ProtocolEntry> protocol;
  final bool respiratoryActive;
  // Liste von Atemschutztrupps
  final List<AtemschutzTrupp> atemschutzTrupps;
  // vehicleId -> RespiratoryTrupp (deprecated, für Rückwärtskompatibilität)
  final Map<String, RespiratoryTrupp> vehicleBreathingApparatus;

  Operation({
    this.id,
    required this.alarmstichwort,
    required this.adresseOrGps,
    required this.vehicleIds,
    required this.vehicleNames,
    required this.vehiclePersonnelAssignment,
    required this.einsatzTime,
    this.protocol = const [],
    this.respiratoryActive = false,
    this.atemschutzTrupps = const [],
    this.vehicleBreathingApparatus = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alarmstichwort': alarmstichwort,
      'adresseOrGps': adresseOrGps,
      'vehicleIds': vehicleIds,
      'vehicleNames': vehicleNames,
      'vehiclePersonnelAssignment': vehiclePersonnelAssignment,
      'einsatzTime': einsatzTime.toIso8601String(),
      'protocol': protocol.map((entry) => entry.toJson()).toList(),
      'atemschutzTrupps': atemschutzTrupps
          .map((trupp) => trupp.toJson())
          .toList(),
      'respiratoryActive': respiratoryActive,
      'vehicleBreathingApparatus': vehicleBreathingApparatus.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory Operation.fromJson(Map<String, dynamic> json) {
    final protocolList = json['protocol'] as List?;
    final atemschutzTruppsList = json['atemschutzTrupps'] as List?;
    final breathingApparatusList =
        json['vehicleBreathingApparatus'] as Map? ?? {};
    return Operation(
      id: json['id'],
      alarmstichwort: json['alarmstichwort'],
      adresseOrGps: json['adresseOrGps'],
      vehicleIds: List<String>.from(json['vehicleIds'] ?? []),
      vehicleNames: List<String>.from(
        json['vehicleNames'] ?? json['vehicleIds'] ?? [],
      ),
      vehiclePersonnelAssignment: Map<String, Map<String, String>>.from(
        (json['vehiclePersonnelAssignment'] as Map? ?? {}).map(
          (key, value) =>
              MapEntry(key, Map<String, String>.from(value as Map? ?? {})),
        ),
      ),
      einsatzTime: DateTime.parse(json['einsatzTime'] as String),
      protocol: protocolList != null
          ? protocolList
                .map(
                  (entry) =>
                      ProtocolEntry.fromJson(entry as Map<String, dynamic>),
                )
                .toList()
          : [],
      atemschutzTrupps: atemschutzTruppsList != null
          ? atemschutzTruppsList
                .map(
                  (entry) =>
                      AtemschutzTrupp.fromJson(entry as Map<String, dynamic>),
                )
                .toList()
          : [],
      respiratoryActive: json['respiratoryActive'] as bool? ?? false,
      vehicleBreathingApparatus: Map<String, RespiratoryTrupp>.from(
        (breathingApparatusList).map(
          (key, value) => MapEntry(
            key,
            RespiratoryTrupp.fromJson(value as Map<String, dynamic>),
          ),
        ),
      ),
    );
  }
}
