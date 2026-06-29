import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../models/notification_prefs.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'config_common.dart';

class ConfigProdutividadeScreen extends StatelessWidget {
  const ConfigProdutividadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final prefs = state.notifPrefs;

    return ConfigSubScaffold(
      title: 'Produtividade',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              CfgSectionTitle('Método Pomodoro'),
              CfgRow(label: 'Duração do foco', sub: 'Tempo de cada sessão', trailing: CfgValue('25 min')),
              CfgRow(label: 'Pausa curta', sub: 'Entre sessões', trailing: CfgValue('5 min')),
              CfgRow(label: 'Pausa longa', sub: 'A cada 4 sessões', showBorder: false, trailing: CfgValue('15 min')),
            ],
          ),
        ),
        // Bug 8 fix: toggles conectados ao NotificationPrefs real
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Comportamento das tarefas'),
              CfgRow(
                label: 'Resetar tarefas diárias',
                sub: 'Às meia-noite automaticamente',
                // Este comportamento é fixo (reset acontece sempre no load)
                trailing: const CfgValue('Sempre ativo'),
              ),
              CfgRow(
                label: 'Vibrar ao completar',
                sub: 'Feedback háptico ao marcar tarefa',
                showBorder: false,
                trailing: CfgToggle(
                  value: prefs.taskReminderAtTime,
                  onChanged: (val) {
                    final updated = NotificationPrefs(
                      taskReminderBefore: prefs.taskReminderBefore,
                      taskReminderMinutesBefore: prefs.taskReminderMinutesBefore,
                      taskReminderAtTime: val,
                      endOfDayReminder: prefs.endOfDayReminder,
                      endOfDayHour: prefs.endOfDayHour,
                      endOfDayMinute: prefs.endOfDayMinute,
                      weeklyMetaSummary: prefs.weeklyMetaSummary,
                      sleepReminder: prefs.sleepReminder,
                      sleepReminderMinutesBefore: prefs.sleepReminderMinutesBefore,
                      goodMorning: prefs.goodMorning,
                    );
                    state.updateNotificationPrefs(updated);
                  },
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Streaks'),
              CfgRow(
                label: 'Resumo semanal de metas',
                sub: 'Notificação todo domingo',
                showBorder: false,
                trailing: CfgToggle(
                  value: prefs.weeklyMetaSummary,
                  onChanged: (val) {
                    final updated = NotificationPrefs(
                      taskReminderBefore: prefs.taskReminderBefore,
                      taskReminderMinutesBefore: prefs.taskReminderMinutesBefore,
                      taskReminderAtTime: prefs.taskReminderAtTime,
                      endOfDayReminder: prefs.endOfDayReminder,
                      endOfDayHour: prefs.endOfDayHour,
                      endOfDayMinute: prefs.endOfDayMinute,
                      weeklyMetaSummary: val,
                      sleepReminder: prefs.sleepReminder,
                      sleepReminderMinutesBefore: prefs.sleepReminderMinutesBefore,
                      goodMorning: prefs.goodMorning,
                    );
                    state.updateNotificationPrefs(updated);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
