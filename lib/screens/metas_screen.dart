import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meta.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/add_edit_sheet.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/item_menu.dart';
import '../widgets/focus_timer_sheet.dart';

class MetasScreen extends StatelessWidget {
  const MetasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final metas = state.metas;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        const SectionLabel('Suas metas'),
        if (metas.isEmpty)
          const AppCard(child: EmptyState(emoji: '🎯', text: 'Nenhuma meta ainda'))
        else
          ...metas.map((m) => _MetaCard(meta: m)),
      ],
    );
  }
}

class _MetaCard extends StatelessWidget {
  final Meta meta;
  const _MetaCard({required this.meta});

  String _formatSecs(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return h > 0 ? '${h}h${m > 0 ? '${m}m' : ''}' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final color = metaColorValue(c, metaColorToString(meta.color));
    final pct = meta.target > 0 ? ((meta.current / meta.target) * 100).clamp(0, 100).round() : 0;

    final typeInfo = {
      MetaType.hours: ('⏱', 'Foco cronometrado'),
      MetaType.count: ('🔢', 'Contador'),
      MetaType.habit: ('📅', 'Hábito diário'),
    }[meta.type]!;

    final todayKey = state.fmtDateKey(DateTime.now());
    final checkedToday = meta.checkins[todayKey] != null && meta.checkins[todayKey] != false;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MetaTypeBadge(icon: typeInfo.$1, label: typeInfo.$2, color: color),
                    Text(meta.name,
                        style: AppFonts.playfair(color: c.cream, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: c.gold.withValues(alpha: 0.15),
                  border: Border.all(color: c.gold.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('🔥 ${meta.streak}',
                    style: TextStyle(color: c.gold, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              ItemMenuButton(
                onEdit: () => showAddEditSheet(context, editingMeta: meta),
                onDelete: () => showAppConfirm(
                  context,
                  title: 'Excluir meta?',
                  body: '"${meta.name}" e todo o progresso serão perdidos.',
                  confirmLabel: 'Sim, excluir',
                  onConfirm: () => state.deleteMeta(meta.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: c.surface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${meta.type == MetaType.hours ? (meta.current % 1 == 0 ? meta.current.toInt().toString() : meta.current.toStringAsFixed(1)) : meta.current.floor()} / ${meta.target % 1 == 0 ? meta.target.toInt() : meta.target} ${meta.unit} · $pct%',
                style: AppFonts.inter(color: c.textMuted, fontSize: 11),
              ),
              if (meta.type == MetaType.hours)
                _ActionButton(
                  label: meta.focusSecs > 0 ? '⏱ ${_formatSecs(meta.focusSecs)}' : '⏱ Iniciar foco',
                  onTap: () => showFocusTimer(context, meta),
                )
              else if (meta.type == MetaType.habit)
                _ActionButton(
                  label: checkedToday ? '✅ Feito hoje' : '＋ Check-in',
                  active: checkedToday,
                  onTap: () => state.checkIn(meta.id),
                )
              else
                _ActionButton(
                  label: '＋ Registrar',
                  onTap: () => state.checkIn(meta.id),
                ),
            ],
          ),
          if (meta.type == MetaType.habit || meta.type == MetaType.count) ...[
            const SizedBox(height: 8),
            _CheckinHistory(meta: meta),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _ActionButton({required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.green.withValues(alpha: 0.15) : c.surface,
          border: Border.all(color: active ? c.green : c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppFonts.inter(
            color: active ? c.green : c.textSoft,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CheckinHistory extends StatelessWidget {
  final Meta meta;
  const _CheckinHistory({required this.meta});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.read<AppState>();
    final history = state.getCheckinHistory(meta);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: history.map((h) {
        return Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: h.done ? c.green.withValues(alpha: 0.2) : c.surface,
            border: Border.all(color: h.done ? c.green : (h.isToday ? c.creamSoft : c.border)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            h.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: h.done ? c.green : c.textMuted,
            ),
          ),
        );
      }).toList(),
    );
  }
}
