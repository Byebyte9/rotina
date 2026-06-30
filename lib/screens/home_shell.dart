import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/add_edit_sheet.dart';
import '../widgets/day_sheet.dart';
import '../widgets/email_verification_banner.dart';
import '../widgets/welcome_assistant.dart';
import 'founder_screen.dart';
import 'hoje_screen.dart';
import 'tarefas_screen.dart';
import 'metas_screen.dart';
import 'dashboard_screen.dart';
import 'config_screen.dart';
import 'verify_email_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pede permissão de notificação (Android 13+) na primeira vez que o
    // app principal é exibido, já que as preferências padrão vêm ativadas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestPermissions();
      if (mounted) _maybeShowWelcomeAssistant();
    });
    // Quando o usuário toca "Concluir" numa notificação com o app aberto,
    // o NotificationService já marcou a tarefa no SharedPreferences — aqui
    // só recarregamos o estado em memória para a UI atualizar na hora.
    NotificationService.instance.onTaskMarkedDoneInForeground = (taskId) {
      if (mounted) context.read<AppState>().markTaskDone(taskId);
    };
  }

  /// Mostra o modal de boas-vindas apenas quando o usuário acabou de se
  /// cadastrar (justRegistered). No login, vai direto para o app.
  void _maybeShowWelcomeAssistant() {
    final state = context.read<AppState>();
    // Só exibe o welcome flow para usuários recém-cadastrados
    if (!state.welcomeAssistantDone && state.justRegistered) {
      _runWelcomeFlow(state);
    }
  }

  Future<void> _runWelcomeFlow(AppState state) async {
    await showWelcomeAssistantFlow(context);
    if (!mounted) return;
    // Limpa a flag para não repetir em próximas sessões
    state.clearJustRegistered();
    // Mostra tela de fundador se ainda não foi exibida nesta sessão
    if (state.isFounder && state.founderPosition != null) {
      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (ctx, anim, _) => FounderScreen(
            userName: state.userName,
            position: state.founderPosition!,
            onContinue: () => Navigator.of(ctx).pop(),
          ),
          transitionsBuilder: (ctx, anim, _, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
      );
    }
  }

  final screens = const [
    HojeScreen(),
    TarefasScreen(),
    MetasScreen(),
    DashboardScreen(),
    ConfigScreen(),
  ];

  final navItems = const [
    (icon: Icons.wb_sunny_outlined, label: 'Hoje'),
    (icon: Icons.check_circle_outline, label: 'Tarefas'),
    (icon: Icons.track_changes_outlined, label: 'Metas'),
    (icon: Icons.bar_chart_outlined, label: 'Dashboard'),
    (icon: Icons.settings_outlined, label: 'Config'),
  ];

  String _formatDatePill() {
    final now = DateTime.now();
    final formatted = DateFormat("EEE, d 'de' MMM", 'pt_BR').format(now);
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: RichText(
          text: TextSpan(
            style: AppFonts.playfair(color: c.cream, fontSize: 20, italic: true),
            children: [
              const TextSpan(text: 'Rotina'),
              TextSpan(text: '.', style: TextStyle(color: c.creamSoft)),
            ],
          ),
        ),
        actions: [
          InkWell(
            onTap: () => showDaySheet(context),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: c.textSoft),
                  const SizedBox(width: 6),
                  Text(_formatDatePill(), style: AppFonts.inter(color: c.text, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => state.toggleTheme(),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                shape: BoxShape.circle,
              ),
              child: Icon(
                state.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                size: 16,
                color: c.textSoft,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          if (!state.emailVerified)
            EmailVerificationBanner(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VerifyEmailScreen(
                    onVerified: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: screens,
            ),
          ),
        ],
      ),
      floatingActionButton: currentIndex == 4
          ? null
          : FloatingActionButton(
              onPressed: () => showAddEditSheet(context),
              backgroundColor: c.creamSoft,
              foregroundColor: c.bg,
              elevation: 2,
              child: const Icon(Icons.add, size: 26),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: navItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final active = i == currentIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => currentIndex = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 20, color: active ? c.creamSoft : c.textMuted),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? c.creamSoft : c.textMuted,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
