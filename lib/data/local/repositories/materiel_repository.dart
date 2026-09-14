import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/materiel_model.dart';
import '../../../core/constants/app_constants.dart';

/// Toute la logique d'accès aux données "matériels" passe par ici.
/// Les écrans appellent ce repository — jamais sqflite directement.
class MaterielRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(MaterielModel materiel) async {
    final db = await _dbHelper.database;
    return db.insert(
      AppConstants.tableMateriels,
      materiel.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(MaterielModel materiel) async {
    final db = await _dbHelper.database;
    return db.update(
      AppConstants.tableMateriels,
      materiel.copyWith(dateModification: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [materiel.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      AppConstants.tableMateriels,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<MaterielModel>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableMateriels,
      orderBy: 'date_modification DESC',
    );
    return maps.map((m) => MaterielModel.fromMap(m)).toList();
  }

  Future<MaterielModel?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableMateriels,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return MaterielModel.fromMap(maps.first);
  }

  /// Recherche simple par code, désignation ou service — pour une future
  /// barre de recherche sur l'écran Matériels.
  Future<List<MaterielModel>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      AppConstants.tableMateriels,
      where: 'code_materiel LIKE ? OR designation LIKE ? OR service_affectation LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date_modification DESC',
    );
    return maps.map((m) => MaterielModel.fromMap(m)).toList();
  }

  /// Nombre total de matériels — utilisé pour la carte "Nombre d'export" du tableau de bord.
  Future<int> countAll() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableMateriels}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Nombre de matériels pas encore exportés — sert pour le badge d'export en attente.
  Future<int> countNonExportes() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableMateriels} WHERE exporte = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Nombre de matériels déjà exportés — carte "Nombre d'export" du tableau de bord.
  Future<int> countExportes() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableMateriels} WHERE exporte = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Marque un lot de matériels comme exportés après un export réussi vers SIGCM.
  Future<void> markAsExported(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await _dbHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE ${AppConstants.tableMateriels} SET exporte = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  /// Insertion en lot — utilisée par l'écran Import.
  /// Les lignes dont le code matériel existe déjà sont ignorées (pas d'échec
  /// global) et comptabilisées séparément grâce à ConflictAlgorithm.ignore.
  Future<ImportResult> insertBatch(List<MaterielModel> materiels) async {
    final db = await _dbHelper.database;
    int inserted = 0;
    int skipped = 0;

    await db.transaction((txn) async {
      for (final materiel in materiels) {
        final id = await txn.insert(
          AppConstants.tableMateriels,
          materiel.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        // sqflite renvoie 0 lorsque l'insertion a été ignorée (conflit d'unicité).
        if (id == 0) {
          skipped++;
        } else {
          inserted++;
        }
      }
    });

    return ImportResult(inserted: inserted, skippedDuplicates: skipped);
  }
}

/// Résultat d'un import en lot — nombre de lignes réellement insérées
/// vs ignorées car le code matériel existait déjà.
class ImportResult {
  final int inserted;
  final int skippedDuplicates;

  ImportResult({required this.inserted, required this.skippedDuplicates});
}