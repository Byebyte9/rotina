import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Scaffold padrão de subtela de config — equivalente ao
/// `configSubOverlay` (slide-in com título + voltar) no JS.
class ConfigSubScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const ConfigSubScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(title, style: AppFonts.playfair(color: c.cream, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: children,
      ),
    );
  }
}

/// Título de seção dentro de um card de config — `.cfg-section-title`.
class CfgSectionTitle extends StatelessWidget {
  final String text;
  const CfgSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: AppFonts.inter(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)
            .copyWith(letterSpacing: 0.5),
      ),
    );
  }
}

/// Linha de configuração (label + sub + valor/toggle à direita) — `.cfg-row`.
class CfgRow extends StatelessWidget {
  final String label;
  final String? sub;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool showBorder;

  const CfgRow({
    super.key,
    required this.label,
    this.sub,
    required this.trailing,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: showBorder
            ? BoxDecoration(border: Border(bottom: BorderSide(color: c.border)))
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppFonts.inter(color: c.text, fontSize: 13)),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(sub!, style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Toggle visual (não funcional para configs cosméticas, espelhando o
/// app original onde vários toggles eram apenas decorativos).
class CfgToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const CfgToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? c.green : c.border,
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// Valor estático à direita de uma CfgRow (texto simples).
class CfgValue extends StatelessWidget {
  final String text;
  final Color? color;
  const CfgValue(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Text(text,
        style: AppFonts.inter(
          color: color ?? c.cream,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ));
  }
}
