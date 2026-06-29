import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

const _bg     = Color(0xFF1E1008);
const _cream  = Color(0xFFF5ECD7);
const _accent = Color(0xFFC4A882);
const _muted  = Color(0xFF8A6A4A);
const _dark   = Color(0xFF3D2512);
const _border = Color(0xFF5C3A20);
const _red    = Color(0xFFC45C4A);
const _green  = Color(0xFF7BAF6E);

/// Tela de verificação de email por código de 6 dígitos.
/// Exibida após cadastro (se [autoShow] == true) ou ao tocar no banner.
class VerifyEmailScreen extends StatefulWidget {
  /// Chamado quando o email for verificado com sucesso.
  final VoidCallback onVerified;

  /// Se true, a tela não tem botão de voltar (veio direto do cadastro).
  final bool autoShow;

  const VerifyEmailScreen({
    super.key,
    required this.onVerified,
    this.autoShow = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  // 6 controllers — um por dígito
  final List<TextEditingController> _ctrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());

  bool _loading   = false;
  bool _resending = false;
  String? _error;
  bool _resent    = false;

  // Cooldown para reenvio
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    for (final c in _ctrl) c.dispose();
    for (final f in _focus) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _code => _ctrl.map((c) => c.text).join();

  // ── Verificar ────────────────────────────────────────────────────────────────
  Future<void> _verify() async {
    final code = _code;
    if (code.length != 6) {
      setState(() => _error = 'Digite os 6 dígitos do código');
      return;
    }

    final token = context.read<AppState>().authToken;
    if (token == null) return;

    setState(() { _loading = true; _error = null; });

    final result = await AuthService.verifyEmailCode(token: token, code: code);

    if (!mounted) return;

    if (result.ok) {
      // Atualiza estado local
      await context.read<AppState>().markEmailVerified();
      widget.onVerified();
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
        // Limpa os campos para nova tentativa
        for (final c in _ctrl) c.clear();
        _focus[0].requestFocus();
      });
    }
  }

  // ── Reenviar ─────────────────────────────────────────────────────────────────
  Future<void> _resend() async {
    if (_resending || _cooldown > 0) return;

    final token = context.read<AppState>().authToken;
    if (token == null) return;

    setState(() { _resending = true; _resent = false; _error = null; });

    final result = await AuthService.resendVerification(token: token);

    if (!mounted) return;

    setState(() {
      _resending = false;
      _resent = result.ok;
      if (!result.ok) _error = result.error;
    });

    if (result.ok) {
      // Cooldown de 60s
      _cooldown = 60;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() { _cooldown--; });
        if (_cooldown <= 0) t.cancel();
      });
    }
  }

  // ── Digit field ───────────────────────────────────────────────────────────────
  Widget _digitField(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: RawKeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _ctrl[index].text.isEmpty &&
              index > 0) {
            _ctrl[index - 1].clear();
            _focus[index - 1].requestFocus();
          }
        },
        child: TextField(
          controller: _ctrl[index],
          focusNode: _focus[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          obscureText: false,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _cream,
            letterSpacing: 0,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _dark,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _ctrl[index].text.isNotEmpty ? _accent : _border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red, width: 1.5),
            ),
          ),
          onChanged: (val) {
            if (val.length == 1) {
              if (index < 5) {
                _focus[index + 1].requestFocus();
              } else {
                _focus[index].unfocus();
                _verify();
              }
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // Mascara o email: jo**@gmail.com
    final email = state.userEmail ?? '';
    final maskedEmail = _maskEmail(email);

    return Scaffold(
      backgroundColor: _bg,
      appBar: widget.autoShow
          ? null
          : AppBar(
              backgroundColor: _bg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _accent),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24, widget.autoShow ? 56 : 24, 24, 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo / título
              Text(
                'Rotina.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: _cream,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Confirme seu email',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: _cream,
                ),
              ),
              const SizedBox(height: 10),

              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: _muted,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: 'Enviamos um código de 6 dígitos para '),
                    TextSpan(
                      text: maskedEmail,
                      style: const TextStyle(color: _accent, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '. Digite-o abaixo para confirmar sua conta.'),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Campos de dígito
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _digitField),
              ),

              // ── Erro
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _error != null
                    ? Padding(
                        key: ValueKey(_error),
                        padding: const EdgeInsets.only(top: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: _red, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.inter(color: _red, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(key: ValueKey('no-error'), height: 14),
              ),

              const SizedBox(height: 28),

              // ── Botão confirmar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: _border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF1E1008),
                          ),
                        )
                      : Text(
                          'Verificar',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1008),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Reenviar
              Center(
                child: _resent
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              color: _green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Novo código enviado!',
                            style: GoogleFonts.inter(color: _green, fontSize: 13),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: (_resending || _cooldown > 0) ? null : _resend,
                        child: _resending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: _muted,
                                ),
                              )
                            : Text(
                                _cooldown > 0
                                    ? 'Reenviar em ${_cooldown}s'
                                    : 'Não recebi o código — Reenviar',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _cooldown > 0 ? _muted : _accent,
                                  decoration: _cooldown > 0
                                      ? TextDecoration.none
                                      : TextDecoration.underline,
                                  decorationColor: _accent,
                                ),
                              ),
                      ),
              ),

              const SizedBox(height: 32),

              // ── Aviso de segurança
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _dark,
                  border: Border(
                    left: BorderSide(color: _red.withValues(alpha: 0.7), width: 3),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: _red, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nunca compartilhe este código com ninguém. '
                        'A equipe do Rotina jamais pedirá seu código de verificação.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _muted,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pula verificação (só aparece se não for autoShow)
              if (!widget.autoShow) ...[
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Verificar depois',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: _muted,
                        decoration: TextDecoration.underline,
                        decorationColor: _muted,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _maskEmail(String email) {
    if (email.isEmpty) return '';
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final local = email.substring(0, at);
    final domain = email.substring(at);
    if (local.length <= 2) return '${local[0]}*$domain';
    return '${local.substring(0, 2)}${'*' * (local.length - 2)}$domain';
  }
}
