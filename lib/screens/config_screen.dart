import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import 'config/config_perfil.dart';
import 'config/config_sono.dart';
import 'config/config_produtividade.dart';
import 'config/config_notificacoes.dart';
import 'config/config_feedback.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  void _openTopic(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final name = state.userName.isNotEmpty ? state.userName : 'Olá!';
    final avatarLetter = state.userName.isNotEmpty ? state.userName[0].toUpperCase() : '?';
    final hasAvatar = state.avatarPath != null && File(state.avatarPath!).existsSync();

    final items = [
      (
        icon: Icons.person_outline,
        bg: c.blue.withValues(alpha: 0.15),
        fg: c.blue,
        label: 'Perfil',
        sub: 'Nome, foto e identidade',
        screen: const ConfigPerfilScreen(),
      ),
      (
        icon: Icons.nightlight_round,
        bg: c.purple.withValues(alpha: 0.12),
        fg: c.purple,
        label: 'Sono & rotina',
        sub: 'Horários, ciclos e descanso',
        screen: const ConfigSonoScreen(),
      ),
      (
        icon: Icons.track_changes_outlined,
        bg: c.green.withValues(alpha: 0.15),
        fg: c.green,
        label: 'Produtividade',
        sub: 'Foco, pausas e método',
        screen: const ConfigProdutividadeScreen(),
      ),
      (
        icon: Icons.notifications_outlined,
        bg: c.gold.withValues(alpha: 0.15),
        fg: c.gold,
        label: 'Notificações',
        sub: 'Lembretes e alertas',
        screen: const ConfigNotificacoesScreen(),
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        bg: c.orange.withValues(alpha: 0.15),
        fg: c.orange,
        label: 'Feedback',
        sub: 'Sugestões, bugs e elogios',
        screen: const ConfigFeedbackScreen(),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border),
                  image: hasAvatar
                      ? DecorationImage(image: FileImage(File(state.avatarPath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: hasAvatar
                    ? null
                    : Text(avatarLetter,
                        style: AppFonts.playfair(color: c.cream, fontSize: 20, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              // BUG 11 fix: state.userEmail é populado no login/cadastro
              // mas nunca aparecia em nenhuma tela do app. É informação
              // útil (ex: confirmar com qual conta está logado).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppFonts.playfair(color: c.cream, fontSize: 16)),
                    if (state.userEmail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        state.userEmail,
                        style: AppFonts.inter(color: c.textSoft, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text('Toque em Perfil para editar',
                        style: AppFonts.inter(color: c.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return InkWell(
                onTap: () => _openTopic(context, item.screen),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: i != items.length - 1
                        ? Border(bottom: BorderSide(color: c.border))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(color: item.bg, borderRadius: BorderRadius.circular(10)),
                        child: Icon(item.icon, color: item.fg, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label,
                                style: AppFonts.inter(color: c.text, fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(item.sub, style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: c.textMuted),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              _ConfigTermsLinks(colors: c),
              const SizedBox(height: 16),
              Text('Rotina.', style: AppFonts.playfair(color: c.creamMuted, fontSize: 20, italic: true)),
              const SizedBox(height: 4),
              Text('v1.0 · feito com ☕', style: AppFonts.inter(color: c.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfigTermsLinks extends StatelessWidget {
  final AppColors colors;
  const _ConfigTermsLinks({required this.colors});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _open('https://byebyte9.github.io/rotina-site/termos.html'),
          child: Text('Termos de Uso',
              style: TextStyle(
                  color: colors.textMuted, fontSize: 12,
                  fontFamily: 'Inter',
                  decoration: TextDecoration.underline,
                  decorationColor: colors.textMuted)),
        ),
        Text('  ·  ', style: AppFonts.inter(color: colors.textMuted, fontSize: 12)),
        GestureDetector(
          onTap: () => _open('https://byebyte9.github.io/rotina-site/privacidade.html'),
          child: Text('Política de Privacidade',
              style: TextStyle(
                  color: colors.textMuted, fontSize: 12,
                  fontFamily: 'Inter',
                  decoration: TextDecoration.underline,
                  decorationColor: colors.textMuted)),
        ),
      ],
    );
  }
}
