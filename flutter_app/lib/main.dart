import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_options.dart';
import 'l10n/app_lang.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/app.env');
    await AppLang.load();

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ).timeout(const Duration(seconds: 15));

    runApp(const FasalMitraApp());
  } catch (e, st) {
    debugPrint('STARTUP ERROR: $e\n$st');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Startup error:\n$e'),
            ),
          ),
        ),
      ),
    );
  }
}

class FasalMitraApp extends StatelessWidget {
  const FasalMitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FasalMitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _onboardingKey = 'onboarding_seen';

  bool _recovering = false;

  /// The splash screen stays up for a moment every time the app opens.
  bool _splashDone = false;

  /// null while the saved value is being read, then true or false.
  bool? _onboardingSeen;
  late final StreamSubscription<AuthState> _sub;

  @override
  void initState() {
    super.initState();
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _recovering = true);
      } else if (data.event == AuthChangeEvent.signedOut) {
        setState(() {
          _recovering = false;
          // After logging out, show the intro again when that option is on.
          if (AppOptions.showIntroEveryLaunch) _onboardingSeen = false;
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _splashDone = true);
    });
    _readOnboarding();
  }

  Future<void> _readOnboarding() async {
    var seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_onboardingKey) ?? false;
      if (AppOptions.showIntroEveryLaunch) seen = false;
    } catch (_) {
      // If the saved value cannot be read, skip the intro rather than block.
      seen = true;
    }
    if (mounted) setState(() => _onboardingSeen = seen);
  }

  Future<void> _finishOnboarding() async {
    setState(() => _onboardingSeen = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {
      // The intro may show once more next time; nothing else is affected.
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_recovering) {
      return ResetPasswordScreen(
        onDone: () => setState(() => _recovering = false),
      );
    }
    if (!_splashDone) return const SplashScreen();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return const HomeScreen();
        final seen = _onboardingSeen;
        if (seen == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!seen) return OnboardingScreen(onDone: _finishOnboarding);
        return const LoginScreen();
      },
    );
  }
}
