import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/repositories/materiel_repository.dart';
import '../../../data/local/services/last_import_info.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../auth/login_screen.dart';
import '../materiels/materiels_screen.dart';
import '../import_export/import_screen.dart';
import '../import_export/export_screen.dart';

/// Tableau de bord — écran "Accueil" de la maquette.
/// Affiche les compteurs d'import/export et le guide rapide.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _materielRepository = MaterielRepository();
  final _lastImportStore = LastImportInfoStore();

  int? _totalImportes;
  int? _totalExportes;
  LastImportInfo? _lastImport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // NOTE : "Nombre d'import" est ici approximé par le total de matériels
    // enregistrés localement, et "Nombre d'export" par ceux déjà marqués
    // comme exportés. À ajuster si un suivi par opération (fichier importé/
    // exporté) est nécessaire plutôt qu'un suivi par enregistrement.
    final total = await _materielRepository.countAll();
    final exportes = await _materielRepository.countExportes();
    final lastImport = await _lastImportStore.read();
    if (!mounted) return;
    setState(() {
      _totalImportes = total;
      _totalExportes = exportes;
      _lastImport = lastImport;
      _isLoading = false;
    });
  }

  void _handleDeconnexion() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    if (index == 0) return; // déjà sur Accueil
    final screen = switch (index) {
      1 => const ImportScreen(),
      2 => const MaterielsScreen(),
      3 => const ExportScreen(),
      _ => const HomeScreen(),
    };
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildInventaireCard(),
              const SizedBox(height: 20),
              _buildGuideRapideCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0, onTap: _onNavTap),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.home_rounded, color: AppColors.primaryRed, size: 26),
            SizedBox(width: 8),
            Text(
              'Tableau de bord',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _handleDeconnexion,
          icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.primaryRed),
          label: const Text(
            'Déconnecter',
            style: TextStyle(fontSize: 12, color: AppColors.primaryRed),
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
      ],
    );
  }

  Widget _buildInventaireCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inventaire matériels',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: "Nombre d'import",
                        value: '${_totalImportes ?? 0}',
                        icon: Icons.add_box_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: "Nombre d'export",
                        value: '${_totalExportes ?? 0}',
                        icon: Icons.remove_red_eye_rounded,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dernier import',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  _lastImport == null ? 'Aucun import effectué' : _lastImport!.fileName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_lastImport != null)
                  Text(
                    _formatDate(_lastImport!.date),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final jour = date.day.toString().padLeft(2, '0');
    final mois = date.month.toString().padLeft(2, '0');
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$jour/$mois/${date.year} à $heure:$minute';
  }

  Widget _buildGuideRapideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guide Rapide',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < AppConstants.guideRapideSteps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppConstants.guideRapideSteps[i],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}