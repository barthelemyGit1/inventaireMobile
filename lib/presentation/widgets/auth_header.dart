import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// En-tête visuel des écrans d'authentification : icône cadenas dans un
/// cercle rouge, titre "ACCESS SECURISE" et sous-titre explicatif.
class AuthHeader extends StatelessWidget {
  final String subtitle;

  const AuthHeader({
    super.key,
    this.subtitle = "Saisissez votre code PIN pour accéder à l'application",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColors.primaryRed,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_rounded, color: Colors.white, size: 44),
        ),
        const SizedBox(height: 20),
        const Text(
          'ACCES SECURISE',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}