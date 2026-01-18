import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Message {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final String type; // 'warning', 'info', 'error'
  bool isRead;

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'isRead': isRead,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: json['type'] as String,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class MessageNotifier extends ChangeNotifier {
  List<Message> _messages = [];
  late SharedPreferences _prefs;
  bool _isLoaded = false;

  List<Message> get messages => _messages;
  List<Message> get unreadMessages => _messages.where((m) => !m.isRead).toList();
  int get unreadCount => unreadMessages.length;
  bool get isLoaded => _isLoaded;

  // Stelle sicher, dass _prefs initialisiert ist
  Future<void> _ensurePrefsInitialized() async {
    if (!_isLoaded) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> loadMessages() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs.getString('messages_list');
    
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _messages = jsonList
          .map((item) => Message.fromJson(item as Map<String, dynamic>))
          .toList();
      _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveMessages() async {
    await _ensurePrefsInitialized();
    final jsonList = _messages.map((msg) => msg.toJson()).toList();
    await _prefs.setString('messages_list', jsonEncode(jsonList));
  }

  Future<void> addMessage(Message message) async {
    _messages.insert(0, message);
    await _saveMessages();
    notifyListeners();
  }

  Future<void> markAsRead(String messageId) async {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index >= 0) {
      _messages[index].isRead = true;
      await _saveMessages();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    _messages.removeWhere((m) => m.id == messageId);
    await _saveMessages();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _messages.clear();
    await _saveMessages();
    notifyListeners();
  }

  // AGT-spezifische Nachricht hinzufügen
  Future<void> addAGTExaminationWarning(String personName) async {
    final message = Message(
      id: DateTime.now().toString(),
      title: 'AGT Untersuchung abgelaufen',
      content:
          'Die G26.3 Untersuchung von $personName ist abgelaufen. Bitte umgehend erneuern!',
      timestamp: DateTime.now(),
      type: 'warning',
    );
    await addMessage(message);
  }

  // TÜV-spezifische Nachricht hinzufügen
  Future<void> addTuevWarning(String vehicleName, String tuevType) async {
    final message = Message(
      id: DateTime.now().toString(),
      title: '$tuevType von $vehicleName abgelaufen',
      content:
          'Der $tuevType des Fahrzeugs $vehicleName ist abgelaufen. Bitte umgehend erneuern!',
      timestamp: DateTime.now(),
      type: 'warning',
    );
    await addMessage(message);
  }
}
