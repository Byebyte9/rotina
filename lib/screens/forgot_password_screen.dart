import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

const _bg     = Color(0xFF1E1008);
const _cream  = Color(0xFFF5ECD7);
const _accent = Color(0xFFC4A882);
const _muted  = Color(0xFF8A6A4A);
const _dark   = Color(0xFF3D2512);
const _border = Color(0xFF5C3A20);
const _red    = Color(0xFFC45C4A);
const _green  = Color(0xFF7BAF6E);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _enviado = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Informe seu email');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final result = await AuthService.forgotPassword(email: email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.ok) {
      setState(() => _enviado = true);
    } else {
      setState(() => _errorMsg = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: _accent, size: 18),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _enviado ? _buildSucesso() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        Text(
          'Esqueceu a senha?',
          style: GoogleFonts.playfairDisplay(
            color: _cream,
            fontSize: 26,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Informe o email da sua conta e enviaremos\num link para redefinir a senha.',
          style: GoogleFonts.inter(color: _muted, fontSize: 14, height: 1.6),
        ),

        const SizedBox(height: 36),

        _label('EMAIL'),
        const SizedBox(height: 6),
        _textField(
          controller: _emailCtrl,
          hint: 'seu@email.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _submit(),
        ),

        if (_errorMsg != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        ],

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _bg,
              disabledBackgroundColor: _accent.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _bg),
                  )
                : Text(
                    'Enviar link',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSucesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: _green, size: 32),
        ),

        const SizedBox(height: 24),

        Text(
          'Email enviado!',
          style: GoogleFonts.playfairDisplay(
            color: _cream,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          'Se este email estiver cadastrado, você receberá um link em breve.\n\nVerifique também sua pasta de spam.',
          style: GoogleFonts.inter(color: _muted, fontSize: 14, height: 1.6),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _dark,
              foregroundColor: _cream,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: _border),
              ),
              elevation: 0,
            ),
            child: Text(
              'Voltar ao login',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: _border,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    void Function(String)? onSubmitted,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        onSubmitted: onSubmitted,
        style: GoogleFonts.inter(color: _cream, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: _muted, fontSize: 14),
          filled: true,
          fillColor: _dark,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
}
