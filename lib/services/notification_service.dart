import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import '../models/task.dart';

const String _kStateKey = 'rotina_state';
const String _actionComplete = 'task_complete_action';

/// Callback de notificação acionável: roda às vezes num isolate de
/// background separado (app fechado), então NÃO pode depender do Provider
/// ou de qualquer estado em memória — só lê/escreve direto no
/// SharedPreferences, do mesmo jeito que o AppState faz.
///
/// Precisa ser uma função top-level (não método de classe) e marcada com
/// @pragma('vm:entry-point') para o Android conseguir invocá-la mesmo com
/// o app encerrado.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  _handleNotificationResponse(response);
}

Future<void> _handleNotificationResponse(NotificationResponse response) async {
  if (response.actionId != _actionComplete) return;
  final payload = response.payload;
  if (payload == null || !payload.startsWith('task:')) return;

  final parts = payload.split(':');
  if (parts.length < 2) return;
  final taskId = int.tryParse(parts[1]);
  if (taskId == null) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStateKey);
    if (raw == null) return;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final tasksJson = (map['tasks'] as List?) ?? [];

    bool changed = false;
    for (final t in tasksJson) {
      final taskMap = t as Map<String, dynamic>;
      if ((taskMap['id'] as num?)?.toInt() == taskId) {
        taskMap['done'] = true;
        changed = true;
        break;
      }
    }
    if (changed) {
      map['tasks'] = tasksJson;
      await prefs.setString(_kStateKey, jsonEncode(map));
    }
  } catch (_) {
    // se algo der errado aqui, melhor falhar silenciosamente do que
    // travar o isolate de notificação
  }

  // Remove a notificação da bandeja após marcar como concluída.
  if (response.id != null) {
    await FlutterLocalNotificationsPlugin().cancel(response.id!);
  }
}

/// Centraliza toda a lógica de notificações locais do app: inicialização,
/// pedido de permissão e agendamento de lembretes de tarefas e de sono.
///
/// Estratégia: em vez de tentar mapear cada padrão de recorrência (semana,
/// mês, ano) para uma regra nativa do Android, reagendamos diariamente as
/// notificações dos próximos 2 dias com base nas tarefas que realmente
/// ocorrem naquela data (via Task.recurrence.matchesDate). Isso é chamado
/// sempre que o app abre e sempre que tarefas/preferências mudam.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Callback chamado quando o app está em primeiro plano e recebe uma
  /// notificação tocada (ou ação tocada). Setado pelo widget raiz para
  /// poder atualizar o Provider em tempo real (sem precisar reabrir o app).
  void Function(int taskId)? onTaskMarkedDoneInForeground;

  // IDs de notificação reservados para os lembretes "fixos" (não por tarefa).
  static const int _idEndOfDay = 900001;
  static const int _idSleepReminder = 900002;
  static const int _idGoodMorning = 900003;
  static const int _idWeeklyMetaSummary = 900004;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {
      // se o nome da timezone não for reconhecido no dispositivo, mantém UTC
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'rotina_tarefas',
        'Lembretes de tarefas',
        description: 'Avisos antes e na hora de uma tarefa da rotina',
        importance: Importance.high,
      ),
    );
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        'rotina_geral',
        'Sono e metas',
        description: 'Lembretes de sono, resumo de metas e tarefas pendentes',
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  /// Quando o app está aberto (primeiro plano) e o usuário toca na ação
  /// "Concluir", processa igual ao background, mas também avisa a UI
  /// (via [onTaskMarkedDoneInForeground]) para refletir na hora.
  void _onForegroundResponse(NotificationResponse response) {
    _handleNotificationResponse(response);
    if (response.actionId == _actionComplete && response.payload != null) {
      final parts = response.payload!.split(':');
      if (parts.length >= 2) {
        final taskId = int.tryParse(parts[1]);
        if (taskId != null) onTaskMarkedDoneInForeground?.call(taskId);
      }
    }
  }

  /// Pede permissão de notificação (Android 13+) e de alarme exato.
  /// Retorna true se a permissão de notificação foi concedida.
  Future<bool> requestPermissions() async {
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    return granted ?? true;
  }

  Future<bool> areNotificationsEnabled() async {
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.areNotificationsEnabled() ?? false;
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Reagenda TODOS os lembretes com base nas preferências atuais.
  /// Chamar sempre que: o app inicia, uma tarefa muda, ou uma preferência
  /// de notificação é alterada na tela de Configurações.
  Future<void> rescheduleAll({
    required List<Task> tasks,
    required bool taskReminderBefore,
    required int taskReminderMinutesBefore,
    required bool taskReminderAtTime,
    required bool endOfDayReminder,
    required int endOfDayHour,
    required int endOfDayMinute,
    required bool sleepReminder,
    required int sleepReminderMinutesBefore,
    required String sleepTime, // 'HH:mm'
    required bool goodMorning,
    required String wakeTime, // 'HH:mm'
    required bool weeklyMetaSummary,
  }) async {
    await init();
    await _plugin.cancelAll();

    if (taskReminderBefore || taskReminderAtTime) {
      await _scheduleTaskReminders(
        tasks,
        beforeEnabled: taskReminderBefore,
        minutesBefore: taskReminderMinutesBefore,
        atTimeEnabled: taskReminderAtTime,
      );
    }
    if (endOfDayReminder) {
      await _scheduleDaily(
        id: _idEndOfDay,
        hour: endOfDayHour,
        minute: endOfDayMinute,
        title: 'Como foi seu dia?',
        body: 'Dá uma olhada nas tarefas que ainda não marcou.',
        channel: 'rotina_geral',
      );
    }
    if (sleepReminder) {
      final t = _parseTime(sleepTime);
      final reminderTime = _subtractMinutes(t, sleepReminderMinutesBefore);
      await _scheduleDaily(
        id: _idSleepReminder,
        hour: reminderTime.$1,
        minute: reminderTime.$2,
        title: 'Quase hora de dormir',
        body: sleepReminderMinutesBefore > 0
            ? 'Faltam $sleepReminderMinutesBefore minutos para o seu horário de dormir.'
            : 'Está na hora de dormir.',
        channel: 'rotina_geral',
      );
    }
    if (goodMorning) {
      final t = _parseTime(wakeTime);
      await _scheduleDaily(
        id: _idGoodMorning,
        hour: t.$1,
        minute: t.$2,
        title: 'Bom dia! ☀️',
        body: 'Vamos começar o dia com o pé direito.',
        channel: 'rotina_geral',
      );
    }
    if (weeklyMetaSummary) {
      await _scheduleWeekly(
        id: _idWeeklyMetaSummary,
        weekday: DateTime.monday,
        hour: 9,
        minute: 0,
        title: 'Resumo semanal de metas',
        body: 'Confira como foi sua semana e o progresso das suas metas.',
        channel: 'rotina_geral',
      );
    }
  }

  /// Agenda lembretes de tarefas para os próximos 2 dias (hoje e amanhã):
  /// um aviso ANTES do horário (se [beforeEnabled]) e/ou uma notificação
  /// NA HORA EXATA com botão de ação "Concluir" (se [atTimeEnabled]).
  Future<void> _scheduleTaskReminders(
    List<Task> tasks, {
    required bool beforeEnabled,
    required int minutesBefore,
    required bool atTimeEnabled,
  }) async {
    final now = DateTime.now();
    for (int dayOffset = 0; dayOffset < 2; dayOffset++) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));
      for (final task in tasks) {
        if (!task.recurrence.matchesDate(date)) continue;
        final parts = task.time.split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final taskTime = DateTime(date.year, date.month, date.day, hour, minute);

        if (beforeEnabled) {
          final notifyAt = taskTime.subtract(Duration(minutes: minutesBefore));
          if (!notifyAt.isBefore(now)) {
            await _scheduleOnce(
              id: _taskNotificationId(task.id, dayOffset, isAtTime: false),
              when: notifyAt,
              title: task.name,
              body: minutesBefore > 0
                  ? 'Está chegando a hora — em $minutesBefore minutos.'
                  : 'Está na hora.',
              channel: 'rotina_tarefas',
            );
          }
        }

        if (atTimeEnabled && !taskTime.isBefore(now)) {
          await _scheduleOnce(
            id: _taskNotificationId(task.id, dayOffset, isAtTime: true),
            when: taskTime,
            title: task.name,
            body: 'É agora! Toque em Concluir quando terminar.',
            channel: 'rotina_tarefas',
            payload: 'task:${task.id}:${_dateKey(date)}',
            withCompleteAction: true,
          );
        }
      }
    }
  }

  int _taskNotificationId(int taskId, int dayOffset, {required bool isAtTime}) =>
      100000 + (taskId % 40000) * 4 + dayOffset * 2 + (isAtTime ? 1 : 0);

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  (int, int) _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 23;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return (h, m);
  }

  (int, int) _subtractMinutes((int, int) time, int minutes) {
    int totalMinutes = time.$1 * 60 + time.$2 - minutes;
    totalMinutes = ((totalMinutes % 1440) + 1440) % 1440; // wrap 0-1439
    return (totalMinutes ~/ 60, totalMinutes % 60);
  }

  Future<void> _scheduleOnce({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String channel,
    String? payload,
    bool withCompleteAction = false,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      _detailsFor(channel, withCompleteAction: withCompleteAction),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channel,
  }) async {
    final when = _nextInstanceOf(hour, minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _detailsFor(channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int weekday, // DateTime.monday..sunday
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channel,
  }) async {
    var when = _nextInstanceOf(hour, minute);
    while (when.weekday != weekday) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _detailsFor(channel),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  NotificationDetails _detailsFor(String channel, {bool withCompleteAction = false}) {
    final isTask = channel == 'rotina_tarefas';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        isTask ? 'Lembretes de tarefas' : 'Sono e metas',
        importance: isTask ? Importance.high : Importance.defaultImportance,
        priority: isTask ? Priority.high : Priority.defaultPriority,
        actions: withCompleteAction
            ? const [
                AndroidNotificationAction(
                  _actionComplete,
                  'Concluir',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
    );
  }
}
