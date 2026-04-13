import 'dart:convert';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../care/care_repository.dart';
import '../medication/medication_repository.dart';
import '../shared/app_utils.dart';

const String _markDoneActionId = 'mark_done';
const String _snoozeActionId = 'snooze_10';
const String _medicationCategoryId = 'medication_actions';
const String _careCategoryId = 'care_actions';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.handleNotificationResponse(notificationResponse);
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService._();

  // ─── Bildirim kanalları ───────────────────────────────────────────────────
  static const _vaccineChannel = AndroidNotificationChannel(
    'vaccine_channel',
    'Aşı Hatırlatmaları',
    description: 'Yaklaşan aşı tarihleri için hatırlatmalar',
    importance: Importance.high,
  );
  static const _medicationChannel = AndroidNotificationChannel(
    'medication_channel',
    'İlaç Hatırlatmaları',
    description: 'Günlük ilaç hatırlatmaları',
    importance: Importance.high,
  );
  static const _vetChannel = AndroidNotificationChannel(
    'vet_channel',
    'Veteriner Hatırlatmaları',
    description: 'Veteriner randevu hatırlatmaları',
    importance: Importance.high,
  );
  static const _careChannel = AndroidNotificationChannel(
    'care_channel',
    'Bakım Hatırlatmaları',
    description: 'Mama, su ve rutin bakım hatırlatmaları',
    importance: Importance.high,
  );

  static final _medicationActions = DarwinNotificationCategory(
    _medicationCategoryId,
    actions: <DarwinNotificationAction>[
      DarwinNotificationAction.plain(_markDoneActionId, 'Tamamlandı'),
      DarwinNotificationAction.plain(_snoozeActionId, 'Ertele 10 dk'),
    ],
  );

  static final _careActions = DarwinNotificationCategory(
    _careCategoryId,
    actions: <DarwinNotificationAction>[
      DarwinNotificationAction.plain(_markDoneActionId, 'Tamamlandı'),
      DarwinNotificationAction.plain(_snoozeActionId, 'Ertele 10 dk'),
    ],
  );

  // ─── Başlatma ─────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: <DarwinNotificationCategory>[
        _medicationActions,
        _careActions,
      ],
    );

    await _plugin.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android kanallarını oluştur
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_vaccineChannel);
    await androidPlugin?.createNotificationChannel(_medicationChannel);
    await androidPlugin?.createNotificationChannel(_vetChannel);
    await androidPlugin?.createNotificationChannel(_careChannel);

    _initialized = true;
  }

  // ─── İzin iste ────────────────────────────────────────────────────────────
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    final macosGranted = await macos?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    return androidGranted && iosGranted && macosGranted;
  }

  // ─── Aşı bildirimi ────────────────────────────────────────────────────────
  /// [daysBefor]: kaç gün önce hatırlatılsın (1, 3, 7)
  Future<void> scheduleVaccineReminder({
    required int id,
    required String petName,
    required String vaccineName,
    required DateTime dueDate,
    TimeOfDay? time,
    int daysBefore = 3,
  }) async {
    await init();
    final dueWithTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
    final notifyAt = dueWithTime.subtract(Duration(days: daysBefore));
    if (notifyAt.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '💉 Aşı Hatırlatması — $petName',
      '$vaccineName aşısının zamanı yaklaşıyor ($daysBefore gün kaldı)',
      _toTZ(notifyAt),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _vaccineChannel.id,
          _vaccineChannel.name,
          channelDescription: _vaccineChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── İlaç bildirimi ───────────────────────────────────────────────────────
  Future<void> scheduleMedicationReminder({
    required int id,
    required String medicationId,
    required String petName,
    required String medicationName,
    required String dosage,
    required TimeOfDay time,
  }) async {
    await init();
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day,
        time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '💊 İlaç Zamanı — $petName',
      '$medicationName · $dosage',
      _toTZ(scheduled),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _medicationChannel.id,
          _medicationChannel.name,
          channelDescription: _medicationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(_markDoneActionId, 'Tamamlandı'),
            AndroidNotificationAction(_snoozeActionId, 'Ertele 10 dk'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _medicationCategoryId,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({
        'type': 'medication',
        'id': id,
        'entityId': medicationId,
      }),
    );
  }

  // ─── Veteriner bildirimi ──────────────────────────────────────────────────
  Future<void> scheduleVetReminder({
    required int id,
    required String petName,
    required String reason,
    required DateTime visitDate,
    TimeOfDay? time,
    int daysBefore = 1,
  }) async {
    await init();
    final visitWithTime = DateTime(
      visitDate.year,
      visitDate.month,
      visitDate.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
    final notifyAt = visitWithTime.subtract(Duration(days: daysBefore));
    if (notifyAt.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '🏥 Veteriner Randevusu — $petName',
      '$reason ($daysBefore gün kaldı)',
      _toTZ(notifyAt),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _vetChannel.id,
          _vetChannel.name,
          channelDescription: _vetChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleCareReminder({
    required int id,
    required String petName,
    required String taskTitle,
    required DateTime dueDate,
    required String taskId,
    TimeOfDay? time,
  }) async {
    await init();
    final dueWithTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      time?.hour ?? 9,
      time?.minute ?? 0,
    );
    if (dueWithTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      '🫧 Bakım Zamanı — $petName',
      taskTitle,
      _toTZ(dueWithTime),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _careChannel.id,
          _careChannel.name,
          channelDescription: _careChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(_markDoneActionId, 'Tamamlandı'),
            AndroidNotificationAction(_snoozeActionId, 'Ertele 10 dk'),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: _careCategoryId,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({
        'type': 'care',
        'id': id,
        'entityId': taskId,
      }),
    );
  }

  // ─── İptal ────────────────────────────────────────────────────────────────
  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  // ─── ID üreteci ──────────────────────────────────────────────────────────
  /// String id'yi integer'a dönüştürür (UUID'nin son 8 karakteri)
  static int idFromString(String s) =>
      s.hashCode.abs() % 2000000000;

  static TimeOfDay? parseReminderTime(String? value) => parseTimeOfDay(value);

  static Future<void> handleNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final payload = notificationResponse.payload;
    if (payload == null || payload.isEmpty) return;
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final type = map['type'] as String?;
    final entityId = map['entityId'] as String?;
    if (type == null || entityId == null) return;

    if (notificationResponse.actionId == _snoozeActionId) {
      await instance._handleSnoozeAction(type: type, entityId: entityId);
      return;
    }

    if (notificationResponse.actionId != _markDoneActionId) return;

    if (type == 'medication') {
      final repository = MedicationRepository();
      final medication = await repository.getById(entityId);
      if (medication != null) {
        await repository.markMedicationStatus(
          medication: medication,
          scheduledDate: DateTime.now(),
          taken: true,
        );
      }
      return;
    }

    if (type == 'care') {
      final repository = CareRepository();
      final task = await repository.getById(entityId);
      if (task != null) {
        final completedAt = DateTime.now();
        await repository.markCompleted(task.id, completedAt);
        await NotificationService.instance.cancel(idFromString(task.id));
        if (task.reminderEnabled && task.isActive) {
          final dueDate = nextCareDueDate(
            startDate: task.startDate,
            lastCompletedAt: completedAt,
            frequency: task.frequency,
          );
          await NotificationService.instance.scheduleCareReminder(
            id: idFromString(task.id),
            petName: 'Evcil hayvanın',
            taskTitle: task.title,
            dueDate: dueDate,
            taskId: task.id,
            time: parseReminderTime(task.reminderTime),
          );
        }
      }
    }
  }

  Future<void> _handleSnoozeAction({
    required String type,
    required String entityId,
  }) async {
    final snoozeAt = DateTime.now().add(const Duration(minutes: 10));

    if (type == 'medication') {
      final repository = MedicationRepository();
      final medication = await repository.getById(entityId);
      if (medication == null) return;
      await repository.markMedicationStatus(
        medication: medication,
        scheduledDate: DateTime.now(),
        taken: false,
        note: 'Bugün atlandı',
      );
      return;
    }

    if (type == 'care') {
      final repository = CareRepository();
      final task = await repository.getById(entityId);
      if (task == null) return;
      final skippedUntil = DateTime(
        snoozeAt.year,
        snoozeAt.month,
        snoozeAt.day,
      );
      await repository.skipUntil(task.id, skippedUntil);
      await instance.cancel(idFromString(task.id));
      await instance.scheduleCareReminder(
        id: idFromString(task.id),
        petName: 'Evcil hayvanın',
        taskTitle: task.title,
        dueDate: skippedUntil,
        taskId: task.id,
        time: parseReminderTime(task.reminderTime),
      );
    }
  }

  // ─── Yardımcı ─────────────────────────────────────────────────────────────
  tz.TZDateTime _toTZ(DateTime dt) {
    final local = tz.local;
    return tz.TZDateTime(
        local, dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }
}
