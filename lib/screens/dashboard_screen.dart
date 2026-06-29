import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meta.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/day_sheet.dart';

const _monthNamesFull = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];
const _dowLabels = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int calYear;
  late int calMonth; // 1-12

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    calYear = now.year;
    calMonth = now.month;
  }

  void _changeMonth(int dir) {
    setState(() {
      calMonth += dir;
      if (calMonth > 12) {
        calMonth = 1;
        calYear++;
      }
      if (calMonth < 1) {
        calMonth = 12;
        calYear--;
      }
    });
  }

  String _formatSecs(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return h > 0 ? '${h}h${m > 0 ? '${m}m' : ''}' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();

    final maxStreak = state.metas.isEmpty
        ? 0
        : state.metas.map((m) => m.streak).reduce((a, b) => a > b ? a : b);

    final todayTasks = state.todayTasks;
    // Bug 9 fix: renomeado de weekRate para taxaHoje — é a taxa do dia atual
    final taxaHoje = todayTasks.isEmpty
        ? '—'
        : '${(todayTasks.where((t) => t.done).length / todayTasks.length * 100).round()}%';

    final focusLabel = state.focusSeconds > 0 ? _formatSecs(state.focusSeconds) : '0m';

    final sleepMins = state.getTodaySleep().durationMinutes;
    final sleepLabel =
        '${sleepMins ~/ 60}h${sleepMins % 60 > 0 ? '${sleepMins % 60}m' : ''}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            _StatCard(icon: Icons.local_fire_department, iconColor: c.gold, value: '$maxStreak🔥', label: 'Maior streak'),
            _StatCard(icon: Icons.check_circle_outline, iconColor: c.green, value: taxaHoje, label: 'Taxa hoje'),
            _StatCard(icon: Icons.timer_outlined, iconColor: c.blue, value: focusLabel, label: 'Foco acumulado'),
            _StatCard(icon: Icons.bedtime_outlined, iconColor: c.purple, value: sleepLabel, label: 'Sono esta noite'),
          ],
        ),
        const SizedBox(height: 12),
        _buildCalendar(context, c, state),
        const SectionLabel('Streaks ativos'),
        if (state.metas.isEmpty)
          const AppCard(child: EmptyState(emoji: '🎯', text: 'Nenhuma meta ainda'))
        else
          ...state.metas.map((m) {
            final pct = m.target > 0 ? ((m.current / m.target) * 100).clamp(0, 100).round() : 0;
            final color = metaColorValue(c, metaColorToString(m.color));
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.name,
                          style: AppFonts.inter(color: c.text, fontSize: 13, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.gold.withValues(alpha: 0.15),
                          border: Border.all(color: c.gold.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('🔥 ${m.streak} dias',
                            style: TextStyle(color: c.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: c.surface,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$pct% concluído', style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, AppColors c, AppState state) {
    final now = DateTime.now();
    final firstWeekday = DateTime(calYear, calMonth, 1).weekday % 7;
    final daysInMonth = DateTime(calYear, calMonth + 1, 0).day;
    final daysInPrev = DateTime(calYear, calMonth, 0).day;

    final cells = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(_calDayCell('${daysInPrev - firstWeekday + i + 1}', otherMonth: true));
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(calYear, calMonth, d);
      final isToday = d == now.day && calMonth == now.month && calYear == now.year;
      final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));
      String? dotColor;

      if (!isFuture) {
        if (isToday) {
          final tasks = state.todayTasks;
          if (tasks.isNotEmpty) {
            final pct = tasks.where((t) => t.done).length / tasks.length;
            dotColor = pct >= 0.8 ? 'green' : (pct >= 0.3 ? 'orange' : 'red');
          }
        } else {
          final key = state.fmtDateKey(date);
          final dayData = state.getDayData(key);
          if (dayData.dot.isNotEmpty) dotColor = dayData.dot;
        }
      }

      cells.add(
        GestureDetector(
          onTap: () => showDaySheet(context, date: date),
          child: _calDayCell('$d', isToday: isToday, dotColor: dotColor),
        ),
      );
    }

    final total = firstWeekday + daysInMonth;
    final remaining = (7 - (total % 7)) % 7;
    for (int i = 1; i <= remaining; i++) {
      cells.add(_calDayCell('$i', otherMonth: true));
    }

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_monthNamesFull[calMonth - 1]} $calYear',
                  style: AppFonts.playfair(color: c.cream, fontSize: 15)),
              Row(
                children: [
                  _navBtn(c, Icons.chevron_left, () => _changeMonth(-1)),
                  const SizedBox(width: 8),
                  _navBtn(c, Icons.chevron_right, () => _changeMonth(1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _dowLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: AppFonts.inter(
                                color: c.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 2),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _navBtn(AppColors c, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: c.textSoft),
      ),
    );
  }

  Widget _calDayCell(String label, {bool isToday = false, bool otherMonth = false, String? dotColor}) {
    return Builder(builder: (context) {
      final c = AppTheme.of(context);
      Color? dot;
      if (dotColor == 'green') dot = c.green;
      if (dotColor == 'orange') dot = c.orange;
      if (dotColor == 'red') dot = c.red;

      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isToday ? c.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Opacity(
          opacity: otherMonth ? 0.4 : 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppFonts.inter(
                  color: otherMonth ? c.textMuted : (isToday ? c.cream : c.textSoft),
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 5,
                child: dot != null
                    ? Container(width: 5, height: 5, decoration: BoxDecoration(color: dot, shape: BoxShape.circle))
                    : null,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: AppFonts.inter(color: c.cream, fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
