import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de cores espelhando 1:1 as variáveis CSS do app original
/// (--bg, --surface, --card, etc.) para os temas dark e light.
class AppColors {
  final Color bg;
  final Color surface;
  final Color card;
  final Color cardHover;
  final Color border;
  final Color cream;
  final Color creamSoft;
  final Color creamMuted;
  final Color green;
  final Color orange;
  final Color red;
  final Color gold;
  final Color blue;
  final Color purple;
  final Color text;
  final Color textSoft;
  final Color textMuted;
  final Color shadow;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.cardHover,
    required this.border,
    required this.cream,
    required this.creamSoft,
    required this.creamMuted,
    required this.green,
    required this.orange,
    required this.red,
    required this.gold,
    required this.blue,
    required this.purple,
    required this.text,
    required this.textSoft,
    required this.textMuted,
    required this.shadow,
  });

  static const dark = AppColors(
    bg: Color(0xFF2C1A0E),
    surface: Color(0xFF3D2512),
    card: Color(0xFF4A2E18),
    cardHover: Color(0xFF56361E),
    border: Color(0xFF5C3A20),
    cream: Color(0xFFF5ECD7),
    creamSoft: Color(0xFFC4A882),
    creamMuted: Color(0xFF8A6A4A),
    green: Color(0xFF7BAF6E),
    orange: Color(0xFFD4834A),
    red: Color(0xFFC45C4A),
    gold: Color(0xFFE8B84B),
    blue: Color(0xFF5B8FBF),
    purple: Color(0xFF7B6BAF),
    text: Color(0xFFF5ECD7),
    textSoft: Color(0xFFC4A882),
    textMuted: Color(0xFF8A6A4A),
    shadow: Color(0x66000000),
  );

  static const light = AppColors(
    bg: Color(0xFFF5ECD7),
    surface: Color(0xFFEDE0C8),
    card: Color(0xFFE5D4B5),
    cardHover: Color(0xFFDCC9A5),
    border: Color(0xFFC4A882),
    cream: Color(0xFF2C1A0E),
    creamSoft: Color(0xFF5C3A20),
    creamMuted: Color(0xFF8A6A4A),
    green: Color(0xFF7BAF6E),
    orange: Color(0xFFD4834A),
    red: Color(0xFFC45C4A),
    gold: Color(0xFFE8B84B),
    blue: Color(0xFF5B8FBF),
    purple: Color(0xFF7B6BAF),
    text: Color(0xFF2C1A0E),
    textSoft: Color(0xFF5C3A20),
    textMuted: Color(0xFF8A6A4A),
    shadow: Color(0x26000000),
  );
}

/// InheritedWidget simples pra disponibilizar AppColors em toda a árvore,
/// trocando dark/light sem precisar de Theme.of() boilerplate.
class AppTheme extends InheritedWidget {
  final AppColors colors;
  final bool isDark;

  const AppTheme({
    super.key,
    required this.colors,
    required this.isDark,
    required super.child,
  });

  static AppColors of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    return widget?.colors ?? AppColors.dark;
  }

  static bool isDarkOf(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    return widget?.isDark ?? true;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) =>
      oldWidget.colors != colors || oldWidget.isDark != isDark;
}

/// Helpers de tipografia: Playfair Display (títulos, itálico) + Inter (corpo).
class AppFonts {
  static TextStyle playfair({
    required Color color,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    bool italic = false,
  }) =>
      GoogleFonts.playfairDisplay(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  static TextStyle inter({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      GoogleFonts.inter(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
}

/// Mapeia o color string ('green','blue',...) salvo nas metas para a Color real.
Color metaColorValue(AppColors c, String colorKey) {
  switch (colorKey) {
    case 'blue':
      return c.blue;
    case 'orange':
      return c.orange;
    case 'purple':
      return c.purple;
    case 'gold':
      return c.gold;
    default:
      return c.green;
  }
}
