import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/task_list_item.dart';
import '../widgets/add_edit_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/day_timeline.dart';
import '../widgets/pickers.dart';

class HojeScreen extends StatelessWidget {
  const HojeScreen({super.key});

  String _getTimeGreeting(String name) {
    final h = DateTime.now().hour;
    final greetings = <String, List<String>>{
      'dawn': [
        'Ei, $name... descansar faz bem.',
        'Madrugada produtiva, $name?',
      ],
      'morning': [
        'Bom dia, $name! Vai um café?',
        'Bom dia, $name! Vamos com disposição hoje!',
        'Oi, $name! Que seu dia comece leve.',
      ],
      'afternoon': [
        'Boa tarde, $name! Mantendo o foco?',
        'Ei, $name! Já deu um tempinho de pausa?',
        'Boa tarde, $name! Meio dia é hora de render.',
      ],
      'evening': [
        'Boa noite, $name! Como foi seu dia?',
        'Ei, $name! Hora de revisar o que fez hoje.',
      ],
      'night': [
        'Boa noite, $name! Quase hora de descansar.',
        'Tá tarde, $name! Não esquece de dormir cedo.',
      ],
    };
    List<String> pool;
    if (h >= 0 && h < 5) {
      pool = greetings['dawn']!;
    } else if (h >= 5 && h < 12) {
      pool = greetings['morning']!;
    } else if (h >= 12 && h < 18) {
      pool = greetings['afternoon']!;
    } else if (h >= 18 && h < 21) {
      pool = greetings['evening']!;
    } else {
      pool = greetings['night']!;
    }
    return pool[DateTime.now().millisecond % pool.length];
  }

  String _getTimeSub() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Sua manhã começa aqui. ☕';
    if (h >= 12 && h < 18) return 'Aproveite bem a tarde. 🌤️';
    if (h >= 18 && h < 21) return 'Revisando o dia. 🌙';
    return 'Descanse bem depois.';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final tasks = state.todayTasks;
    final todaySleep = state.getTodaySleep();
    final done = tasks.where((t) => t.done).length;
    final total = tasks.length;
    final pct = total > 0 ? (done / total * 100).round() : 0;

    Color barColor;
    if (pct >= 80) {
      barColor = c.green;
    } else if (pct >= 40) {
      barColor = c.orange;
    } else {
      barColor = c.red;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        if (state.userName.isNotEmpty)
          AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTimeGreeting(state.userName),
                  style: AppFonts.inter(color: c.cream, fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(_getTimeSub(), style: AppFonts.inter(color: c.textMuted, fontSize: 12)),
              ],
            ),
          ),

        // Barra de progresso do dia
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progresso do dia',
                      style: AppFonts.inter(color: c.textSoft, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('$pct%',
                      style: AppFonts.inter(color: c.cream, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  minHeight: 8,
                  backgroundColor: c.surface,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
              const SizedBox(height: 6),
              Text('$done de $total tarefas concluídas',
                  style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
            ],
          ),
        ),

        // Timeline 24h
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardTitle('Timeline do dia'),
              DayTimeline(sleep: todaySleep, tasks: tasks),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.nightlight_round, size: 11, color: c.purple),
                          const SizedBox(width: 4),
                          Text('Dormi às', style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        _sleepTimeButton(context, c, todaySleep.start, (val) async {
                          await state.setTodaySleepField(start: val);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.wb_sunny_outlined, size: 11, color: c.gold),
                          const SizedBox(width: 4),
                          Text('Acordei às', style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        _sleepTimeButton(context, c, todaySleep.end, (val) async {
                          await state.setTodaySleepField(end: val);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SectionLabel('Tarefas de hoje'),
        AppCard(
          child: tasks.isEmpty
              ? const EmptyState(emoji: '🌿', text: 'Nenhuma tarefa hoje')
              : Column(
                  children: tasks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    final metaList = t.linkedMeta != null
                        ? state.metas.where((m) => m.id == t.linkedMeta).toList()
                        : const [];
                    final meta = metaList.isNotEmpty ? metaList.first : null;
                    return TaskListItem(
                      task: t,
                      linkedMeta: meta,
                      showBorder: i != tasks.length - 1,
                      onToggle: () => state.toggleTask(t.id),
                      onEdit: () => showAddEditSheet(context, editingTask: t),
                      onDelete: () => showAppConfirm(
                        context,
                        title: 'Excluir tarefa?',
                        body: '"${t.name}" será removida permanentemente.',
                        confirmLabel: 'Sim, excluir',
                        onConfirm: () => state.deleteTask(t.id),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _sleepTimeButton(
      BuildContext context, AppColors c, String value, ValueChanged<String> onChanged) {
    return InkWell(
      onTap: () async {
        final r = await showTimePickerSheet(context, initialTime: value);
        if (r != null) onChanged(r);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: AppFonts.inter(color: c.text, fontSize: 13)),
            Icon(Icons.access_time, size: 12, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
