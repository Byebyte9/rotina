import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/deleting_overlay.dart';
import 'config_common.dart';
import '../change_password_screen.dart';

class ConfigPerfilScreen extends StatefulWidget {
  const ConfigPerfilScreen({super.key});

  @override
  State<ConfigPerfilScreen> createState() => _ConfigPerfilScreenState();
}

class _ConfigPerfilScreenState extends State<ConfigPerfilScreen> {
  late TextEditingController nameCtrl;
  bool savedMsg = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: context.read<AppState>().userName);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  String _formatSecs(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    return h > 0 ? '${h}h${m > 0 ? '${m}m' : ''}' : '${m}m';
  }

  Future<void> _save(AppState state) async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    await state.updateUserName(name);
    setState(() => savedMsg = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => savedMsg = false);
    });
  }

  Future<void> _pickAndCropAvatar(AppState state) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    if (!mounted) return;

    final c = AppTheme.of(context);
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          toolbarColor: c.bg,
          toolbarWidgetColor: c.cream,
          backgroundColor: c.bg,
          activeControlsWidgetColor: c.creamSoft,
          cropFrameColor: c.creamSoft,
          cropGridColor: c.border,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: const [CropAspectRatioPreset.square],
        ),
      ],
    );
    if (cropped == null) return;

    await state.setAvatarPath(cropped.path);
    if (mounted) setState(() {});
  }

  Future<void> _removeAvatar(AppState state) async {
    await state.setAvatarPath(null);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final state = context.watch<AppState>();
    final name = state.userName.isNotEmpty ? state.userName : 'Sem nome';
    final avatarLetter = state.userName.isNotEmpty ? state.userName[0].toUpperCase() : '?';
    final hasAvatar = state.avatarPath != null && File(state.avatarPath!).existsSync();

    return ConfigSubScaffold(
      title: 'Perfil',
      children: [
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _pickAndCropAvatar(state),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.border),
                        image: hasAvatar
                            ? DecorationImage(image: FileImage(File(state.avatarPath!)), fit: BoxFit.cover)
                            : null,
                      ),
                      child: hasAvatar
                          ? null
                          : Text(avatarLetter,
                              style: AppFonts.playfair(color: c.cream, fontSize: 28, fontWeight: FontWeight.w600)),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 10,
                      child: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.creamSoft,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.bg, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, size: 13, color: c.bg),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasAvatar)
                TextButton(
                  onPressed: () => _removeAvatar(state),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: Text('Remover foto', style: TextStyle(color: c.red, fontSize: 11)),
                ),
              Text(name, style: AppFonts.playfair(color: c.cream, fontSize: 18)),
              const SizedBox(height: 20),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Identidade'),
              Text('SEU NOME',
                  style: AppFonts.inter(color: c.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                maxLength: 30,
                style: AppFonts.inter(color: c.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Como quer ser chamado?',
                  hintStyle: AppFonts.inter(color: c.textMuted, fontSize: 14),
                  counterText: '',
                  filled: true,
                  fillColor: c.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _save(state),
                  icon: const Icon(Icons.check, size: 13),
                  label: const Text('Salvar nome'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.creamSoft,
                    foregroundColor: c.bg,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              if (savedMsg)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text('Nome atualizado ✓',
                        style: TextStyle(color: c.green, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Aparência'),
              CfgRow(
                label: 'Modo escuro',
                sub: 'Fundo café, texto creme',
                showBorder: false,
                trailing: CfgToggle(
                  value: state.isDark,
                  onChanged: (_) => state.toggleTheme(),
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Estatísticas pessoais'),
              CfgRow(label: 'Tarefas criadas', trailing: CfgValue('${state.tasks.length}')),
              CfgRow(label: 'Metas ativas', trailing: CfgValue('${state.metas.length}')),
              CfgRow(
                  label: 'Foco acumulado',
                  trailing: CfgValue(state.focusSeconds > 0 ? _formatSecs(state.focusSeconds) : '0m')),
              CfgRow(
                label: 'Maior streak',
                showBorder: false,
                trailing: CfgValue(
                  '${state.metas.isEmpty ? 0 : state.metas.map((m) => m.streak).reduce((a, b) => a > b ? a : b)} 🔥',
                  color: c.gold,
                ),
              ),
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CfgSectionTitle('Conta'),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ));
                  },
                  icon: Icon(Icons.lock_outline_rounded, size: 16, color: c.creamSoft),
                  label: const Text('Alterar senha'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.creamSoft,
                    side: BorderSide(color: c.creamSoft),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Captura o navigator raiz ANTES do confirm abrir
                    // (o confirm faz pop() de si mesmo antes de chamar onConfirm,
                    // então o context do onConfirm já é o da tela principal)
                    final rootNav = Navigator.of(context);
                    showAppConfirm(
                      context,
                      icon: ConfirmIconType.warning,
                      iconData: Icons.logout_rounded,
                      title: 'Sair da conta?',
                      body: 'Você será desconectado. Seus dados locais continuam salvos no aparelho.',
                      confirmLabel: 'Sim, sair',
                      danger: false,
                      onConfirm: () async {
                        await showDeletingOverlay(
                          rootNav.context,
                          () => state.logout(),
                          label: 'Saindo...',
                        );
                        rootNav.popUntil((route) => route.isFirst);
                      },
                    );
                  },
                  icon: Icon(Icons.logout_rounded, size: 16, color: c.gold),
                  label: const Text('Sair da conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.gold,
                    side: BorderSide(color: c.gold),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final rootNav = Navigator.of(context);
                    showAppConfirm(
                      context,
                      icon: ConfirmIconType.danger,
                      iconData: Icons.person_remove_outlined,
                      title: 'Excluir sua conta?',
                      body:
                          'Todos os seus dados — tarefas, metas e histórico — serão apagados permanentemente. Esta ação não pode ser desfeita.',
                      confirmLabel: 'Sim, excluir tudo',
                      onConfirm: () async {
                        await showDeletingOverlay(
                          rootNav.context,
                          () => state.deleteAccount(),
                          label: 'Apagando conta...',
                        );
                        rootNav.popUntil((route) => route.isFirst);
                      },
                    );
                  },
                  icon: Icon(Icons.person_remove_outlined, size: 16, color: c.red),
                  label: const Text('Excluir conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.red,
                    side: BorderSide(color: c.red),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
