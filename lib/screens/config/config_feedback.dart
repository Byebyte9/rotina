import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../services/app_state.dart';
import '../../services/auth_service.dart';
import 'config_common.dart';

enum _FeedbackType { sugestao, bug, elogio, outro }

class ConfigFeedbackScreen extends StatefulWidget {
  const ConfigFeedbackScreen({super.key});

  @override
  State<ConfigFeedbackScreen> createState() => _ConfigFeedbackScreenState();
}

class _ConfigFeedbackScreenState extends State<ConfigFeedbackScreen> {
  _FeedbackType _type = _FeedbackType.sugestao;
  final _msgCtrl = TextEditingController();
  bool _sent = false;
  bool _sending = false;
  String? _error;

  static const _email = 'contact@rotina.life';

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;

    final token = context.read<AppState>().authToken;
    // BUG 25 fix: antes o código fazia `token: token ?? ''` e deixava o
    // servidor rejeitar com 401, mostrando só "Erro ao enviar feedback"
    // sem explicar o motivo real. Agora falha de forma explícita e clara
    // antes mesmo de tentar a requisição.
    if (token == null) {
      setState(() => _error = 'Você precisa estar logado para enviar feedback.');
      return;
    }

    setState(() { _sending = true; _error = null; });

    final result = await AuthService.sendFeedback(
      token: token,
      tipo: _type.name,
      mensagem: msg,
    );

    if (!mounted) return;
    if (result.ok) {
      setState(() { _sending = false; _sent = true; });
    } else {
      setState(() { _sending = false; _error = result.error; });
    }
  }

  void _reset() => setState(() { _sent = false; _msgCtrl.clear(); _type = _FeedbackType.sugestao; _error = null; });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);

    return ConfigSubScaffold(
      title: 'Feedback',
      children: [
        // Header emocional
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              Icon(Icons.favorite_outline_rounded, color: c.creamSoft, size: 32),
              const SizedBox(height: 10),
              Text(
                'Conte sua experiência',
                style: AppFonts.playfair(color: c.cream, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Tem uma sugestão? Encontrou um bug?\nConte pra gente — cada mensagem é lida.',
                style: AppFonts.inter(color: c.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        if (_sent) ...[
          _SentCard(onReset: _reset),
        ] else ...[
          // Tipo de feedback
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CfgSectionTitle('Tipo'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _FeedbackType.values.map((t) {
                    final selected = _type == t;
                    return GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? c.creamSoft : c.surface,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: selected ? c.creamSoft : c.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_typeIcon(t),
                                size: 13,
                                color: selected ? c.bg : c.textMuted),
                            const SizedBox(width: 5),
                            Text(
                              _typeLabel(t),
                              style: AppFonts.inter(
                                color: selected ? c.bg : c.textSoft,
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Mensagem
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CfgSectionTitle('Mensagem'),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 5,
                  maxLength: 500,
                  style: AppFonts.inter(color: c.text, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _hintText(_type),
                    hintStyle: AppFonts.inter(color: c.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: c.surface,
                    contentPadding: const EdgeInsets.all(12),
                    counterStyle: AppFonts.inter(color: c.textMuted, fontSize: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: c.creamSoft),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_error != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: c.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.red.withValues(alpha: 0.3)),
              ),
              child: Text(_error!,
                  style: AppFonts.inter(color: c.red, fontSize: 13)),
            ),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.creamSoft,
                foregroundColor: c.bg,
                disabledBackgroundColor: c.border,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.bg,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 15),
                        const SizedBox(width: 8),
                        Text('Enviar feedback',
                            style: AppFonts.inter(
                                color: c.bg, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Email direto
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CfgSectionTitle('Contato direto'),
                CfgRow(
                  label: 'E-mail',
                  sub: _email,
                  showBorder: false,
                  trailing: IconButton(
                    icon: Icon(Icons.copy_rounded, size: 16, color: c.textMuted),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: _email));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('E-mail copiado',
                              style: AppFonts.inter(color: c.cream, fontSize: 13)),
                          backgroundColor: c.card,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _typeLabel(_FeedbackType t) => switch (t) {
        _FeedbackType.sugestao => 'Sugestão',
        _FeedbackType.bug => 'Bug',
        _FeedbackType.elogio => 'Elogio',
        _FeedbackType.outro => 'Outro',
      };

  IconData _typeIcon(_FeedbackType t) => switch (t) {
        _FeedbackType.sugestao => Icons.lightbulb_outline,
        _FeedbackType.bug => Icons.bug_report_outlined,
        _FeedbackType.elogio => Icons.favorite_outline,
        _FeedbackType.outro => Icons.chat_bubble_outline,
      };

  String _hintText(_FeedbackType t) => switch (t) {
        _FeedbackType.sugestao =>
          'O que você adicionaria ou mudaria no Rotina?',
        _FeedbackType.bug =>
          'Descreva o que aconteceu e quando. Quanto mais detalhe, melhor!',
        _FeedbackType.elogio =>
          'O que você mais gosta no Rotina? 😊',
        _FeedbackType.outro =>
          'Pode falar à vontade...',
      };
}

class _SentCard extends StatelessWidget {
  final VoidCallback onReset;
  const _SentCard({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: c.green, size: 28),
          ),
          const SizedBox(height: 14),
          Text('Obrigado!',
              style: AppFonts.playfair(color: c.cream, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Seu feedback foi recebido.\nCada mensagem ajuda o Rotina a melhorar.',
            style: AppFonts.inter(color: c.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: onReset,
            child: Text('Enviar outro',
                style: AppFonts.inter(color: c.creamSoft, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
