import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/habit_suggestions.dart';
import '../theme/app_theme.dart';

/// Ponto de entrada do assistente de boas-vindas: mostra primeiro o modal
/// com a pergunta "Tem dúvidas em quais hábitos criar ou melhorar?" e,
/// caso o usuário aceite, conduz o mini-questionário + sugestões.
///
/// Chamado uma vez, logo depois do onboarding (nome definido). Se o
/// usuário recusar ou concluir o fluxo, [AppState.welcomeAssistantDone]
/// fica marcado e o modal não aparece de novo.
Future<void> showWelcomeAssistantFlow(BuildContext context) async {
  final state = context.read<AppState>();

  final wantsHelp = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => _WelcomeQuestionSheet(name: state.userName),
  );

  if (wantsHelp != true) {
    await state.dismissWelcomeAssistant();
    return;
  }

  if (!context.mounted) return;
  await Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, anim, secAnim) => const _RoutineWizardScreen(),
      transitionsBuilder: (ctx, anim, secAnim, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
    ),
  );

  // Garante que o assistente não reapareça mesmo se o usuário saiu no meio
  // (ex: botão voltar do Android) sem terminar o fluxo.
  if (context.mounted) {
    final st = context.read<AppState>();
    if (!st.welcomeAssistantDone) {
      await st.dismissWelcomeAssistant();
    }
  }
}

/// Modal inicial: "Tem dúvidas em quais hábitos criar ou melhorar? Eu ajudo!"
class _WelcomeQuestionSheet extends StatelessWidget {
  final String name;
  const _WelcomeQuestionSheet({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.auto_awesome_outlined, color: c.gold, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              name.isNotEmpty ? 'Bem-vindo(a), $name!' : 'Bem-vindo(a)!',
              textAlign: TextAlign.center,
              style: AppFonts.playfair(color: c.cream, fontSize: 19),
            ),
            const SizedBox(height: 10),
            Text(
              'Tem dúvidas em quais hábitos criar ou melhorar? Eu ajudo!',
              textAlign: TextAlign.center,
              style: AppFonts.inter(color: c.textMuted, fontSize: 14).copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.creamSoft,
                  foregroundColor: c.bg,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Quero ajuda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textSoft,
                  backgroundColor: c.card,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Não, obrigado', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela cheia com o mini-questionário + seleção de categorias + ampliação.
class _RoutineWizardScreen extends StatefulWidget {
  const _RoutineWizardScreen();

  @override
  State<_RoutineWizardScreen> createState() => _RoutineWizardScreenState();
}

enum _Step { wake, focus, categories, extras, done }

class _RoutineWizardScreenState extends State<_RoutineWizardScreen> {
  _Step step = _Step.wake;

  final profile = RoutineProfile();
  late List<HabitCategory> _catalog;
  final Set<String> selectedCategoryIds = {};
  final Set<String> selectedExtraIds = {};

  // Helpers de horário (sliders simples de hora cheia, sem picker pra ficar
  // rápido de responder dentro do próprio wizard).
  int wakeHour = 7;
  int sleepHour = 23;

  @override
  void initState() {
    super.initState();
    _catalog = HabitCategoryCatalog.build(profile);
  }

  void _refreshCatalog() {
    profile.wakeTime = '${wakeHour.toString().padLeft(2, '0')}:00';
    profile.sleepTime = '${sleepHour.toString().padLeft(2, '0')}:00';
    _catalog = HabitCategoryCatalog.build(profile);
  }

  List<HabitCategory> get _selectedCategories =>
      _catalog.where((c) => selectedCategoryIds.contains(c.id)).toList();

  List<ExtraHabit> get _availableExtras {
    final seen = <String>{};
    final result = <ExtraHabit>[];
    for (final cat in _selectedCategories) {
      for (final e in cat.categoryExtras) {
        if (seen.add(e.id)) result.add(e);
      }
    }
    for (final e in HabitCategoryCatalog.variedExtras()) {
      if (seen.add(e.id)) result.add(e);
    }
    return result;
  }

  List<ExtraHabit> get _selectedExtras =>
      _availableExtras.where((e) => selectedExtraIds.contains(e.id)).toList();

  void _goTo(_Step s) => setState(() => step = s);

  Future<void> _finish() async {
    final state = context.read<AppState>();
    await state.applySuggestedCategories(_selectedCategories, profile);
    if (selectedExtraIds.isNotEmpty) {
      await state.applyExtraHabits(_selectedExtras);
    }
    await state.dismissWelcomeAssistant();
    if (mounted) _goTo(_Step.done);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildStep(c),
        ),
      ),
    );
  }

  Widget _buildStep(AppColors c) {
    switch (step) {
      case _Step.wake:
        return _ScheduleStep(
          key: const ValueKey('wake'),
          title: 'Como é a sua rotina?',
          subtitle: 'Que horas você costuma acordar e dormir?',
          wakeHour: wakeHour,
          sleepHour: sleepHour,
          onWakeChanged: (v) => setState(() => wakeHour = v),
          onSleepChanged: (v) => setState(() => sleepHour = v),
          onNext: () {
            _refreshCatalog();
            _goTo(_Step.focus);
          },
          onSkip: () {
            _refreshCatalog();
            _goTo(_Step.focus);
          },
        );
      case _Step.focus:
        return _FocusPeriodStep(
          key: const ValueKey('focus'),
          selected: profile.focusPeriod,
          onSelect: (v) => setState(() => profile.focusPeriod = v),
          onBack: () => _goTo(_Step.wake),
          onNext: () {
            _refreshCatalog();
            _goTo(_Step.categories);
          },
        );
      case _Step.categories:
        return _CategoryStep(
          key: const ValueKey('categories'),
          categories: _catalog,
          selectedIds: selectedCategoryIds,
          onToggle: (id) => setState(() {
            if (!selectedCategoryIds.remove(id)) selectedCategoryIds.add(id);
          }),
          onBack: () => _goTo(_Step.focus),
          onNext: () => _goTo(_Step.extras),
        );
      case _Step.extras:
        return _ExtrasStep(
          key: const ValueKey('extras'),
          extras: _availableExtras,
          selectedIds: selectedExtraIds,
          onToggle: (id) => setState(() {
            if (!selectedExtraIds.remove(id)) selectedExtraIds.add(id);
          }),
          onBack: () => _goTo(_Step.categories),
          onFinish: _finish,
        );
      case _Step.done:
        return _DoneStep(
          key: const ValueKey('done'),
          metaCount: _selectedCategories.fold<int>(0, (sum, c) => sum + c.metas.length) +
              _selectedExtras.where((e) => e.meta != null).length,
          taskCount: _selectedCategories.fold<int>(
                0,
                (sum, c) => sum + c.metas.fold<int>(0, (s, m) => s + m.tasks.length),
              ) +
              _selectedExtras.length,
          onClose: () => Navigator.of(context).pop(),
        );
    }
  }
}

/// Cabeçalho reutilizável dos passos do wizard (título + subtítulo).
Widget _wizardHeader(AppColors c, {required String title, String? subtitle}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppFonts.playfair(color: c.cream, fontSize: 22, italic: true)),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle, style: AppFonts.inter(color: c.textMuted, fontSize: 14).copyWith(height: 1.5)),
      ],
    ],
  );
}

Widget _wizardFooter(
  AppColors c, {
  VoidCallback? onBack,
  required VoidCallback? onNext,
  String nextLabel = 'Próximo',
  String? skipLabel,
  VoidCallback? onSkip,
}) {
  return Column(
    children: [
      Row(
        children: [
          if (onBack != null)
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textMuted,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Voltar'),
              ),
            ),
          if (onBack != null) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.creamSoft,
                foregroundColor: c.bg,
                disabledBackgroundColor: c.creamSoft.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(nextLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      if (onSkip != null) ...[
        const SizedBox(height: 10),
        TextButton(
          onPressed: onSkip,
          child: Text(skipLabel ?? 'Pular', style: TextStyle(color: c.textMuted, fontSize: 13)),
        ),
      ],
    ],
  );
}

/// Passo 1: horário de dormir/acordar com sliders simples.
class _ScheduleStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final int wakeHour;
  final int sleepHour;
  final ValueChanged<int> onWakeChanged;
  final ValueChanged<int> onSleepChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _ScheduleStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.wakeHour,
    required this.sleepHour,
    required this.onWakeChanged,
    required this.onSleepChanged,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wizardHeader(c, title: title, subtitle: subtitle),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _hourPickerRow(
                  c,
                  icon: Icons.wb_sunny_outlined,
                  label: 'Acordo às',
                  hour: wakeHour,
                  onChanged: onWakeChanged,
                ),
                const SizedBox(height: 20),
                _hourPickerRow(
                  c,
                  icon: Icons.nightlight_round,
                  label: 'Durmo às',
                  hour: sleepHour,
                  onChanged: onSleepChanged,
                ),
              ],
            ),
          ),
          _wizardFooter(c, onNext: onNext, onSkip: onSkip, skipLabel: 'Pular esta etapa'),
        ],
      ),
    );
  }

  Widget _hourPickerRow(
    AppColors c, {
    required IconData icon,
    required String label,
    required int hour,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: c.creamSoft),
              const SizedBox(width: 8),
              Text(label, style: AppFonts.inter(color: c.text, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: AppFonts.playfair(color: c.cream, fontSize: 18, italic: true),
              ),
            ],
          ),
          Slider(
            value: hour.toDouble(),
            min: 0,
            max: 23,
            divisions: 23,
            activeColor: c.creamSoft,
            inactiveColor: c.border,
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

/// Passo 2: período do dia em que a pessoa se sente mais produtiva.
class _FocusPeriodStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _FocusPeriodStep({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onNext,
  });

  static const _options = [
    (id: 'manha', label: 'Manhã', emoji: '🌅'),
    (id: 'tarde', label: 'Tarde', emoji: '☀️'),
    (id: 'noite', label: 'Noite', emoji: '🌙'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wizardHeader(
            c,
            title: 'Quando você foca melhor?',
            subtitle: 'Vou usar isso pra sugerir o melhor horário dos seus blocos de foco.',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView(
              children: _options.map((o) {
                final isSelected = selected == o.id;
                return InkWell(
                  onTap: () => onSelect(o.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? c.card : c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? c.creamSoft : c.border),
                    ),
                    child: Row(
                      children: [
                        Text(o.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            o.label,
                            style: AppFonts.inter(
                              color: isSelected ? c.cream : c.text,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected) Icon(Icons.check_circle, color: c.green, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          _wizardFooter(c, onBack: onBack, onNext: onNext),
        ],
      ),
    );
  }
}

/// Passo 3: seleção das categorias de hábitos/metas sugeridas.
class _CategoryStep extends StatelessWidget {
  final List<HabitCategory> categories;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _CategoryStep({
    super.key,
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final canAdvance = selectedIds.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wizardHeader(
            c,
            title: 'O que você quer melhorar?',
            subtitle: 'Escolha uma ou mais áreas. Vou sugerir metas e tarefas pra cada uma.',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final isSelected = selectedIds.contains(cat.id);
                return InkWell(
                  onTap: () => onToggle(cat.id),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? c.card : c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? c.creamSoft : c.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.label,
                                style: AppFonts.inter(
                                  color: isSelected ? c.cream : c.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat.description,
                                style: AppFonts.inter(color: c.textMuted, fontSize: 12).copyWith(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? c.green : c.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _wizardFooter(
            c,
            onBack: onBack,
            onNext: canAdvance ? onNext : null,
            nextLabel: 'Continuar',
          ),
        ],
      ),
    );
  }
}

/// Passo 4: "Quer ampliar mais seu dia?" — hábitos extras que a pessoa
/// talvez não tenha pensado em fazer (skincare, leitura, etc.).
class _ExtrasStep extends StatelessWidget {
  final List<ExtraHabit> extras;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const _ExtrasStep({
    super.key,
    required this.extras,
    required this.selectedIds,
    required this.onToggle,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _wizardHeader(
            c,
            title: 'Quer ampliar mais seu dia?',
            subtitle: 'Algumas pessoas esquecem desses hábitos — quer incluir algum?',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: extras.isEmpty
                ? Center(
                    child: Text(
                      'Sem sugestões extras por aqui.',
                      style: AppFonts.inter(color: c.textMuted, fontSize: 13),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: extras.length,
                    itemBuilder: (ctx, i) {
                      final e = extras[i];
                      final isSelected = selectedIds.contains(e.id);
                      return InkWell(
                        onTap: () => onToggle(e.id),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? c.card : c.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSelected ? c.creamSoft : c.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.emoji, style: const TextStyle(fontSize: 20)),
                                  Icon(
                                    isSelected ? Icons.check_circle : Icons.add_circle_outline,
                                    color: isSelected ? c.green : c.textMuted,
                                    size: 18,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                e.label,
                                style: AppFonts.inter(
                                  color: isSelected ? c.cream : c.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ).copyWith(height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          _wizardFooter(
            c,
            onBack: onBack,
            onNext: onFinish,
            nextLabel: selectedIds.isEmpty ? 'Concluir sem ampliar' : 'Concluir',
          ),
        ],
      ),
    );
  }
}

/// Passo final: resumo de conclusão.
class _DoneStep extends StatelessWidget {
  final int metaCount;
  final int taskCount;
  final VoidCallback onClose;

  const _DoneStep({
    super.key,
    required this.metaCount,
    required this.taskCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.check_rounded, color: c.green, size: 34),
                ),
                const SizedBox(height: 24),
                Text(
                  'Tudo pronto!',
                  textAlign: TextAlign.center,
                  style: AppFonts.playfair(color: c.cream, fontSize: 24, italic: true),
                ),
                const SizedBox(height: 12),
                Text(
                  metaCount > 0
                      ? 'Criei $metaCount ${metaCount == 1 ? 'meta' : 'metas'} e $taskCount ${taskCount == 1 ? 'tarefa' : 'tarefas'} pra você começar. Você pode editar tudo a qualquer momento.'
                      : 'Você pode criar metas e tarefas a qualquer momento por aqui.',
                  textAlign: TextAlign.center,
                  style: AppFonts.inter(color: c.textMuted, fontSize: 14).copyWith(height: 1.6),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.creamSoft,
                foregroundColor: c.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Ir para o app', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
