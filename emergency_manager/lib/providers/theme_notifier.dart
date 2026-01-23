import 'package:flutter/material.dart';
import 'dart:async';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isAutoScheduleEnabled = false;
  int _darkModeStartHour = 21;
  int _darkModeStartMinute = 0;
  int _darkModeEndHour = 6;
  int _darkModeEndMinute = 0;
  Timer? _scheduleTimer;

  bool get isDarkMode => _isDarkMode;
  bool get isAutoScheduleEnabled => _isAutoScheduleEnabled;
  int get darkModeStartHour => _darkModeStartHour;
  int get darkModeStartMinute => _darkModeStartMinute;
  int get darkModeEndHour => _darkModeEndHour;
  int get darkModeEndMinute => _darkModeEndMinute;

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

  void setDarkModeStartTime(int hour, int minute) {
    _darkModeStartHour = hour;
    _darkModeStartMinute = minute;
    if (_isAutoScheduleEnabled) {
      _checkAndApplySchedule();
    }
    notifyListeners();
  }

  void setDarkModeEndTime(int hour, int minute) {
    _darkModeEndHour = hour;
    _darkModeEndMinute = minute;
    if (_isAutoScheduleEnabled) {
      _checkAndApplySchedule();
    }
    notifyListeners();
  }

  void _checkAndApplySchedule() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = _darkModeStartHour * 60 + _darkModeStartMinute;
    final endMinutes = _darkModeEndHour * 60 + _darkModeEndMinute;
    
    bool shouldBeDarkMode;
    
    // Dark mode zwischen eingestellter Startzeit und Endzeit
    if (startMinutes < endMinutes) {
      // Normal: z.B. 14:00 - 18:00
      shouldBeDarkMode = currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Über Mitternacht: z.B. 21:00 - 06:00
      shouldBeDarkMode = currentMinutes >= startMinutes || currentMinutes < endMinutes;
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

