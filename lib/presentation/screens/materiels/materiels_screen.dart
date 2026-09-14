import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/models/materiel_model.dart';
import '../../../data/local/repositories/materiel_repository.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../import_export/import_screen.dart';
import '../import_export/export_screen.dart';
import 'add_materiel_screen.dart';

/// Liste des matériels inventoriés — écran "Matériels".
/// Permet la recherche, l'ajout, et l'édition d'un enregistrement existant.
class MaterielsScreen extends StatefulWidget {
  const MaterielsScreen({super.key});

  @override
  State<MaterielsScreen> createState() => _MaterielsScreenState();
}

class _MaterielsScreenState extends State<MaterielsScreen> {
  final _repository = MaterielRepository();
  final _searchController = TextEditingController();

  List<MaterielModel> _materiels = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMateriels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMateriels() async {
    setState(() => _isLoading = true);
    final result = _query.isEmpty
        ? await _repository.getAll()
        : await _repository.search(_query);
    if (!mounted) return;
    setState(() {
      _materiels = result;
      _isLoading = false;
    });
  }

  Future<void> _openAddOrEdit({MaterielModel? materiel}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddMaterielScreen(materiel: materiel)),
    );
    if (saved == true) _loadMateriels();
  }

  Future<void> _confirmDelete(MaterielModel materiel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce matériel ?'),
        content: Text('"${materiel.designation}" (${materiel.codeMateriel}) sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && materiel.id != null) {
      await _repository.delete(materiel.id!);
      _loadMateriels();
    }
  }

  void _onNavTap(int index) {
    if (index == 2) return; // déjà sur Matériels
    final screen = switch (index) {
      0 => const HomeScreen(),
      1 => const ImportScreen(),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: const [
                  Icon(Icons.inventory_2_rounded, color: AppColors.primaryRed, size: 24),
                  SizedBox(width: 8),
                  Text('Matériels', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher par code, désignation, service...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
                onChanged: (value) {
                  _query = value;
                  _loadMateriels();
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentYellow,
        foregroundColor: AppColors.textPrimary,
        onPressed: () => _openAddOrEdit(),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 2, onTap: _onNavTap),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_materiels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _query.isEmpty
                ? "Aucun matériel enregistré.\nUtilisez le bouton + pour en ajouter un."
                : "Aucun résultat pour « $_query ».",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
      itemCount: _materiels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final materiel = _materiels[index];
        return _MaterielListItem(
          materiel: materiel,
          onTap: () => _openAddOrEdit(materiel: materiel),
          onDelete: () => _confirmDelete(materiel),
        );
      },
    );
  }
}

class _MaterielListItem extends StatelessWidget {
  final MaterielModel materiel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MaterielListItem({
    required this.materiel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: materiel.exporte
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.accentYellow.withValues(alpha: 0.25),
          child: Icon(
            materiel.exporte ? Icons.cloud_done_rounded : Icons.pending_actions_rounded,
            size: 18,
            color: materiel.exporte ? AppColors.success : AppColors.accentYellowDark,
          ),
        ),
        title: Text(materiel.designation, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${materiel.codeMateriel} · ${materiel.serviceAffectation}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }
}