import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _atualCtrl   = TextEditingController();
  final _novaCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _atualVisible   = false;
  bool _novaVisible    = false;
  bool _confirmVisible = false;
  bool _loading        = false;
  String? _errorMsg;
  bool _sucesso = false;

  @override
  void dispose() {
    _atualCtrl.dispose();
    _novaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validarSenha(String s) {
    if (s.length < 8) return 'Mínimo de 8 caracteres';
    if (!s.contains(RegExp(r'[A-Z]'))) return 'Precisa ter ao menos uma letra maiúscula';
    if (!s.contains(RegExp(r'[!@#\$%^&*(),.?\":{}|<>_\-+=\[\]\\/]')))
      return 'Precisa ter ao menos um caractere especial';
    return null;
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final token = state.authToken;
    if (token == null) return;

    final atual   = _atualCtrl.text;
    final nova    = _novaCtrl.text;
    final confirm = _confirmCtrl.text;

    if (atual.isEmpty) {
      setState(() => _errorMsg = 'Informe sua senha atual');
      return;
    }
    final erroSenha = _validarSenha(nova);
    if (erroSenha != null) {
      setState(() => _errorMsg = erroSenha);
      return;
    }
    if (nova != confirm) {
      setState(() => _errorMsg = 'As senhas não coincidem');
      return;
    }
    if (atual == nova) {
      setState(() => _errorMsg = 'A nova senha deve ser diferente da atual');
      return;
    }

    setState(() { _loading = true; _errorMsg = null; });

    final result = await AuthService.changePassword(
      token: token,
      senhaAtual: atual,
      novaSenha: nova,
    );

    if (!mounted) return;
    if (result.ok) {
      setState(() { _loading = false; _sucesso = true; });
    } else {
      setState(() {
        _loading = false;
        _errorMsg = result.error ?? 'Erro ao alterar a senha.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.cream, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Alterar senha',
            style: GoogleFonts.inter(color: c.cream, fontSize: 16, fontWeight: FontWeight.w500)),
      ),
      body: SafeArea(
        child: _sucesso ? _buildSucesso(c) : _buildForm(c),
      ),
    );
  }

  Widget _buildSucesso(AppColors c) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: c.green, size: 64),
          const SizedBox(height: 20),
          Text('Senha alterada!',
              style: AppFonts.playfair(color: c.cream, fontSize: 24)),
          const SizedBox(height: 12),
          Text('Sua senha foi atualizada com sucesso.',
              textAlign: TextAlign.center,
              style: AppFonts.inter(color: c.textMuted, fontSize: 14)),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.creamSoft,
                foregroundColor: c.bg,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Voltar',
                  style: AppFonts.inter(color: c.bg, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informe sua senha atual e escolha uma nova.',
              style: AppFonts.inter(color: c.textMuted, fontSize: 14).copyWith(height: 1.5)),
          const SizedBox(height: 28),

          _label('SENHA ATUAL', c),
          const SizedBox(height: 6),
          _textField(c,
            controller: _atualCtrl,
            hint: 'Sua senha atual',
            obscure: !_atualVisible,
            suffix: _eyeBtn(c, _atualVisible,
                () => setState(() => _atualVisible = !_atualVisible)),
          ),

          const SizedBox(height: 18),
          _label('NOVA SENHA', c),
          const SizedBox(height: 6),
          _textField(c,
            controller: _novaCtrl,
            hint: 'Crie uma senha forte',
            obscure: !_novaVisible,
            suffix: _eyeBtn(c, _novaVisible,
                () => setState(() => _novaVisible = !_novaVisible)),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 18),
          _label('CONFIRMAR NOVA SENHA', c),
          const SizedBox(height: 6),
          _textField(c,
            controller: _confirmCtrl,
            hint: 'Repita a nova senha',
            obscure: !_confirmVisible,
            suffix: _eyeBtn(c, _confirmVisible,
                () => setState(() => _confirmVisible = !_confirmVisible)),
            onChanged: (_) => setState(() {}),
          ),
          if (_confirmCtrl.text.isNotEmpty && _confirmCtrl.text != _novaCtrl.text)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text('As senhas não coincidem',
                  style: TextStyle(color: c.red, fontSize: 12)),
            ),

          if (_errorMsg != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.red.withOpacity(0.3)),
              ),
              child: Text(_errorMsg!, style: TextStyle(color: c.red, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.creamSoft,
                foregroundColor: c.bg,
                disabledBackgroundColor: c.creamSoft.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: c.bg))
                  : Text('Alterar senha',
                      style: AppFonts.inter(color: c.bg, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t, AppColors c) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t, style: AppFonts.inter(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600).copyWith(letterSpacing: 1)),
  );

  Widget _textField(AppColors c, {
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onChanged,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    onChanged: onChanged,
    style: AppFonts.inter(color: c.text, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppFonts.inter(color: c.textMuted, fontSize: 14),
      filled: true,
      fillColor: c.surface,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.creamSoft)),
    ),
  );

  Widget _eyeBtn(AppColors c, bool visible, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.only(right: 12),
      child: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: c.textMuted, size: 18)),
  );
}
