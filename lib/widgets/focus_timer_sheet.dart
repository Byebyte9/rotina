import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meta.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

/// Abre o modal de timer de foco para uma meta — equivalente a
/// `openTimer()` / `timerToggle()` / `closeTimer()` no JS.
Future<void> showFocusTimer(BuildContext context, Meta meta) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => _FocusTimerSheet(meta: meta),
  );
}

class _FocusTimerSheet extends StatefulWidget {
  final Meta meta;
  const _FocusTimerSheet({required this.meta});

  @override
  State<_FocusTimerSheet> createState() => _FocusTimerSheetState();
}

class _FocusTimerSheetState extends State<_FocusTimerSheet> {
  Timer? _timer;
  bool running = false;
  int secs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      running = !running;
      if (running) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => secs++);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _close() async {
    _timer?.cancel();
    if (secs > 0) {
      await context.read<AppState>().addFocusSeconds(widget.meta.id, secs);
    }
    if (mounted) Navigator.of(context).pop();
  }

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.meta.name, style: AppFonts.playfair(color: c.cream, fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              'Sessão de foco · ${widget.meta.current.toStringAsFixed(widget.meta.current % 1 == 0 ? 0 : 1)}/${widget.meta.target.toStringAsFixed(widget.meta.target % 1 == 0 ? 0 : 1)} ${widget.meta.unit}',
              style: AppFonts.inter(color: c.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Text(
              _fmt(secs),
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w300,
                color: c.cream,
                letterSpacing: -2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _toggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: running ? c.red : c.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    running ? '⏸ Pausar' : (secs > 0 ? '▶ Continuar' : '▶ Iniciar'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _close,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.card,
                    foregroundColor: c.textSoft,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Fechar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
