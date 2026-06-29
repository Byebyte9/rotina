import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_shell.dart';
import 'screens/verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await NotificationService.instance.init();
  runApp(const RotinaApp());
}

class RotinaApp extends StatelessWidget {
  const RotinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: const _RotinaRoot(),
    );
  }
}

class _RotinaRoot extends StatelessWidget {
  const _RotinaRoot();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final colors = state.isDark ? AppColors.dark : AppColors.light;

    return AppTheme(
      colors: colors,
      isDark: state.isDark,
      child: MaterialApp(
        title: 'Rotina.',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: state.isDark ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: colors.bg,
          colorScheme: ColorScheme(
            brightness: state.isDark ? Brightness.dark : Brightness.light,
            primary: colors.creamSoft,
            onPrimary: colors.bg,
            secondary: colors.green,
            onSecondary: Colors.white,
            error: colors.red,
            onError: Colors.white,
            surface: colors.surface,
            onSurface: colors.text,
          ),
          popupMenuTheme: PopupMenuThemeData(color: colors.card),
        ),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _AppFlow(),
      ),
    );
  }
}

/// Fluxo:
///   Splash
///   → sem token       → AuthScreen
///   → token + !verified → VerifyEmailScreen
///   → token + !onboarding → OnboardingScreen
///   → tudo ok         → HomeShell
class _AppFlow extends StatefulWidget {
  const _AppFlow();

  @override
  State<_AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<_AppFlow> {
  bool _showSplash = true;
  bool _isNewUser = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // 1. Splash
    if (!state.loaded || _showSplash) {
      return const SplashScreen();
    }

    // 2. Sem token → login/cadastro
    if (state.authToken == null) {
      return AuthScreen(
        onSuccess: ({required bool isNewUser}) {
          setState(() => _isNewUser = isNewUser);
        },
      );
    }

    // 3. Token mas email não verificado → bloqueia aqui sempre
    //    (tanto novo usuário quanto quem fechou o app antes de verificar)
    if (!state.emailVerified) {
      return VerifyEmailScreen(
        autoShow: true,
        onVerified: () => setState(() {}),
      );
    }

    // 4. Email verificado mas onboarding pendente
    if (!state.onboardingDone) {
      return OnboardingScreen(
        initialName: _isNewUser ? state.userName : null,
        onComplete: () => setState(() => _isNewUser = false),
      );
    }

    // 5. Tudo certo → app principal
    return const HomeShell();
  }
}
