/// Constantes globales — évite de disperser des chaînes et valeurs magiques
/// dans les écrans.
class AppConstants {
  AppConstants._();

  // Identité
  static const String appName = 'Inventaire des biens Matériels';
  static const String organisation = 'MTDPCE';

  // Base de données
  static const String dbName = 'inventaire_mtdpce.db';
  static const int dbVersion = 1;
  static const String tableMateriels = 'materiels';
  static const String tableUsers = 'users';

  // Import / export
  static const List<String> allowedImportExtensions = ['xlsx', 'xls', 'csv'];
  static const String defaultExportFileName = 'inventaire_export';

   // Options fixes pour les champs à choix (écran Ajouter/modifier de bien)
  static const List<String> etatOptions = ['Bon', 'Passable', 'Mauvais'];
  static const List<String> presenceOptions = ['1 : trouvé', '0 : non trouvé'];

  // Sécurité
  static const String secureKeyPin = 'user_pin_hash';
  static const int minPasswordLength = 4;

  // Textes du guide rapide (écran Accueil)
  static const List<String> guideRapideSteps = [
    "Importer un fichier Excel (.xlsx, .xls)",
    "Consulter, ajouter ou modifier les enregistrements",
    "Exporter les données mises à jour",
  ];
}