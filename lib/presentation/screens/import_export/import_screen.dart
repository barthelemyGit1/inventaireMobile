import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/repositories/materiel_repository.dart';
import '../../../data/local/services/materiel_file_parser.dart';
import '../../../data/local/services/last_import_info.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../materiels/materiels_screen.dart';
import '../import_export/export_screen.dart';

enum _ImportStep { selection, apercu, resultat }

/// Écran "Importer un fichier excel" — sélection d'un fichier .xlsx/.xls/.csv,
/// aperçu du nombre de lignes valides/ignorées, puis import en base locale.
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _parser = MaterielFileParser();
  final _repository = MaterielRepository();
  final _lastImportStore = LastImportInfoStore();

  _ImportStep _step = _ImportStep.selection;
  String? _fileName;
  String? _filePath;
  bool _isProcessing = false;
  String? _errorMessage;

  ParseResult? _parseResult;
  ImportResult? _importResult;

  Future<void> _pickFile() async {
    setState(() => _errorMessage = null);
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: AppConstants.allowedImportExtensions,
    );
    if (file == null || file.path == null) return;

    final path = file.path!;
    setState(() {
      _fileName = file.name;
      _filePath = path;
      _isProcessing = true;
    });

    try {
      final parsed = await _parser.parseFile(path);
      if (!mounted) return;
      setState(() {
        _parseResult = parsed;
        _step = _ImportStep.apercu;
      });
    } on ColonneCodeIntrouvableException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e, stack) {
      debugPrint('Erreur import fichier: $e');
      debugPrint('$stack');
      setState(() => _errorMessage = "Impossible de lire ce fichier. Vérifiez le format et réessayez.");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmerImport() async {
    if (_parseResult == null) return;
    setState(() => _isProcessing = true);
    try {
      final result = await _repository.insertBatch(_parseResult!.valides);
      await _lastImportStore.save(
        fileName: _fileName ?? 'Fichier importé',
        date: DateTime.now(),
      );
      if (!mounted) return;
      setState(() {
        _importResult = result;
        _step = _ImportStep.resultat;
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _recommencer() {
    setState(() {
      _step = _ImportStep.selection;
      _fileName = null;
      _filePath = null;
      _parseResult = null;
      _importResult = null;
      _errorMessage = null;
    });
  }

  void _onNavTap(int index) {
    if (index == 1) return; // déjà sur Importer
    final screen = switch (index) {
      0 => const HomeScreen(),
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
              Row(
                children: const [
                  Icon(Icons.file_upload_rounded, color: AppColors.primaryRed, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Importer un fichier excel',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              switch (_step) {
                _ImportStep.selection => _buildSelectionCard(),
                _ImportStep.apercu => _buildApercuCard(),
                _ImportStep.resultat => _buildResultatCard(),
              },
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 1, onTap: _onNavTap),
    );
  }

  Widget _buildSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Selectionner un fichier', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Formats acceptés : ${AppConstants.allowedImportExtensions.join(", ")}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _pickFile, child: const Text('Parcourir')),
            ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildApercuCard() {
    final result = _parseResult!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(_fileName ?? '', overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Divider(height: 28),
          _buildStatRow('Lignes lues', '${result.totalLignes}'),
          _buildStatRow('Lignes valides', '${result.valides.length}', color: AppColors.success),
          _buildStatRow('Lignes ignorées', '${result.ignorees.length}', color: AppColors.warning),
          if (result.ignorees.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Détail des lignes ignorées :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ...result.ignorees.take(5).map(
                  (r) => Text(
                    '· Ligne ${r.numeroLigne} : ${r.raison}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
            if (result.ignorees.length > 5)
              Text(
                '... et ${result.ignorees.length - 5} autre(s)',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _recommencer,
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isProcessing || result.valides.isEmpty) ? null : _confirmerImport,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Importer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultatCard() {
    final result = _importResult!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
          const SizedBox(height: 14),
          Text(
            '${result.inserted} matériel(s) importé(s)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          if (result.skippedDuplicates > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${result.skippedDuplicates} ignoré(s) — code matériel déjà existant',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _recommencer, child: const Text('Importer un autre fichier')),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}