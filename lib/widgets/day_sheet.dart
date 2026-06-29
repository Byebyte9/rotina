import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/day_data.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'pickers.dart';

/// Abre o sheet de detalhes de um dia (status, nota, sono, tarefas).
/// Equivalente a `openDaySheet()` / `saveDaySheet()` no JS.
Future<void> showDaySheet(BuildContext context, {DateTime? date}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _DaySheet(date: date ?? DateTime.now()),
  );
}

class _DaySheet extends StatefulWidget {
  final DateTime date;
  const _DaySheet({required this.date});

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  late bool isToday;
  late String dateKey;
  late TextEditingController noteCtrl;
  String sleepStart = '23:00';
  String sleepEnd = '07:00';
  String dot = '';
  late DayData dayData;
  late Map<int, bool> taskDoneOverride; // para tarefas de dias passados

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final now = DateTime.now();
    isToday = _isSameDay(widget.date, now);
    dateKey = state.fmtDateKey(widget.date);
    dayData = state.getDayData(dateKey);
    noteCtrl = TextEditingController(text: dayData.note);

    if (isToday) {
      final todaySleep = state.getTodaySleep();
      sleepStart = todaySleep.start;
      sleepEnd = todaySleep.end;
    } else {
      sleepStart = dayData.sleep?.start ?? state.sleep.start;
      sleepEnd = dayData.sleep?.end ?? state.sleep.end;
    }

    dot = dayData.dot.isNotEmpty ? dayData.dot : (isToday ? _computeTodayDot(state) : '');
    taskDoneOverride = {for (final id in dayData.tasksDone) id: true};
  }

  @override
  void dispose() {
    noteCtrl.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _computeTodayDot(AppState state) {
    final tasks = state.todayTasks;
    if (tasks.isEmpty) return '';
    final pct = tasks.where((t) => t.done).length / tasks.length;
    return pct >= 0.8 ? 'green' : (pct >= 0.3 ? 'orange' : 'red');
  }

  Future<void> _save() async {
    final state = context.read<AppState>();

    // Salva tudo do dia (nota, status, sono e tarefas) numa única escrita.
    // O sono fica registrado SÓ neste dia — nunca sobrescreve o padrão global.
    final newData = DayData(
      note: noteCtrl.text,
      dot: dot,
      sleep: SleepData(start: sleepStart, end: sleepEnd),
      tasksDone: taskDoneOverride.entries.where((e) => e.value).map((e) => e.key).toList(),
    );
    await state.saveDayData(dateKey, newData);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final title = isToday
        ? 'Hoje'
        : _capitalize(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(widget.date));

    // Bug 10 fix: usa getTasksForDate para dias passados, que respeita
    // a recorrência de cada tarefa corretamente (incluindo tarefas únicas
    // que existiam naquele dia, não só as recorrentes).
    final tasks = isToday
        ? state.todayTasks
        : state.getTasksForDate(widget.date);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title, style: AppFonts.playfair(color: c.cream, fontSize: 18)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 16, color: c.textMuted),
                    style: IconButton.styleFrom(
                      backgroundColor: c.card,
                      side: BorderSide(color: c.border),
                      minimumSize: const Size(30, 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label(c, 'Como foi o dia'),
              Row(
                children: [
                  _dotOption(c, 'green', 'Ótimo', c.green),
                  const SizedBox(width: 8),
                  _dotOption(c, 'orange', 'Parcial', c.orange),
                  const SizedBox(width: 8),
                  _dotOption(c, 'red', 'Difícil', c.red),
                ],
              ),
              const SizedBox(height: 14),
              _label(c, 'Nota rápida'),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: AppFonts.inter(color: c.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Como foi? O que aconteceu...',
                  hintStyle: AppFonts.inter(color: c.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: c.card,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.creamSoft),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _label(c, 'Sono'),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.nightlight_round, size: 11, color: c.purple),
                          const SizedBox(width: 4),
                          Text('Dormi às',
                              style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        _timeTrigger(c, sleepStart, () async {
                          final r = await showTimePickerSheet(context,
                              initialTime: sleepStart, title: 'Dormi às');
                          if (r != null) setState(() => sleepStart = r);
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
                          Text('Acordei às',
                              style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        _timeTrigger(c, sleepEnd, () async {
                          final r = await showTimePickerSheet(context,
                              initialTime: sleepEnd, title: 'Acordei às');
                          if (r != null) setState(() => sleepEnd = r);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label(c, 'Tarefas'),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nenhuma tarefa',
                      style: AppFonts.inter(color: c.textMuted, fontSize: 12)),
                )
              else
                ...tasks.map((t) {
                  final isDone = isToday ? t.done : (taskDoneOverride[t.id] ?? false);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            if (isToday) {
                              await state.toggleTask(t.id);
                              setState(() {});
                            } else {
                              setState(() {
                                taskDoneOverride[t.id] = !isDone;
                              });
                            }
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isDone ? c.green : Colors.transparent,
                              border: Border.all(color: isDone ? c.green : c.border, width: 2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isDone
                                ? const Icon(Icons.check, size: 13, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.name,
                            style: AppFonts.inter(
                              color: isDone ? c.textMuted : c.text,
                              fontSize: 13,
                            ).copyWith(decoration: isDone ? TextDecoration.lineThrough : null),
                          ),
                        ),
                        Text(t.time, style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.creamSoft,
                    foregroundColor: c.bg,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(AppColors c, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Text(
          text.toUpperCase(),
          style: AppFonts.inter(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)
              .copyWith(letterSpacing: 1),
        ),
      );

  Widget _dotOption(AppColors c, String key, String label, Color color) {
    final selected = dot == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => dot = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : c.card,
            border: Border.all(color: selected ? color : c.border, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: AppFonts.inter(
                    color: selected ? color : c.textMuted,
                    fontSize: 11,
                  )),
            ],
          ),
        ),
      ),
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

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
