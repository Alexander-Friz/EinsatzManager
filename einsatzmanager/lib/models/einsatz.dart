import 'package:intl/intl.dart';

enum EinsatzStatus {
  pending('Ausstehend'),
  active('Aktiv'),
  completed('Abgeschlossen'),
  cancelled('Storniert');

  final String label;
  const EinsatzStatus(this.label);
}

enum EinsatzPriority {
  low('Niedrig', 3),
  medium('Mittel', 2),
  high('Hoch', 1);

  final String label;
  final int priority;
  const EinsatzPriority(this.label, this.priority);
}

enum EinsatzType {
  fire('Brand'),
  accident('Verkehrsunfall'),
  rescue('Rettung'),
  hazmat('Gefahrengut'),
  medical('Medizinisch'),
  technical('Technisch'),
  other('Sonstiges');

  final String label;
  const EinsatzType(this.label);
}

class Einsatz {
  final String id;
  final String title;
  final String description;
  final EinsatzType type;
  final EinsatzStatus status;
  final EinsatzPriority priority;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> assignedPersonnel;
  final String? commanderName;
  final String? notes;

  Einsatz({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.priority,
    required this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.assignedPersonnel = const [],
    this.commanderName,
    this.notes,
  });

  // Kopieren mit Änderungen
  Einsatz copyWith({
    String? id,
    String? title,
    String? description,
    EinsatzType? type,
    EinsatzStatus? status,
    EinsatzPriority? priority,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? assignedPersonnel,
    String? commanderName,
    String? notes,
  }) {
    return Einsatz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      assignedPersonnel: assignedPersonnel ?? this.assignedPersonnel,
      commanderName: commanderName ?? this.commanderName,
      notes: notes ?? this.notes,
    );
  }

  // JSON Serialisierung
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'status': status.name,
    'priority': priority.name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'assignedPersonnel': assignedPersonnel,
    'commanderName': commanderName,
    'notes': notes,
  };

  factory Einsatz.fromJson(Map<String, dynamic> json) => Einsatz(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    type: EinsatzType.values.byName(json['type'] as String),
    status: EinsatzStatus.values.byName(json['status'] as String),
    priority: EinsatzPriority.values.byName(json['priority'] as String),
    address: json['address'] as String,
    latitude: json['latitude'] as double?,
    longitude: json['longitude'] as double?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
    assignedPersonnel: List<String>.from(json['assignedPersonnel'] as List? ?? []),
    commanderName: json['commanderName'] as String?,
    notes: json['notes'] as String?,
  );

  String get formattedCreatedAt {
    return DateFormat('dd.MM.yyyy HH:mm').format(createdAt);
  }

  String get duration {
    final end = completedAt ?? DateTime.now();
    final diff = end.difference(createdAt);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '$hours h $minutes min';
  }
}
