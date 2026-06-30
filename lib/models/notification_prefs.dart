/// Preferências de notificação configuráveis pelo usuário na tela de
/// Configurações > Notificações. Persistidas dentro do estado principal.
class NotificationPrefs {
  // Lembrete ANTES da tarefa (ex: "em 10 minutos")
  bool taskReminderBefore;
  int taskReminderMinutesBefore;

  // Notificação NA HORA EXATA da tarefa, com botão de ação "Concluir"
  bool taskReminderAtTime;

  // Tarefas não concluídas no fim do dia
  bool endOfDayReminder;
  int endOfDayHour;
  int endOfDayMinute;

  // Resumo semanal de metas
  bool weeklyMetaSummary;

  // Aviso antes de dormir
  bool sleepReminder;
  int sleepReminderMinutesBefore;

  // Saudação no horário de acordar
  bool goodMorning;

  // BUG 17 fix: campo próprio para feedback háptico ao marcar tarefa.
  // Antes estava mapeado erroneamente em taskReminderAtTime, o que ativava
  // as notificações na hora exata sem o usuário saber.
  bool hapticFeedback;

  NotificationPrefs({
    this.taskReminderBefore = true,
    this.taskReminderMinutesBefore = 10,
    this.taskReminderAtTime = false,
    this.endOfDayReminder = true,
    this.endOfDayHour = 21,
    this.endOfDayMinute = 30,
    this.weeklyMetaSummary = false,
    this.sleepReminder = false,
    this.sleepReminderMinutesBefore = 30,
    this.goodMorning = true,
    this.hapticFeedback = true,
  });

  Map<String, dynamic> toJson() => {
        'taskReminderBefore': taskReminderBefore,
        'taskReminderMinutesBefore': taskReminderMinutesBefore,
        'taskReminderAtTime': taskReminderAtTime,
        'endOfDayReminder': endOfDayReminder,
        'endOfDayHour': endOfDayHour,
        'endOfDayMinute': endOfDayMinute,
        'weeklyMetaSummary': weeklyMetaSummary,
        'sleepReminder': sleepReminder,
        'sleepReminderMinutesBefore': sleepReminderMinutesBefore,
        'goodMorning': goodMorning,
        'hapticFeedback': hapticFeedback,
      };

  factory NotificationPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NotificationPrefs();
    return NotificationPrefs(
      taskReminderBefore: json['taskReminderBefore'] as bool? ?? true,
      taskReminderMinutesBefore: (json['taskReminderMinutesBefore'] as num?)?.toInt() ?? 10,
      taskReminderAtTime: json['taskReminderAtTime'] as bool? ?? false,
      endOfDayReminder: json['endOfDayReminder'] as bool? ?? true,
      endOfDayHour: (json['endOfDayHour'] as num?)?.toInt() ?? 21,
      endOfDayMinute: (json['endOfDayMinute'] as num?)?.toInt() ?? 30,
      weeklyMetaSummary: json['weeklyMetaSummary'] as bool? ?? false,
      sleepReminder: json['sleepReminder'] as bool? ?? false,
      sleepReminderMinutesBefore: (json['sleepReminderMinutesBefore'] as num?)?.toInt() ?? 30,
      goodMorning: json['goodMorning'] as bool? ?? true,
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
    );
  }
}
