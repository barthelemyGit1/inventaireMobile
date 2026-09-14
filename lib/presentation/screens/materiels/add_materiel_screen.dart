import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/models/materiel_model.dart';
import '../../../data/local/repositories/materiel_repository.dart';

/// Écran "Ajouter/modifier de bien" — sert à la fois pour la création
/// (materiel == null) et l'édition (materiel fourni) d'un enregistrement.
class AddMaterielScreen extends StatefulWidget {
  final MaterielModel? materiel;

  const AddMaterielScreen({super.key, this.materiel});

  bool get isEditing => materiel != null;

  @override
  State<AddMaterielScreen> createState() => _AddMaterielScreenState();
}

class _AddMaterielScreenState extends State<AddMaterielScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = MaterielRepository();

  late final _codeController = TextEditingController(text: widget.materiel?.codeMateriel);
  late final _designationController = TextEditingController(text: widget.materiel?.designation);
  late final _marqueController = TextEditingController(text: widget.materiel?.marqueType);
  late final _valeurController = TextEditingController(
    text: widget.materiel?.valeur != null ? widget.materiel!.valeur.toString() : '',
  );
  late final _serviceController = TextEditingController(text: widget.materiel?.serviceAffectation);
  late final _utilisateurController = TextEditingController(text: widget.materiel?.nomUtilisateur);

  String? _etatValue;
  String? _presenceValue;

  bool _isSaving = false;
  String? _errorMessage;

  late List<String> _etatItems;
  late List<String> _presenceItems;

  @override
  void initState() {
    super.initState();
    _etatItems = List.of(AppConstants.etatOptions);
    _presenceItems = List.of(AppConstants.presenceOptions);

    final etatExistant = widget.materiel?.etat;
    if (etatExistant != null && etatExistant.isNotEmpty && !_etatItems.contains(etatExistant)) {
      _etatItems.insert(0, etatExistant);
    }
    _etatValue = (etatExistant != null && etatExistant.isNotEmpty) ? etatExistant : null;

    final presenceExistante = widget.materiel?.presence;
    if (presenceExistante != null && presenceExistante.isNotEmpty && !_presenceItems.contains(presenceExistante)) {
      _presenceItems.insert(0, presenceExistante);
    }
    _presenceValue = (presenceExistante != null && presenceExistante.isNotEmpty) ? presenceExistante : null;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _designationController.dispose();
    _marqueController.dispose();
    _valeurController.dispose();
    _serviceController.dispose();
    _utilisateurController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final model = MaterielModel(
        id: widget.materiel?.id,
        codeMateriel: _codeController.text.trim(),
        designation: _designationController.text.trim(),
        marqueType: _marqueController.text.trim(),
        etat: _etatValue ?? '',
        valeur: double.tryParse(_valeurController.text.replaceAll(',', '.')),
        presence: _presenceValue ?? '',
        serviceAffectation: _serviceController.text.trim(),
        nomUtilisateur: _utilisateurController.text.trim(),
        dateCreation: widget.materiel?.dateCreation,
        exporte: widget.materiel?.exporte ?? false,
      );

      if (widget.isEditing) {
        await _repository.update(model);
      } else {
        await _repository.insert(model);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DatabaseUniqueCodeException {
      setState(() => _errorMessage = 'Ce code matériel existe déjà.');
    } catch (_) {
      setState(() => _errorMessage = "Impossible d'enregistrer. Vérifiez les champs (code déjà utilisé ?).");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                    ),
                    const Icon(Icons.edit_note_rounded, color: AppColors.primaryRed, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Modifier de bien' : 'Ajouter/modifier de bien',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildField(
                  label: 'Code matériel',
                  controller: _codeController,
                  hint: '233/34/43/...',
                  required: true,
                ),
                _buildField(
                  label: 'Designation',
                  controller: _designationController,
                  hint: 'Le ...',
                  required: true,
                ),
                _buildField(
                  label: 'Marque/type',
                  controller: _marqueController,
                  hint: 'Le ...',
                ),
                _buildDropdownField(
                  label: 'Etat',
                  value: _etatValue,
                  items: _etatItems,
                  onChanged: (value) => setState(() => _etatValue = value),
                  required: true,
                ),
                _buildField(
                  label: 'Valeur',
                  controller: _valeurController,
                  hint: 'Le ...',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                _buildDropdownField(
                  label: 'Présence',
                  value: _presenceValue,
                  items: _presenceItems,
                  onChanged: (value) => setState(() => _presenceValue = value),
                  required: true,
                ),
                _buildField(
                  label: "Service ou bureau d'affectation",
                  controller: _serviceController,
                  hint: 'DSI',
                ),
                _buildField(
                  label: "Nom de l'utilisateur",
                  controller: _utilisateurController,
                  hint: 'Ali Traoré',
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(widget.isEditing ? 'Modifier' : 'Ajouter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
            validator: required
                ? (value) => (value == null || value.trim().isEmpty) ? 'Champ requis' : null
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(),
            hint: const Text('Sélectionner...'),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
            validator: required ? (v) => v == null ? 'Champ requis' : null : null,
          ),
        ],
      ),
    );
  }
}

/// Exception dédiée si besoin de distinguer une violation de contrainte
/// unique (code_materiel déjà utilisé) d'une autre erreur SQLite.
class DatabaseUniqueCodeException implements Exception {}