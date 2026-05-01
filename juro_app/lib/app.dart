import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/view/login_page.dart';
import 'features/home/view/home_page.dart';
import 'features/nutrition/view/voice_input_page.dart';
import 'features/onboarding/cubit/onboarding_cubit.dart';
import 'features/onboarding/view/onboarding_page.dart';
import 'features/report/view/report_page.dart';
import 'features/settings/view/settings_page.dart';

class JuroApp extends StatelessWidget {
  const JuroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JURO',
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ja', 'JP'),
      onGenerateRoute: _onGenerateRoute,
      home: const _StartupRouter(),
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/nutrition':
        return MaterialPageRoute(builder: (_) => const VoiceInputPage());
      case '/report':
        return MaterialPageRoute(builder: (_) => const ReportPage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}

/// 起動時ルーティング：未認証→ログイン / 初回→オンボーディング / 通常→ホーム
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    final authRepo = AuthRepository();
    final isLoggedIn = await authRepo.isLoggedIn();

    if (!isLoggedIn) {
      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed('/login');
      }
      return;
    }

    final onboarding = OnboardingCubit();
    final complete = await onboarding.isOnboardingComplete();

    if (!complete) {
      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed('/onboarding');
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
