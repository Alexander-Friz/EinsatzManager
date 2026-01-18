class ProtocolEntry {
  final String text;
  final DateTime timestamp;
  final String? imageBase64; // Bild als Base64 kodierter String (optional)

  ProtocolEntry({
    required this.text,
    required this.timestamp,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'imageBase64': imageBase64,
    };
  }

  factory ProtocolEntry.fromJson(Map<String, dynamic> json) {
    return ProtocolEntry(
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageBase64: json['imageBase64'] as String?,
    );
  }
}

class RespiratoryTrupp {
  final String angriffstrupp; // Name des Angriffstrupps
  final String sicherungstrupp; // "Wassertrupp" oder "Schlauchtrupp"

  RespiratoryTrupp({
    required this.angriffstrupp,
    required this.sicherungstrupp,
  });

  Map<String, dynamic> toJson() {
    return {
      'angriffstrupp': angriffstrupp,
      'sicherungstrupp': sicherungstrupp,
    };
  }

  factory RespiratoryTrupp.fromJson(Map<String, dynamic> json) {
    return RespiratoryTrupp(
      angriffstrupp: json['angriffstrupp'] as String,
      sicherungstrupp: json['sicherungstrupp'] as String,
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
  // vehicleId -> RespiratoryTrupp
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
      'respiratoryActive': respiratoryActive,
      'vehicleBreathingApparatus': vehicleBreathingApparatus.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory Operation.fromJson(Map<String, dynamic> json) {
    final protocolList = json['protocol'] as List?;
    final breathingApparatusList = json['vehicleBreathingApparatus'] as Map? ?? {};
    return Operation(
      id: json['id'],
      alarmstichwort: json['alarmstichwort'],
      adresseOrGps: json['adresseOrGps'],
      vehicleIds: List<String>.from(json['vehicleIds'] ?? []),
      vehicleNames: List<String>.from(json['vehicleNames'] ?? json['vehicleIds'] ?? []),
      vehiclePersonnelAssignment: Map<String, Map<String, String>>.from(
        (json['vehiclePersonnelAssignment'] as Map? ?? {}).map(
          (key, value) => MapEntry(
            key,
            Map<String, String>.from(value as Map? ?? {}),
          ),
        ),
      ),
      einsatzTime: DateTime.parse(json['einsatzTime'] as String),
      protocol: protocolList != null
          ? protocolList
              .map((entry) => ProtocolEntry.fromJson(entry as Map<String, dynamic>))
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
