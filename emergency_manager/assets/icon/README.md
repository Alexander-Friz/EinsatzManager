# App Icon

## So setzt du ein App-Icon:

### 1. Icon-Bild vorbereiten
- **Format:** PNG (mit transparentem Hintergrund empfohlen)
- **Größe:** Mindestens 1024x1024 Pixel (quadratisch)
- **Dateiname:** `app_icon.png`
- **Speicherort:** Lege die Datei in diesen Ordner: `assets/icon/app_icon.png`

### 2. Icon generieren
Nach dem Hinzufügen der Icon-Datei, führe folgende Befehle aus:

```bash
flutter pub get
dart run flutter_launcher_icons
```

### 3. App neu bauen
```bash
flutter clean
flutter build apk  # Für Android
# oder
flutter build ios  # Für iOS
```

### Icon-Design-Tipps:
- Verwende ein klares, erkennbares Symbol
- Für Feuerwehr-App: 🚒 Feuerwehrauto, Helm, oder Flammen-Symbol
- Vermeide zu viele Details (Icons sind klein)
- Teste auf hellem und dunklem Hintergrund

### Kostenlose Icon-Quellen:
- Flaticon.com
- Icons8.com
- Freepik.com
- Canva.com (Icon-Generator)
