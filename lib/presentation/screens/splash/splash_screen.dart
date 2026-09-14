import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/repositories/auth_repository.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

/// Écran de chargement affiché au démarrage de l'application.
/// Correspond à "Page de chargement" dans la maquette.
/// Redirige vers Inscription (premier lancement) ou Connexion (compte existant).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Petit délai pour laisser le splash s'afficher — purement visuel.
    await Future.delayed(const Duration(milliseconds: 600));
    final isRegistered = await AuthRepository().isRegistered();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isRegistered ? const LoginScreen() : const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add_check_rounded,
              size: 64,
              color: AppColors.primaryRed,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}