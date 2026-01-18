import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android Initialisierung
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    // iOS Initialisierung
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification response
      },
    );

    // Berechtigungen müssen in AndroidManifest.xml konfiguriert werden
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'emergency_manager_channel',
      'Emergency Manager Notifications',
      channelDescription:
          'Benachrichtigungen fuer abgelaufene AGT-Untersuchungen und TÜVs',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showAGTWarning(String personName) async {
    await showNotification(
      id: personName.hashCode,
      title: 'AGT Untersuchung abgelaufen',
      body: 'Die G26.3 Untersuchung von $personName ist abgelaufen!',
    );
  }

  Future<void> showTuevWarning(String vehicleName, String tuevType) async {
    await showNotification(
      id: '$vehicleName$tuevType'.hashCode,
      title: '$tuevType von $vehicleName abgelaufen',
      body: 'Bitte erneuern Sie den $tuevType umgehend!',
    );
  }
}
