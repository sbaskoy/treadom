import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_gate.dart';
import 'onboarding/onboarding_screen.dart';

/// Uygulamanın kök ekranı. İlk açılışta —giriş/kayıttan ÖNCE— "Nasıl oynanır"
/// tanıtımını bir kez gösterir; sonra (ve sonraki açılışlarda) oturum durumuna
/// göre giriş ya da harita ekranına geçen [AuthGate]'i gösterir.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  static const _seenKey = 'seenOnboarding';

  /// null = SharedPreferences henüz yüklenmedi.
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _seenOnboarding = prefs.getBool(_seenKey) ?? false);
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
    if (mounted) setState(() => _seenOnboarding = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_seenOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_seenOnboarding!) {
      return OnboardingScreen(onDone: _finishOnboarding);
    }
    return const AuthGate();
  }
}
