import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ConfirmIconType { danger, warning, info }

/// Equivalente a `showConfirm()` no JS: bottom sheet de confirmação com
/// ícone, título, corpo e dois botões.
Future<void> showAppConfirm(
  BuildContext context, {
  ConfirmIconType icon = ConfirmIconType.danger,
  IconData iconData = Icons.delete_outline,
  required String title,
  required String body,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool danger = true,
  required Future<void> Function() onConfirm,
}) async {
  final c = AppTheme.of(context);

  Color iconBg;
  Color iconColor;
  switch (icon) {
    case ConfirmIconType.danger:
      iconBg = c.red.withValues(alpha: 0.15);
      iconColor = c.red;
      break;
    case ConfirmIconType.warning:
      iconBg = c.gold.withValues(alpha: 0.15);
      iconColor = c.gold;
      break;
    case ConfirmIconType.info:
      iconBg = c.blue.withValues(alpha: 0.15);
      iconColor = c.blue;
      break;
  }

  final confirmColor = danger ? c.red : c.gold;
  final confirmTextColor = danger ? Colors.white : const Color(0xFF1A1000);

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppFonts.playfair(color: c.cream, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppFonts.inter(color: c.textMuted, fontSize: 13).copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: confirmTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(confirmLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSoft,
                    backgroundColor: c.card,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(cancelLabel,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
