import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Pied de page affiché en bas des écrans d'authentification :
/// "Inventaire des biens Matériels" / "MTDPCE".
class AppFooterBrand extends StatelessWidget {
  const AppFooterBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          AppConstants.appName,
          style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 13, 134, 2)),
        ),
        const SizedBox(height: 2),
        const Text(
          AppConstants.organisation,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}