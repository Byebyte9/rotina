import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Card básico — equivalente a `.card` no CSS.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

/// Título de card em Playfair Display — equivalente a `.card-title`.
class CardTitle extends StatelessWidget {
  final String text;
  const CardTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppFonts.playfair(color: c.cream, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Label de seção — equivalente a `.section-label`.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppFonts.inter(
          color: c.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ).copyWith(letterSpacing: 1),
      ),
    );
  }
}

/// Tag pequena (pill) — equivalente a `.tag`.
class AppTag extends StatelessWidget {
  final String label;
  final Color color;
  const AppTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Tag neutra para "recorrente" — usa borda como no CSS (.tag.recurrent).
class NeutralTag extends StatelessWidget {
  final String label;
  const NeutralTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: c.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// Empty state simples (ícone emoji + texto) usado em várias listas.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String text;
  const EmptyState({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(text, style: AppFonts.inter(color: c.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Badge de tipo de meta — equivalente a `.meta-type-badge`.
class MetaTypeBadge extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const MetaTypeBadge({super.key, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$icon $label'.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
