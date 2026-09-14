import 'package:flutter/material.dart';

/// Barre de navigation basse commune aux écrans Accueil, Importer,
/// Matériels, Exporter — reproduit le style vert de la maquette.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.file_download_rounded),
          label: 'Importer',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded),
          label: 'Matériels',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.file_upload_rounded),
          label: 'Exporter',
        ),
      ],
    );
  }
}