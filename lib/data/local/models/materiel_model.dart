/// Représente un bien matériel inventorié (équipement informatique,
/// mobilier, véhicule, fourniture, appareil technique...).
/// Correspond aux champs de l'écran "Ajouter/modifier de bien".
class MaterielModel {
  final int? id;
  final String codeMateriel;
  final String designation;
  final String marqueType;
  final String etat;
  final double? valeur;
  final String presence;
  final String serviceAffectation;
  final String nomUtilisateur;
  final DateTime dateCreation;
  final DateTime dateModification;
  final bool exporte; // true si déjà inclus dans un export vers SIGCM

  MaterielModel({
    this.id,
    required this.codeMateriel,
    required this.designation,
    required this.marqueType,
    required this.etat,
    this.valeur,
    required this.presence,
    required this.serviceAffectation,
    required this.nomUtilisateur,
    DateTime? dateCreation,
    DateTime? dateModification,
    this.exporte = false,
  })  : dateCreation = dateCreation ?? DateTime.now(),
        dateModification = dateModification ?? DateTime.now();

  /// Conversion vers une Map pour insertion/mise à jour SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code_materiel': codeMateriel,
      'designation': designation,
      'marque_type': marqueType,
      'etat': etat,
      'valeur': valeur,
      'presence': presence,
      'service_affectation': serviceAffectation,
      'nom_utilisateur': nomUtilisateur,
      'date_creation': dateCreation.toIso8601String(),
      'date_modification': dateModification.toIso8601String(),
      'exporte': exporte ? 1 : 0,
    };
  }

  /// Construction depuis une ligne SQLite (Map).
  factory MaterielModel.fromMap(Map<String, dynamic> map) {
    return MaterielModel(
      id: map['id'] as int?,
      codeMateriel: map['code_materiel'] as String,
      designation: map['designation'] as String,
      marqueType: map['marque_type'] as String,
      etat: map['etat'] as String,
      valeur: (map['valeur'] as num?)?.toDouble(),
      presence: map['presence'] as String,
      serviceAffectation: map['service_affectation'] as String,
      nomUtilisateur: map['nom_utilisateur'] as String,
      dateCreation: DateTime.parse(map['date_creation'] as String),
      dateModification: DateTime.parse(map['date_modification'] as String),
      exporte: (map['exporte'] as int? ?? 0) == 1,
    );
  }

  /// Copie avec modification partielle — pratique pour l'écran d'édition.
  MaterielModel copyWith({
    int? id,
    String? codeMateriel,
    String? designation,
    String? marqueType,
    String? etat,
    double? valeur,
    String? presence,
    String? serviceAffectation,
    String? nomUtilisateur,
    DateTime? dateCreation,
    DateTime? dateModification,
    bool? exporte,
  }) {
    return MaterielModel(
      id: id ?? this.id,
      codeMateriel: codeMateriel ?? this.codeMateriel,
      designation: designation ?? this.designation,
      marqueType: marqueType ?? this.marqueType,
      etat: etat ?? this.etat,
      valeur: valeur ?? this.valeur,
      presence: presence ?? this.presence,
      serviceAffectation: serviceAffectation ?? this.serviceAffectation,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? DateTime.now(),
      exporte: exporte ?? this.exporte,
    );
  }
}