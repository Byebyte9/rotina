import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

/// Banner compacto exibido nas telas principais quando o email ainda não foi
/// verificado. Permite reenviar o email com um toque.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _sending = false;
  bool _sent = false;

  Future<void> _resend() async {
    final token = context.read<AppState>().authToken;
    if (token == null) return;

    setState(() {
      _sending = true;
      _sent = false;
    });

    final result = await AuthService.resendVerification(token: token);

    if (!mounted) return;
    setState(() {
      _sending = false;
      _sent = result.ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B84B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8B84B).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, color: Color(0xFFE8B84B), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: _sent
                ? Text(
                    'Email enviado! Verifique sua caixa de entrada.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE8B84B),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  )
                : Text(
                    'Confirme seu email para maior segurança.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE8B84B),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
          ),
          if (!_sent) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _resend,
              child: _sending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFFE8B84B),
                      ),
                    )
                  : Text(
                      'Reenviar',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFE8B84B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFFE8B84B),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
