import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

const _obBg = Color(0xFF1E1008);
const _obCream = Color(0xFFF5ECD7);
const _obAccent = Color(0xFFC4A882);
const _obMuted = Color(0xFF8A6A4A);
const _obDark = Color(0xFF3D2512);
const _obBorder = Color(0xFF5C3A20);

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  /// Nome já preenchido (vindo do cadastro). Se informado, o campo vem pré-populado.
  final String? initialName;
  const OnboardingScreen({super.key, required this.onComplete, this.initialName});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentSlide = 0;
  static const total = 5;
  late final TextEditingController nameCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _pageController.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (currentSlide < total - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    } else {
      _finish();
    }
  }

  void _back() {
    if (currentSlide > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    }
  }

  Future<void> _finish() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    await context.read<AppState>().completeOnboarding(name);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final canAdvance = currentSlide < total - 1 || nameCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _obBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => currentSlide = i),
                children: [
                  _slide(
                    icon: Icons.eco_outlined,
                    title: 'Bem-vindo ao Rotina.',
                    body: 'Um espaço simples e bonito para organizar seus dias, construir hábitos e alcançar suas metas — do seu jeito.',
                  ),
                  _slide(
                    icon: Icons.checklist_outlined,
                    title: 'Tarefas que fazem sentido',
                    body: 'Crie tarefas com horários, defina o peso de cada uma e acompanhe seu progresso do dia em tempo real na linha do tempo.',
                  ),
                  _slide(
                    icon: Icons.track_changes_outlined,
                    title: 'Metas que você não abandona',
                    body: 'Conecte tarefas às suas metas, use o timer de foco para registrar seu tempo e veja seus streaks crescerem.',
                  ),
                  _slide(
                    icon: Icons.calendar_month_outlined,
                    title: 'Seu histórico, sempre à mão',
                    body: 'O calendário mostra como cada dia foi. Anote reflexões, registre seu sono e veja padrões no dashboard.',
                  ),
                  _nameSlide(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (i) {
                      final active = i == currentSlide;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? _obAccent : _obDark,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (currentSlide > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _back,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _obMuted,
                              side: const BorderSide(color: _obDark),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Voltar'),
                          ),
                        ),
                      if (currentSlide > 0) const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: canAdvance ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _obAccent,
                            foregroundColor: _obBg,
                            disabledBackgroundColor: _obAccent.withValues(alpha: 0.4),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            currentSlide == total - 1 ? 'Começar' : 'Próximo',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slide({required IconData icon, required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _obAccent.withValues(alpha: 0.12),
              border: Border.all(color: _obAccent.withValues(alpha: 0.18)),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: _obAccent, size: 32),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontStyle: FontStyle.italic,
              fontSize: 26,
              color: _obCream,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _obMuted, height: 1.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _obAccent.withValues(alpha: 0.12),
              border: Border.all(color: _obAccent.withValues(alpha: 0.18)),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.person_outline, color: _obAccent, size: 32),
          ),
          const SizedBox(height: 28),
          Text(
            'Como posso te chamar?',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontStyle: FontStyle.italic,
              fontSize: 26,
              color: _obCream,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEU NOME',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Color(0xFF5C3A20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  maxLength: 30,
                  autofocus: false,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 22,
                    color: _obCream,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _obDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _obBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _obBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _obAccent),
                    ),
                  ),
                  onSubmitted: (_) => _finish(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tudo pronto. Vamos começar a sua melhor rotina.',
                  style: TextStyle(fontSize: 14, color: _obMuted, height: 1.65),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
