import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Mostra overlay com animação de xícara de café enquanto [action] é executada.
/// Usado tanto para deletar conta quanto para sair da conta.
Future<void> showDeletingOverlay(
  BuildContext context,
  Future<void> Function() action, {
  String label = 'Aguarde...',
}) async {
  // Lê o tema ANTES de abrir o dialog (evita perder o InheritedWidget)
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    builder: (_) => _CoffeeOverlay(isDark: isDark, label: label),
  );

  try {
    await action();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _CoffeeOverlay extends StatefulWidget {
  final bool isDark;
  final String label;
  const _CoffeeOverlay({required this.isDark, required this.label});

  @override
  State<_CoffeeOverlay> createState() => _CoffeeOverlayState();
}

class _CoffeeOverlayState extends State<_CoffeeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _steamCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _steamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _steamCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Marrom escuro (dark) ↔ creme (light)
    final cupColor =
        widget.isDark ? const Color(0xFF7B4A2A) : const Color(0xFFE8D5B5);
    final steamColor =
        widget.isDark ? const Color(0xFFD4B896) : const Color(0xFF9A7A5A);
    final labelColor =
        widget.isDark ? const Color(0xFFF5ECD7) : const Color(0xFF2C1A0E);

    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: AnimatedBuilder(
                animation: _steamCtrl,
                builder: (_, __) => CustomPaint(
                  size: const Size(120, 140),
                  painter: _CoffeeCupPainter(
                    t: _steamCtrl.value,
                    cupColor: cupColor,
                    steamColor: steamColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                letterSpacing: 0.4,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoffeeCupPainter extends CustomPainter {
  final double t;
  final Color cupColor;
  final Color steamColor;

  const _CoffeeCupPainter({
    required this.t,
    required this.cupColor,
    required this.steamColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Pires ──
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.47, h * 0.89),
        width: w * 0.82,
        height: h * 0.08,
      ),
      Paint()
        ..color = cupColor.withValues(alpha: 0.40)
        ..style = PaintingStyle.fill,
    );

    // ── Corpo (trapézio arredondado) ──
    const tl = 0.22, tr = 0.78, bl = 0.10, br = 0.90;
    final topY = h * 0.35;
    final botY = h * 0.83;
    final r = h * 0.09;

    final body = Path()
      ..moveTo(w * tl, topY)
      ..lineTo(w * tr, topY)
      ..lineTo(w * br, botY - r)
      ..arcToPoint(Offset(w * br - r, botY),
          radius: Radius.circular(r), clockwise: true)
      ..lineTo(w * bl + r, botY)
      ..arcToPoint(Offset(w * bl, botY - r),
          radius: Radius.circular(r), clockwise: true)
      ..close();

    canvas.drawPath(
        body, Paint()..color = cupColor..style = PaintingStyle.fill);

    // Borda superior grossa
    canvas.drawLine(
      Offset(w * tl - 2, topY),
      Offset(w * tr + 2, topY),
      Paint()
        ..color = cupColor
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );

    // Listras internas
    final stripe = Paint()
      ..color = cupColor.withValues(alpha: 0.25)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final p = 0.52 + i * 0.12;
      final y = topY + (botY - topY) * p;
      final f = (y - topY) / (botY - topY);
      final xl = w * tl + (w * bl - w * tl) * f + w * 0.06;
      final xr = w * tr + (w * br - w * tr) * f - w * 0.06;
      canvas.drawLine(Offset(xl, y), Offset(xr, y), stripe);
    }

    // ── Alça ──
    final handle = Path()
      ..moveTo(w * 0.77, h * 0.44)
      ..cubicTo(w * 1.10, h * 0.43, w * 1.10, h * 0.73, w * 0.77, h * 0.73);
    canvas.drawPath(
        handle,
        Paint()
          ..color = cupColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.09
          ..strokeCap = StrokeCap.round);

    // ── Vapor (3 fios) ──
    _drawSteam(canvas, w * 0.30, h * 0.34, t, 0.00);
    _drawSteam(canvas, w * 0.49, h * 0.32, t, 0.34);
    _drawSteam(canvas, w * 0.67, h * 0.34, t, 0.67);
  }

  void _drawSteam(
      Canvas canvas, double x, double baseY, double t, double phase) {
    final p = (t + phase) % 1.0;

    // Opacidade: sobe suavemente, sustenta, depois some
    final double op;
    if (p < 0.18) {
      op = (p / 0.18) * 0.70;
    } else if (p > 0.72) {
      op = ((1.0 - p) / 0.28) * 0.70;
    } else {
      op = 0.70;
    }
    if (op < 0.03) return;

    // Sobe 60 px; ondula mais conforme sobe
    final rise = 60.0 * p;
    final amp = 7.0 * p;
    final wave = amp * math.sin(p * math.pi * 2.8 + phase * math.pi * 2);

    final path = Path()
      ..moveTo(x, baseY - rise)
      ..quadraticBezierTo(x + wave, baseY - rise - 10, x - wave * 0.4, baseY - rise - 22)
      ..quadraticBezierTo(x - wave, baseY - rise - 32, x + wave * 0.6, baseY - rise - 44);

    canvas.drawPath(
      path,
      Paint()
        ..color = steamColor.withValues(alpha: op)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CoffeeCupPainter o) =>
      o.t != t || o.cupColor != cupColor || o.steamColor != steamColor;
}
