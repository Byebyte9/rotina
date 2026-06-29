import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/pickers.dart';
import 'config_common.dart';

class ConfigSonoScreen extends StatefulWidget {
  const ConfigSonoScreen({super.key});

  @override
  State<ConfigSonoScreen> createState() => _ConfigSonoScreenState();
}

class _ConfigSonoScreenState extends State<ConfigSonoScreen> {
  bool savedMsg = false;

  Future<void> _save(AppState state, String start, String end) async {
    await state.setDefaultSleep(start, end);
    setState(() => savedMsg = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => savedMsg = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final weekAvgLabel = _weekAverageSleepLabel(state);

    return ConfigSubScaffold(
      title: 'Sono & Rotina',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Horários padrão'),
              Row(children: [
                Icon(Icons.nightlight_round, size: 11, color: c.purple),
                const SizedBox(width: 4),
                Text('Hora de dormir', style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              _timeTrigger(c, state.sleep.start, () async {
                final r = await showTimePickerSheet(context, initialTime: state.sleep.start, title: 'Hora de dormir');
                if (r != null) await _save(state, r, state.sleep.end);
              }),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.wb_sunny_outlined, size: 11, color: c.gold),
                const SizedBox(width: 4),
                Text('Hora de acordar', style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              _timeTrigger(c, state.sleep.end, () async {
                final r = await showTimePickerSheet(context, initialTime: state.sleep.end, title: 'Hora de acordar');
                if (r != null) await _save(state, state.sleep.start, r);
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _save(state, state.sleep.start, state.sleep.end),
                  icon: const Icon(Icons.check, size: 13),
                  label: const Text('Salvar horários'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.creamSoft,
                    foregroundColor: c.bg,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              if (savedMsg)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(child: Text('Salvo ✓', style: TextStyle(color: c.green, fontSize: 12))),
                ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Sono desta semana'),
              CfgRow(label: 'Média registrada (7 dias)', showBorder: false, trailing: CfgValue(weekAvgLabel)),
            ],
          ),
        ),
      ],
    );
  }

  /// Calcula a média de sono dos últimos 7 dias com base no que foi
  /// efetivamente registrado em cada dia (DayData), não no padrão fixo.
  String _weekAverageSleepLabel(AppState state) {
    final now = DateTime.now();
    int totalMins = 0;
    int count = 0;
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final key = state.fmtDateKey(d);
      final dayData = state.getDayData(key);
      if (dayData.sleep != null) {
        totalMins += dayData.sleep!.durationMinutes;
        count++;
      }
    }
    if (count == 0) return '—';
    final avg = totalMins ~/ count;
    return '${avg ~/ 60}h${avg % 60 > 0 ? '${avg % 60}m' : ''}';
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
