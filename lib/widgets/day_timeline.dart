import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/day_data.dart';
import '../theme/app_theme.dart';

/// Timeline visual de 24h — equivalente a `renderTimeline()` no JS.
/// Mostra o bloco de sono (lidando com virada de meia-noite), blocos de
/// tarefas (cor diferente se vinculada a meta) e a linha do "agora".
class DayTimeline extends StatelessWidget {
  final SleepData sleep;
  final List<Task> tasks;

  const DayTimeline({super.key, required this.sleep, required this.tasks});

  double _timeToFrac(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return (h * 60 + m) / 1440;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final now = DateTime.now();
    final nowFrac = (now.hour * 60 + now.minute) / 1440;

    final ss = _timeToFrac(sleep.start);
    final se = _timeToFrac(sleep.end);

    return LayoutBuilder(builder: (ctx, constraints) {
      final width = constraints.maxWidth;
      const height = 48.0;

      final blocks = <Widget>[];

      void addBlock(double left, double w, Color color, String label, {bool isSleep = false}) {
        if (w <= 0) return;
        blocks.add(Positioned(
          left: left * width,
          width: w * width,
          top: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: w > 0.08
                ? Text(
                    label,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: const TextStyle(fontSize: 9, color: Colors.white),
                  )
                : null,
          ),
        ));
      }

      // bloco de sono — lida com virada de meia-noite
      if (ss > se) {
        addBlock(ss, 1 - ss, c.purple.withValues(alpha: 0.55), '🌙', isSleep: true);
        addBlock(0, se, c.purple.withValues(alpha: 0.55), '🌙', isSleep: true);
      } else {
        addBlock(ss, se - ss, c.purple.withValues(alpha: 0.55), '🌙', isSleep: true);
      }

      // blocos de tarefa
      final sorted = [...tasks]..sort((a, b) => a.time.compareTo(b.time));
      for (final t in sorted) {
        final f = _timeToFrac(t.time);
        final dur = t.weight == TaskWeight.heavy
            ? 0.042
            : t.weight == TaskWeight.medium
                ? 0.028
                : 0.018;
        final color = t.linkedMeta != null ? c.green.withValues(alpha: 0.75) : c.blue.withValues(alpha: 0.75);
        final label = t.name.length > 6 ? t.name.substring(0, 6) : t.name;
        addBlock(f, dur, color, label);
      }

      return Column(
        children: [
          Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: SizedBox(
                  height: height - 4,
                  child: Stack(children: blocks),
                ),
              ),
              // linha do "agora"
              Positioned(
                left: (nowFrac * width).clamp(0, width - 2),
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: c.gold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0h', '4h', '8h', '12h', '16h', '20h', '24h']
                .map((l) => Text(l, style: AppFonts.inter(color: c.textMuted, fontSize: 9)))
                .toList(),
          ),
        ],
      );
    });
  }
}
