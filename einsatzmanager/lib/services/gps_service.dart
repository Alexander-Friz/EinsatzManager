import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsService {
  static final GpsService _instance = GpsService._internal();

  factory GpsService() {
    return _instance;
  }

  GpsService._internal();

  /// Überprüfe und fordere GPS-Berechtigungen an
  Future<bool> requestLocationPermission() async {
    try {
      debugPrint('GPS: Überprüfe Berechtigung...');
      
      final permission = await Geolocator.checkPermission();
      debugPrint('GPS: Aktueller Status: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('GPS: Berechtigung verweigert, fordere an...');
        final result = await Geolocator.requestPermission();
        debugPrint('GPS: Anfrage-Ergebnis: $result');
        
        if (result == LocationPermission.whileInUse || result == LocationPermission.always) {
          debugPrint('GPS: Berechtigung gewährt!');
          return true;
        } else {
          debugPrint('GPS: Berechtigung abgelehnt');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('GPS: Berechtigung permanent verweigert, öffne Einstellungen...');
        await Geolocator.openLocationSettings();
        return false;
      }
      
      debugPrint('GPS: Berechtigung bereits vorhanden');
      return true;
    } catch (e) {
      debugPrint('GPS Permission Error: $e');
      return false;
    }
  }

  /// Rufe die aktuelle Position ab
  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('GPS: Starte Position-Abruf...');
      
      // Überprüfe Berechtigung
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        debugPrint('GPS: Keine Berechtigung');
        return null;
      }

      // Überprüfe ob Location-Services aktiviert sind
      final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('GPS: Services aktiviert: $isLocationServiceEnabled');
      
      if (!isLocationServiceEnabled) {
        debugPrint('GPS: Location Services deaktiviert');
        await Geolocator.openLocationSettings();
        return null;
      }

      // Rufe aktuelle Position ab mit längerer Timeout
      debugPrint('GPS: Fordere Position an (30 Sekunden Timeout)...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      debugPrint('GPS: Position erhalten - ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('GPS Error: $e');
      rethrow;
    }
  }

  /// Konvertiere Koordinaten zu Addresse (Reverse Geocoding)
  /// Hinweis: Benötigt Geocoding Package
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Placeholder - In Zukunft mit Geocoding Package
      // z.B. mit google_maps_flutter oder geocoding Package
      return '$latitude, $longitude';
    } catch (e) {
      debugPrint('Geocoding Error: $e');
      return null;
    }
  }

  /// Berechne Distanz zwischen zwei Koordinaten in Meter
  static double getDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
