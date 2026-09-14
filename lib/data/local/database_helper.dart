import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

/// Point d'accès unique à la base SQLite locale.
/// Toutes les requêtes passent par ce singleton — aucun repository
/// n'ouvre sa propre connexion.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade, // à ajouter si le schéma évolue plus tard
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableMateriels} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_materiel TEXT NOT NULL,
        designation TEXT NOT NULL,
        marque_type TEXT,
        etat TEXT,
        valeur REAL,
        presence TEXT,
        service_affectation TEXT,
        nom_utilisateur TEXT,
        date_creation TEXT NOT NULL,
        date_modification TEXT NOT NULL,
        exporte INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Index pour accélérer la recherche par code matériel (souvent unique)
    await db.execute('''
      CREATE UNIQUE INDEX idx_code_materiel
      ON ${AppConstants.tableMateriels} (code_materiel)
    ''');
  }

  /// Utilitaire de test/réinitialisation — à ne jamais exposer dans l'UI finale.
  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete(AppConstants.tableMateriels);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}