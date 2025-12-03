# EinsatzManager

Eine professionelle Feuerwehr-Einsatz-Management-App für Echtzeit-Einsatzverwaltung und Koordination.

## Features

✅ **Einsatzverwaltung**
- Neue Einsätze erstellen mit Titel, Typ, Priorität und Adresse
- Einsatzstatus verwalten (Ausstehend → Aktiv → Abgeschlossen)
- Prioritätsbasierte Sortierung (Hoch, Mittel, Niedrig)

✅ **Einsatztypen**
- Brand
- Verkehrsunfall
- Rettung
- Gefahrengut
- Medizinisch
- Technisch
- Sonstiges

✅ **Personal Management**
- Personal zu Einsätzen zuweisen
- Zugewiesene Personen verwalten
- Einsatzleiter festlegen

✅ **Einsatzdetails**
- Vollständige Informationen anzeigen
- Notizen hinzufügen und bearbeiten
- Einsatzdauer automatisch berechnen

✅ **Übersichtliche Oberfläche**
- Tab-basierte Navigation (Aktiv, Ausstehend, Abgeschlossen)
- Feuerwehr-typisches rotes Design
- Responsive und benutzerfreundliche UI

## Installation

```bash
# Dependencies installieren
flutter pub get

# App starten
flutter run
```

## Anforderungen

- Flutter SDK >= 3.10.1
- Dart SDK >= 3.10.1

## Dependencies

- **provider**: State Management
- **intl**: Internationalisierung und Datumsformatierung
- **uuid**: UUID-Generierung
- **shared_preferences**: Lokale Datenspeicherung (optional, für zukünftige Features)

## Projektstruktur

```
lib/
├── main.dart              # App-Einstiegspunkt
├── models/
│   └── einsatz.dart      # Einsatz-Datenmodell
├── services/
│   └── einsatz_service.dart  # Business Logic
├── screens/
│   ├── home_screen.dart           # Startseite mit Tabs
│   ├── einsatz_detail_screen.dart # Einsatzdetails
│   └── new_einsatz_screen.dart    # Neuen Einsatz erstellen
└── widgets/              # Wiederverwendbare Widgets
```

## Zukünftige Features

🔄 **Geplant**
- Google Maps Integration für Einsatzort
- GPS-basierte Standortverfolgung
- Lokale Datenspeicherung mit Synchronisation
- Offline-Modus
- Benachrichtigungen für neue Einsätze
- Einsatzhistorie und Statistiken
- Export zu PDF/Excel
- Multi-User Support mit Authentifizierung

## Getting Started

1. **Neue Einsatz erstellen**: Drücken Sie die "+" Schaltfläche
2. **Einsatz öffnen**: Tippen Sie auf eine Einsatzkarte
3. **Status ändern**: Nutzen Sie die Status-Buttons in den Details
4. **Personal zuweisen**: Namen hinzufügen im Personal-Bereich
5. **Notizen hinzufügen**: Im Notizen-Feld Details dokumentieren

## Lizenz

Dieses Projekt ist privat und nicht für die öffentliche Nutzung lizenziert.

## Support

Bei Fragen oder Problemen bitte kontaktieren.

