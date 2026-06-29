import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_prefs.dart';
import '../../services/app_state.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import 'config_common.dart';

class ConfigNotificacoesScreen extends StatefulWidget {
  const ConfigNotificacoesScreen({super.key});

  @override
  State<ConfigNotificacoesScreen> createState() => _ConfigNotificacoesScreenState();
}

class _ConfigNotificacoesScreenState extends State<ConfigNotificacoesScreen> {
  bool? _systemEnabled; // null = ainda não checado

  @override
  void initState() {
    super.initState();
    _checkSystemPermission();
  }

  Future<void> _checkSystemPermission() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() => _systemEnabled = enabled);
  }

  Future<void> _toggle(AppState state, void Function(_PrefsBuilder b) apply) async {
    final builder = _PrefsBuilder(state.notifPrefs);
    apply(builder);
    await state.updateNotificationPrefs(builder.build());
    if (_systemEnabled == false) {
      await NotificationService.instance.requestPermissions();
      _checkSystemPermission();
    }
  }

  String _fmtHourMinute(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final p = state.notifPrefs;

    return ConfigSubScaffold(
      title: 'Notificações',
      children: [
        if (_systemEnabled == false)
          AppCard(
            child: Row(
              children: [
                Icon(Icons.notifications_off_outlined, size: 18, color: c.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'As notificações estão desativadas para o Rotina. nas configurações do sistema. Os lembretes abaixo não vão aparecer até você reativar.',
                    style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Lembretes de tarefas'),
              CfgRow(
                label: 'Avisar antes da tarefa',
                sub: '${p.taskReminderMinutesBefore} minutos de antecedência',
                trailing: CfgToggle(
                  value: p.taskReminderBefore,
                  onChanged: (v) => _toggle(state, (b) => b.taskReminderBefore = v),
                ),
              ),
              if (p.taskReminderBefore) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15, 30, 60].map((m) {
                    final selected = p.taskReminderMinutesBefore == m;
                    return ChoiceChip(
                      label: Text(m < 60 ? '${m}min' : '1h'),
                      selected: selected,
                      onSelected: (_) => _toggle(state, (b) => b.taskReminderMinutesBefore = m),
                      selectedColor: c.creamSoft.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: selected ? c.creamSoft : c.textMuted,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.border),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
              CfgRow(
                label: 'Avisar na hora exata',
                sub: 'Notificação com botão de Concluir',
                showBorder: false,
                trailing: CfgToggle(
                  value: p.taskReminderAtTime,
                  onChanged: (v) => _toggle(state, (b) => b.taskReminderAtTime = v),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Fim do dia'),
              CfgRow(
                label: 'Tarefas não concluídas',
                sub: 'Lembrar no horário abaixo',
                trailing: CfgToggle(
                  value: p.endOfDayReminder,
                  onChanged: (v) => _toggle(state, (b) => b.endOfDayReminder = v),
                ),
              ),
              if (p.endOfDayReminder) ...[
                const SizedBox(height: 8),
                _timeTrigger(c, _fmtHourMinute(p.endOfDayHour, p.endOfDayMinute), () async {
                  final r = await showTimePickerSheet(
                    context,
                    initialTime: _fmtHourMinute(p.endOfDayHour, p.endOfDayMinute),
                    title: 'Horário do lembrete',
                  );
                  if (r != null) {
                    final parts = r.split(':');
                    _toggle(state, (b) {
                      b.endOfDayHour = int.parse(parts[0]);
                      b.endOfDayMinute = int.parse(parts[1]);
                    });
                  }
                }),
              ],
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Metas'),
              CfgRow(
                label: 'Progresso semanal',
                sub: 'Resumo toda segunda às 9h',
                showBorder: false,
                trailing: CfgToggle(
                  value: p.weeklyMetaSummary,
                  onChanged: (v) => _toggle(state, (b) => b.weeklyMetaSummary = v),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Sono'),
              CfgRow(
                label: 'Hora de dormir',
                sub: '${p.sleepReminderMinutesBefore} minutos antes do seu horário',
                trailing: CfgToggle(
                  value: p.sleepReminder,
                  onChanged: (v) => _toggle(state, (b) => b.sleepReminder = v),
                ),
              ),
              if (p.sleepReminder) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [10, 15, 30, 45, 60].map((m) {
                    final selected = p.sleepReminderMinutesBefore == m;
                    return ChoiceChip(
                      label: Text(m < 60 ? '${m}min' : '1h'),
                      selected: selected,
                      onSelected: (_) => _toggle(state, (b) => b.sleepReminderMinutesBefore = m),
                      selectedColor: c.creamSoft.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: selected ? c.creamSoft : c.textMuted,
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.border),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
              ],
              CfgRow(
                label: 'Bom dia',
                sub: 'Saudação no seu horário de acordar',
                showBorder: false,
                trailing: CfgToggle(
                  value: p.goodMorning,
                  onChanged: (v) => _toggle(state, (b) => b.goodMorning = v),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeTrigger(AppColors c, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: AppFonts.inter(color: c.text, fontSize: 14)),
            Icon(Icons.access_time, size: 13, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Helper interno para aplicar uma mudança pontual nas prefs sem precisar
/// escrever um copyWith gigante repetido em cada toggle.
class _PrefsBuilder {
  bool taskReminderBefore;
  int taskReminderMinutesBefore;
  bool taskReminderAtTime;
  bool endOfDayReminder;
  int endOfDayHour;
  int endOfDayMinute;
  bool weeklyMetaSummary;
  bool sleepReminder;
  int sleepReminderMinutesBefore;
  bool goodMorning;

  _PrefsBuilder(NotificationPrefs p)
      : taskReminderBefore = p.taskReminderBefore,
        taskReminderMinutesBefore = p.taskReminderMinutesBefore,
        taskReminderAtTime = p.taskReminderAtTime,
        endOfDayReminder = p.endOfDayReminder,
        endOfDayHour = p.endOfDayHour,
        endOfDayMinute = p.endOfDayMinute,
        weeklyMetaSummary = p.weeklyMetaSummary,
        sleepReminder = p.sleepReminder,
        sleepReminderMinutesBefore = p.sleepReminderMinutesBefore,
        goodMorning = p.goodMorning;

  NotificationPrefs build() => NotificationPrefs(
        taskReminderBefore: taskReminderBefore,
        taskReminderMinutesBefore: taskReminderMinutesBefore,
        taskReminderAtTime: taskReminderAtTime,
        endOfDayReminder: endOfDayReminder,
        endOfDayHour: endOfDayHour,
        endOfDayMinute: endOfDayMinute,
        weeklyMetaSummary: weeklyMetaSummary,
        sleepReminder: sleepReminder,
        sleepReminderMinutesBefore: sleepReminderMinutesBefore,
        goodMorning: goodMorning,
      );
}
