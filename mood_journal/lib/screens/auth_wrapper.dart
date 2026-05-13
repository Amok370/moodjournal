import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../main.dart';

/// Firebase Auth durumuna göre Login veya Ana ekranı gösterir.
///
/// [authStateChanges] stream'i dinlenerek kullanıcı giriş/çıkış
/// yaptığında otomatik olarak ilgili ekrana yönlendirilir.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı beklenirken loading göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoading();
        }

        // Kullanıcı oturum açmışsa ana navigasyona yönlendir
        if (snapshot.hasData && snapshot.data != null) {
          return const MainNavigation();
        }

        // Oturum yoksa login ekranını göster
        return const LoginScreen();
      },
    );
  }
}

/// Uygulama ilk açılışında gösterilen splash/loading ekranı.
class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1123), const Color(0xFF151735)]
                : [const Color(0xFFEEF0FF), const Color(0xFFF5F7FF)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}
