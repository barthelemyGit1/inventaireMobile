import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'presentation/screens/splash/splash_screen.dart';

/// Widget racine de l'application. Le routage détaillé (routes/app_routes.dart)
/// sera branché ici une fois les écrans créés.
class InventaireMtdpceApp extends StatelessWidget {
  const InventaireMtdpceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}