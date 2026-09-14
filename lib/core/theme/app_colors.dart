import 'package:flutter/material.dart';

/// Palette de couleurs de l'application Inventaire MTDPCE.
/// Reprend les trois couleurs dominantes de la maquette :
/// rouge (en-têtes, icônes), jaune (actions principales), vert (navigation).
class AppColors {
  AppColors._();

  // Rouge — en-têtes, icônes, actions "danger"/import-export
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryRedDark = Color(0xFFB71C1C);

  // Jaune — boutons d'action principale (Valider, Ajouter, Télécharger)
  static const Color accentYellow = Color(0xFFF5C518);
  static const Color accentYellowDark = Color(0xFFD4A70A);

  // Vert — barre de navigation basse
  static const Color navGreen = Color(0xFF3C8B3C);
  static const Color navGreenActive = Color(0xFF2E6B2E);

  // Neutres
  static const Color background = Color(0xFFFAFAFA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color inputFill = Color(0xFFF0F0F0);

  // États
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFF9A825);
}