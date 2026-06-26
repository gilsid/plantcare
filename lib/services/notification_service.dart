import 'package:flutter/foundation.dart';
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
    if (kIsWeb) {
      debugPrint('[NotificationService] init: skipped on Web');
      return;
    }
    debugPrint('[NotificationService] init: initializing timezones...');
    try {
      tz.initializeTimeZones();
      debugPrint('[NotificationService] init: timezones initialized');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] init: timezone initialization FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

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

    debugPrint('[NotificationService] init: initializing plugin...');
    try {
      await _notificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('[NotificationService] notification response: ${details.payload}');
        },
      );
      debugPrint('[NotificationService] init: plugin initialized');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] init: plugin initialize FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    debugPrint('[NotificationService] init: creating notification channels...');
    try {
      await _createNotificationChannels();
      debugPrint('[NotificationService] init: channels created');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] init: channel creation FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation == null) {
      debugPrint('[NotificationService] _createNotificationChannels: no Android implementation (iOS/macOS)');
      return;
    }

    debugPrint('[NotificationService] _createNotificationChannels: creating channels...');

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

    try {
      await androidImplementation.createNotificationChannel(wateringChannel);
      debugPrint('[NotificationService] _createNotificationChannels: watering channel created');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] _createNotificationChannels: watering channel FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await androidImplementation.createNotificationChannel(fertilizingChannel);
      debugPrint('[NotificationService] _createNotificationChannels: fertilizing channel created');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] _createNotificationChannels: fertilizing channel FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    try {
      await androidImplementation.createNotificationChannel(otherChannel);
      debugPrint('[NotificationService] _createNotificationChannels: other channel created');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] _createNotificationChannels: other channel FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    debugPrint('[NotificationService] requestPermissions: requesting Android notification permission...');

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    bool? grantedNotification;
    try {
      grantedNotification = await androidImplementation
          ?.requestNotificationsPermission();
      debugPrint('[NotificationService] requestPermissions: notification permission -> $grantedNotification');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] requestPermissions: notification permission FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    bool? grantedFullScreenIntent;
    try {
      grantedFullScreenIntent = await androidImplementation
          ?.requestFullScreenIntentPermission();
      debugPrint('[NotificationService] requestPermissions: fullScreenIntent permission -> $grantedFullScreenIntent');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] requestPermissions: fullScreenIntent permission FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    bool? iOSGranted;
    try {
      iOSGranted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint('[NotificationService] requestPermissions: iOS permission -> $iOSGranted');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] requestPermissions: iOS permission FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    final result = (grantedNotification ?? false) ||
        (grantedFullScreenIntent ?? false) ||
        (iOSGranted ?? false);
    debugPrint('[NotificationService] requestPermissions: overall result -> $result');
    return result;
  }

  int _getNotificationId(String plantId, CareType careType) {
    final String key = '$plantId-${careType.index}';
    int hash = 2166136261;
    for (int i = 0; i < key.length; i++) {
      hash ^= key.codeUnitAt(i);
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toSigned(31);
  }

  Future<void> scheduleCareReminder({
    required String plantId,
    required String plantName,
    required CareType careType,
    required DateTime nextDueDate,
  }) async {
    if (kIsWeb) return;
    final int id = _getNotificationId(plantId, careType);
    debugPrint('[NotificationService] scheduleCareReminder: id=$id plant=$plantName type=$careType nextDueDate=$nextDueDate');

    debugPrint('[NotificationService] scheduleCareReminder: cancelling existing reminder...');
    try {
      await cancelCareReminder(plantId, careType);
      debugPrint('[NotificationService] scheduleCareReminder: existing reminder cancelled');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] scheduleCareReminder: cancel FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    final now = DateTime.now();
    var scheduledDateTime = nextDueDate;

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = now.add(const Duration(seconds: 10));
      debugPrint('[NotificationService] scheduleCareReminder: date in past, rescheduled to $scheduledDateTime');
    }

    debugPrint('[NotificationService] scheduleCareReminder: converting to TZDateTime...');
    tz.TZDateTime tzScheduledDate;
    try {
      tzScheduledDate = tz.TZDateTime.from(
        scheduledDateTime,
        tz.local,
      );
      debugPrint('[NotificationService] scheduleCareReminder: TZDateTime=$tzScheduledDate timezone=${tz.local.name}');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] scheduleCareReminder: TZDateTime conversion FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    final (String channelId, String title, String body, String soundName) =
        _getNotificationContent(careType, plantName);

    final (String chId, String chName, String chDesc) = _getChannelInfo(careType);

    debugPrint('[NotificationService] scheduleCareReminder: building AndroidNotificationDetails...');
    AndroidNotificationDetails androidDetails;
    try {
      androidDetails = AndroidNotificationDetails(
        chId,
        chName,
        channelDescription: chDesc,
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('watering_alarm'),
        vibrationPattern: Int64List.fromList([0, 500, 300, 500, 300, 1000]),
        fullScreenIntent: true,
      );
      debugPrint('[NotificationService] scheduleCareReminder: AndroidNotificationDetails built');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] scheduleCareReminder: AndroidNotificationDetails FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      return;
    }

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    debugPrint('[NotificationService] scheduleCareReminder: calling zonedSchedule...');
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('[NotificationService] scheduleCareReminder: ✅ SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] scheduleCareReminder: ❌ zonedSchedule FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
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
    if (kIsWeb) return;
    final int id = _getNotificationId(plantId, careType);
    debugPrint('[NotificationService] cancelCareReminder: cancelling id=$id for plant=$plantId type=$careType');
    try {
      await _notificationsPlugin.cancel(id: id);
      debugPrint('[NotificationService] cancelCareReminder: ✅ cancelled id=$id');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] cancelCareReminder: ❌ cancel FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> cancelAllReminders() async {
    if (kIsWeb) return;
    debugPrint('[NotificationService] cancelAllReminders: cancelling all...');
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('[NotificationService] cancelAllReminders: ✅ all cancelled');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] cancelAllReminders: ❌ cancelAll FAILED: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  (String, String, String) _getChannelInfo(CareType careType) {
    switch (careType) {
      case CareType.watering:
        return (
          _wateringChannelId,
          'Pengingat Penyiraman',
          'Notifikasi untuk mengingatkan Anda menyiram tanaman',
        );
      case CareType.fertilizing:
        return (
          _fertilizingChannelId,
          'Pengingat Pemupukan',
          'Notifikasi untuk mengingatkan Anda memupuk tanaman',
        );
      case CareType.pruning:
      case CareType.pestCheck:
      case CareType.repotting:
        return (
          _otherChannelId,
          'Pengingat Perawatan Lainnya',
          'Notifikasi untuk pengingat perawatan tanaman lainnya',
        );
    }
  }
}
