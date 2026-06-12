import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../map/map_screen.dart';
import 'login_screen.dart';

/// Oturum durumuna göre doğru ekranı gösteren kök yönlendirici.
///
/// Firebase Auth oturumu cihazda sakladığı için bu akış, uygulama yeniden
/// açıldığında kullanıcı giriş yapmışsa doğrudan ana ekranı gösterir
/// (oturum hatırlama).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // İlk durum belirlenene kadar kısa bir yükleniyor göstergesi.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Oturum açıksa ana ekran, değilse giriş ekranı.
        if (snapshot.hasData) {
          return const MapScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
