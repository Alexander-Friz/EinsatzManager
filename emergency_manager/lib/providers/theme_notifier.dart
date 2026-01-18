import 'package:flutter/material.dart';
import 'dart:async';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isAutoScheduleEnabled = false;
  int _darkModeStartHour = 21;
  int _darkModeEndHour = 6;
  Timer? _scheduleTimer;

  bool get isDarkMode => _isDarkMode;
  bool get isAutoScheduleEnabled => _isAutoScheduleEnabled;
  int get darkModeStartHour => _darkModeStartHour;
  int get darkModeEndHour => _darkModeEndHour;

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setAutoSchedule(bool value) {
    _isAutoScheduleEnabled = value;
    if (value) {
      _checkAndApplySchedule();
      _startScheduleTimer();
    } else {
      _stopScheduleTimer();
    }
    notifyListeners();
  }

  void setDarkModeStartHour(int hour) {
    _darkModeStartHour = hour;
    if (_isAutoScheduleEnabled) {
      _checkAndApplySchedule();
    }
    notifyListeners();
  }

  void setDarkModeEndHour(int hour) {
    _darkModeEndHour = hour;
    if (_isAutoScheduleEnabled) {
      _checkAndApplySchedule();
    }
    notifyListeners();
  }

  void _checkAndApplySchedule() {
    final now = DateTime.now();
    final hour = now.hour;
    
    bool shouldBeDarkMode;
    
    // Dark mode zwischen eingestellter Startzeit und Endzeit
    if (_darkModeStartHour < _darkModeEndHour) {
      // Normal: z.B. 14:00 - 18:00
      shouldBeDarkMode = hour >= _darkModeStartHour && hour < _darkModeEndHour;
    } else {
      // Über Mitternacht: z.B. 21:00 - 06:00
      shouldBeDarkMode = hour >= _darkModeStartHour || hour < _darkModeEndHour;
    }
    
    if (_isDarkMode != shouldBeDarkMode) {
      _isDarkMode = shouldBeDarkMode;
      notifyListeners();
    }
  }

  void _startScheduleTimer() {
    _stopScheduleTimer();
    // Überprüfe jede Minute, ob der Dark Mode aktiviert/deaktiviert werden soll
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkAndApplySchedule();
    });
  }

  void _stopScheduleTimer() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
  }

  void updateScheduleIfNeeded() {
    if (_isAutoScheduleEnabled) {
      _checkAndApplySchedule();
    }
  }

  @override
  void dispose() {
    _stopScheduleTimer();
    super.dispose();
  }
}

