import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/enums.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _wateringChannelId = 'watering_reminders';
  static const String _fertilizingChannelId = 'fertilizing_reminders';
  static const String _otherChannelId = 'other_care_reminders';

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation == null) return;

    final wateringChannel = AndroidNotificationChannel(
      _wateringChannelId,
      'Pengingat Penyiraman',
      description: 'Notifikasi untuk mengingatkan Anda menyiram tanaman',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('watering_alarm'),
      enableVibration: true,
    );

    final fertilizingChannel = AndroidNotificationChannel(
      _fertilizingChannelId,
      'Pengingat Pemupukan',
      description: 'Notifikasi untuk mengingatkan Anda memupuk tanaman',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('watering_alarm'),
      enableVibration: true,
    );

    final otherChannel = AndroidNotificationChannel(
      _otherChannelId,
      'Pengingat Perawatan Lainnya',
      description: 'Notifikasi untuk pengingat perawatan tanaman lainnya',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation.createNotificationChannel(wateringChannel);
    await androidImplementation.createNotificationChannel(fertilizingChannel);
    await androidImplementation.createNotificationChannel(otherChannel);
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    final bool? grantedNotification = await androidImplementation
        ?.requestNotificationsPermission();

    final bool? grantedFullScreenIntent = await androidImplementation
        ?.requestFullScreenIntentPermission();

    final bool? iOSGranted = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return (grantedNotification ?? false) ||
        (grantedFullScreenIntent ?? false) ||
        (iOSGranted ?? false);
  }

  int _getNotificationId(String plantId, CareType careType) {
    return plantId.hashCode ^ (careType.index * 31);
  }

  Future<void> scheduleCareReminder({
    required String plantId,
    required String plantName,
    required CareType careType,
    required DateTime nextDueDate,
  }) async {
    final int id = _getNotificationId(plantId, careType);

    await cancelCareReminder(plantId, careType);

    final now = DateTime.now();
    var scheduledDateTime = nextDueDate;

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = now.add(const Duration(seconds: 10));
    }

    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      scheduledDateTime,
      tz.local,
    );

    final (String channelId, String title, String body, String soundName) =
        _getNotificationContent(careType, plantName);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          title,
          channelDescription: body,
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('watering_alarm'),
          vibrationPattern: Int64List.fromList([0, 500, 300, 500, 300, 1000]),
          fullScreenIntent: true,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  (String, String, String, String) _getNotificationContent(
    CareType careType,
    String plantName,
  ) {
    switch (careType) {
      case CareType.watering:
        return (
          _wateringChannelId,
          'Waktunya Menyiram Tanaman!',
          'Jangan lupa siram $plantName sekarang',
          'watering_alarm',
        );
      case CareType.fertilizing:
        return (
          _fertilizingChannelId,
          'Waktunya Memupuk Tanaman!',
          'Jangan lupa beri pupuk untuk $plantName',
          'watering_alarm',
        );
      case CareType.pruning:
        return (
          _otherChannelId,
          'Waktunya Memangkas Tanaman!',
          'Jangan lupa pangkas $plantName',
          'watering_alarm',
        );
      case CareType.pestCheck:
        return (
          _otherChannelId,
          'Cek Hama Tanaman!',
          'Periksa apakah ada hama pada $plantName',
          'watering_alarm',
        );
      case CareType.repotting:
        return (
          _otherChannelId,
          'Waktunya Ganti Pot!',
          '$plantName perlu dipindahkan ke pot yang lebih besar',
          'watering_alarm',
        );
    }
  }

  Future<void> cancelCareReminder(String plantId, CareType careType) async {
    final int id = _getNotificationId(plantId, careType);
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
  }
}
