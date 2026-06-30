import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';

// Mesmas cores do onboarding/splash para consistência visual
const _bg = Color(0xFF1E1008);
const _cream = Color(0xFFF5ECD7);
const _accent = Color(0xFFC4A882);
const _muted = Color(0xFF8A6A4A);
const _dark = Color(0xFF3D2512);
const _border = Color(0xFF5C3A20);
const _red = Color(0xFFC45C4A);
const _green = Color(0xFF7BAF6E);

class AuthScreen extends StatefulWidget {
  /// Chamado após auth bem-sucedido.
  /// [isNewUser] = true se acabou de se cadastrar (vai pro onboarding).
  final void Function({required bool isNewUser}) onSuccess;

  const AuthScreen({super.key, required this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Controla se está na aba Login ou Cadastro
  bool _isLogin = true;

  late TabController _tabCtrl;

  // Campos compartilhados
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  // Só cadastro
  final _confirmSenhaCtrl = TextEditingController();

  bool _senhaVisible   = false;
  bool _confirmVisible = false;
  bool _loading        = false;
  String? _errorMsg;
  bool _termsAccepted  = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() {
          _isLogin = _tabCtrl.index == 0;
          _errorMsg = null;
          // BUG 22 fix: limpa os campos de senha ao trocar de aba.
          // Mantém o email preenchido (é razoável reaproveitar), mas senha e
          // confirmação não devem vazar de um contexto (cadastro) para outro
          // (login) nem ficar acumuladas se o usuário ficar trocando de aba.
          _senhaCtrl.clear();
          _confirmSenhaCtrl.clear();
          _senhaVisible = false;
          _confirmVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmSenhaCtrl.dispose();
    super.dispose();
  }

  // ── Validação de senha ──────────────────────────────────────────────────────

  String? _validarSenha(String senha) {
    if (senha.length < 8) return 'Mínimo de 8 caracteres';
    if (!senha.contains(RegExp(r'[A-Z]'))) return 'Precisa ter ao menos uma letra maiúscula';
    if (!senha.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'))) {
      return 'Precisa ter ao menos um caractere especial';
    }
    return null;
  }

  bool get _senhaValida => _validarSenha(_senhaCtrl.text) == null;
  bool get _confirmValida => _confirmSenhaCtrl.text == _senhaCtrl.text;

  // Indicadores visuais de força da senha (para cadastro)
  List<_SenhaReq> get _requisitos => [
        _SenhaReq('8 ou mais caracteres', _senhaCtrl.text.length >= 8),
        _SenhaReq('Letra maiúscula', _senhaCtrl.text.contains(RegExp(r'[A-Z]'))),
        _SenhaReq(
          'Caractere especial',
          _senhaCtrl.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]')),
        ),
      ];

  // ── Ações ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() => _errorMsg = 'Preencha email e senha');
      return;
    }

    if (!_isLogin) {
      final erroSenha = _validarSenha(senha);
      if (erroSenha != null) {
        setState(() => _errorMsg = erroSenha);
        return;
      }
      if (!_confirmValida) {
        setState(() => _errorMsg = 'As senhas não coincidem');
        return;
      }
      if (!_termsAccepted) {
        setState(() => _errorMsg = 'Aceite os Termos de Uso e Política de Privacidade para continuar');
        return;
      }
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final state = context.read<AppState>();
    AuthResult result;

    if (_isLogin) {
      result = await AuthService.login(email: email, senha: senha);
    } else {
      // No cadastro passamos o email como nome temporário;
      // o nome real é definido no onboarding a seguir.
      result = await AuthService.register(
        email: email,
        senha: senha,
        nome: email.split('@').first,
      );
    }

    if (!mounted) return;

    if (result.success) {
      await state.saveAuthSession(
        result.token!,
        result.user!,
        isNewUser: !_isLogin,
      );
      widget.onSuccess(isNewUser: !_isLogin);
    } else {
      setState(() {
        _loading = false;
        _errorMsg = result.error;
      });
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 52),

              // Logo
              RichText(
                text: TextSpan(
                  style: GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 48,
                    color: _cream,
                    height: 1,
                  ),
                  children: const [
                    TextSpan(text: 'Rotina'),
                    TextSpan(text: '.', style: TextStyle(color: _accent)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sua vida em um app.',
                style: TextStyle(fontSize: 13, color: _muted, letterSpacing: 0.4),
              ),

              const SizedBox(height: 40),

              // Abas Login / Cadastro
              Container(
                decoration: BoxDecoration(
                  color: _dark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: _bg,
                  unselectedLabelColor: _muted,
                  labelStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
                  indicator: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'Entrar'),
                    Tab(text: 'Criar conta'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Campo Email
              _label('EMAIL'),
              const SizedBox(height: 6),
              _textField(
                controller: _emailCtrl,
                hint: 'seu@email.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),

              const SizedBox(height: 18),

              // Campo Senha
              _label('SENHA'),
              const SizedBox(height: 6),
              _textField(
                controller: _senhaCtrl,
                hint: _isLogin ? 'Sua senha' : 'Crie uma senha forte',
                obscure: !_senhaVisible,
                suffix: _visibilityBtn(
                  visible: _senhaVisible,
                  onTap: () => setState(() => _senhaVisible = !_senhaVisible),
                ),
                onChanged: (_) => setState(() {}),
              ),

              // Indicadores de força (só no cadastro)
              if (!_isLogin) ...[
                const SizedBox(height: 10),
                ..._requisitos.map((r) => _ReqRow(req: r)),
              ],

              // Campo confirmar senha (só no cadastro)
              if (!_isLogin) ...[
                const SizedBox(height: 18),
                _label('CONFIRMAR SENHA'),
                const SizedBox(height: 6),
                _textField(
                  controller: _confirmSenhaCtrl,
                  hint: 'Repita a senha',
                  obscure: !_confirmVisible,
                  suffix: _visibilityBtn(
                    visible: _confirmVisible,
                    onTap: () =>
                        setState(() => _confirmVisible = !_confirmVisible),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_confirmSenhaCtrl.text.isNotEmpty && !_confirmValida)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 2),
                    child: Text(
                      'As senhas não coincidem',
                      style: TextStyle(color: _red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                _TermsCheckbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v),
                ),
              ],

              // Esqueci a senha
              if (_isLogin) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                    child: Text(
                      'Esqueci minha senha',
                      style: GoogleFonts.inter(
                        color: _accent.withValues(alpha: 0.7),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: _accent.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Mensagem de erro
              if (_errorMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: _red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botão principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _bg,
                    disabledBackgroundColor: _accent.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _bg,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Entrar' : 'Criar conta',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 28),
              const _TermsLinks(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers de UI ───────────────────────────────────────────────────────────

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: _border,
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    Iterable<String>? autofillHints,
    void Function(String)? onChanged,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        onChanged: onChanged,
        onSubmitted: (_) => _submit(),
        style: GoogleFonts.inter(color: _cream, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: _muted, fontSize: 14),
          filled: true,
          fillColor: _dark,
          suffixIcon: suffix,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
      );

  Widget _visibilityBtn({required bool visible, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _muted,
            size: 18,
          ),
        ),
      );
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SenhaReq {
  final String label;
  final bool ok;
  const _SenhaReq(this.label, this.ok);
}

class _ReqRow extends StatelessWidget {
  final _SenhaReq req;
  const _ReqRow({super.key, required this.req});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(
            req.ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 14,
            color: req.ok ? _green : _muted,
          ),
          const SizedBox(width: 7),
          Text(
            req.label,
            style: TextStyle(
              fontSize: 12,
              color: req.ok ? _green : _muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Links de termos (usados em Login e Cadastro) ─────────────────────────────

class _TermsLinks extends StatelessWidget {
  const _TermsLinks();

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
              style: GoogleFonts.inter(
                  color: _muted, fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: _muted)),
        ),
        Text('  ·  ', style: GoogleFonts.inter(color: _muted, fontSize: 12)),
        GestureDetector(
          onTap: () => _open('https://byebyte9.github.io/rotina-site/privacidade.html'),
          child: Text('Política de Privacidade',
              style: GoogleFonts.inter(
                  color: _muted, fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: _muted)),
        ),
      ],
    );
  }
}

// ── Checkbox de aceite de termos (só no Cadastro) ────────────────────────────

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TermsCheckbox({required this.value, required this.onChanged});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: _accent,
              checkColor: _bg,
              side: const BorderSide(color: _border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              children: [
                Text('Estou de acordo com os ',
                    style: GoogleFonts.inter(color: _muted, fontSize: 12, height: 1.5)),
                GestureDetector(
                  onTap: () => _open('https://byebyte9.github.io/rotina-site/termos.html'),
                  child: Text('Termos de Uso',
                      style: GoogleFonts.inter(
                          color: _accent, fontSize: 12, height: 1.5,
                          decoration: TextDecoration.underline,
                          decorationColor: _accent)),
                ),
                Text(' e ',
                    style: GoogleFonts.inter(color: _muted, fontSize: 12, height: 1.5)),
                GestureDetector(
                  onTap: () => _open('https://byebyte9.github.io/rotina-site/privacidade.html'),
                  child: Text('Política de Privacidade',
                      style: GoogleFonts.inter(
                          color: _accent, fontSize: 12, height: 1.5,
                          decoration: TextDecoration.underline,
                          decorationColor: _accent)),
                ),
                Text('.',
                    style: GoogleFonts.inter(color: _muted, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
