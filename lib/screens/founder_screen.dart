import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _bg = Color(0xFF1E1008);
const _cream = Color(0xFFF5ECD7);
const _accent = Color(0xFFC8541E);
const _gold = Color(0xFFD4A843);
const _muted = Color(0xFF8A6A4A);
const _card = Color(0xFF2C1A0E);
const _border = Color(0xFF5C3A20);

/// Tela exibida uma única vez após o onboarding para usuários que
/// são um dos 200 Fundadores do Rotina.
class FounderScreen extends StatefulWidget {
  final String userName;
  final int position;
  final VoidCallback onContinue;

  const FounderScreen({
    super.key,
    required this.userName,
    required this.position,
    required this.onContinue,
  });

  @override
  State<FounderScreen> createState() => _FounderScreenState();
}

class _FounderScreenState extends State<FounderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _firstName {
    final parts = widget.userName.trim().split(' ');
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Ícone / medalha
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _card,
                      border: Border.all(color: _gold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.25),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 42,
                      color: _gold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Título
                  Text(
                    'Parabéns, $_firstName!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: _cream,
                      fontSize: 30,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Badge de posição
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.15),
                      border: Border.all(color: _accent.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Usuário #${widget.position} de 200',
                      style: GoogleFonts.inter(
                        color: _accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Texto principal
                  Text(
                    'Você é um dos Fundadores do Rotina.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _cream,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Card de benefícios
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _card,
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seus benefícios',
                          style: GoogleFonts.inter(
                            color: _gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _benefit(
                          Icons.star_rounded,
                          'Premium gratuito para sempre',
                        ),
                        const SizedBox(height: 12),
                        _benefit(
                          Icons.record_voice_over_rounded,
                          'Preferência nas opiniões sobre o app',
                        ),
                        const SizedBox(height: 12),
                        _benefit(
                          Icons.rocket_launch_rounded,
                          'Acesso prioritário a novas funcionalidades',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nota de rodapé
                  Text(
                    'Caso haja novas funcionalidades, seus benefícios podem melhorar ainda mais.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Botão continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Começar',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: _cream,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
