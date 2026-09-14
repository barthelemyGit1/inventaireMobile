import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/models/materiel_model.dart';
import '../../../data/local/repositories/materiel_repository.dart';
import '../../../data/local/services/materiel_file_exporter.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../materiels/materiels_screen.dart';
import '../import_export/import_screen.dart';

/// Écran "Exporter un fichier excel" — génère un .xlsx à partir de la base
/// locale et le partage (SIGCM n'étant pas synchronisé en direct, l'agent
/// transmet le fichier par le canal de son choix : e-mail, clé USB, etc.).
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _repository = MaterielRepository();
  final _exporter = MaterielFileExporter();

  final _fileNameController = TextEditingController(text: 'inventaire_export');
  final _sheetNameController = TextEditingController(text: 'DSI');

  List<MaterielModel> _materiels = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMateriels();
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _sheetNameController.dispose();
    super.dispose();
  }

  Future<void> _loadMateriels() async {
    setState(() => _isLoading = true);
    final all = await _repository.getAll();
    if (!mounted) return;
    setState(() {
      _materiels = all;
      _isLoading = false;
    });
  }

  Future<void> _handleExport() async {
    if (_materiels.isEmpty) return;
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      final path = await _exporter.exportToFile(
        materiels: _materiels,
        fileName: _fileNameController.text,
        sheetName: _sheetNameController.text,
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Export inventaire MTDPCE',
        ),
      );

      // On ne marque comme exporté que si le partage a bien abouti,
      // pour éviter de considérer des lignes comme envoyées à tort.
      if (result.status == ShareResultStatus.success) {
        final ids = _materiels.where((m) => m.id != null).map((m) => m.id!).toList();
        await _repository.markAsExported(ids);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier exporté et partagé avec succès.')),
        );
        _loadMateriels();
      }
    } catch (e) {
      setState(() => _errorMessage = "Échec de l'export. Réessayez.");
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _onNavTap(int index) {
    if (index == 3) return; // déjà sur Exporter
    final screen = switch (index) {
      0 => const HomeScreen(),
      1 => const ImportScreen(),
      2 => const MaterielsScreen(),
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
              Row(
                children: const [
                  Icon(Icons.file_upload_rounded, color: AppColors.primaryRed, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exporter un fichier excel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildBaseDonneesCard(),
              const SizedBox(height: 16),
              _buildOptionsCard(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isExporting || _isLoading || _materiels.isEmpty) ? null : _handleExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_rounded, size: 20),
                  label: const Text('Telecharger le fichier excel'),
                ),
              ),
              if (_materiels.isEmpty && !_isLoading) ...[
                const SizedBox(height: 10),
                const Text(
                  "Aucun matériel enregistré à exporter pour le moment.",
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3, onTap: _onNavTap),
    );
  }

  Widget _buildBaseDonneesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Base de données locale', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _isLoading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Text(
                  '${_materiels.length}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
          const SizedBox(height: 2),
          Text(
            'Enregistrement  -  ${MaterielFileExporter.headers.length} colonnes',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Option d'export", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          const Text('Nom du fichier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _fileNameController,
            decoration: const InputDecoration(suffixText: '.xlsx'),
          ),
          const SizedBox(height: 14),
          const Text('Nom de la feuille', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(controller: _sheetNameController),
        ],
      ),
    );
  }
}