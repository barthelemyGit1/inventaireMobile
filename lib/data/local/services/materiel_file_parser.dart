import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import '../models/materiel_model.dart';

/// Résultat du parsing d'un fichier d'import : lignes valides prêtes à
/// insérer, et lignes ignorées avec la raison (pour affichage à l'agent).
class ParseResult {
  final List<MaterielModel> valides;
  final List<SkippedRow> ignorees;
  final int totalLignes;

  ParseResult({
    required this.valides,
    required this.ignorees,
    required this.totalLignes,
  });
}

class SkippedRow {
  final int numeroLigne;
  final String raison;
  SkippedRow(this.numeroLigne, this.raison);
}

/// Levée quand le fichier n'a pas de colonne "code matériel" reconnaissable —
/// on ne peut pas continuer sans identifiant.
class ColonneCodeIntrouvableException implements Exception {
  final String message;
  ColonneCodeIntrouvableException([
    this.message =
        "Impossible de trouver une colonne « Code matériel » dans le fichier.",
  ]);
}

/// Lit un fichier .xlsx/.xls/.csv et le transforme en liste de MaterielModel.
/// La première ligne doit contenir les en-têtes de colonnes ; leur ordre
/// et leur casse n'ont pas d'importance grâce à la normalisation des noms.
///
/// IMPORTANT : tous les alias listés ci-dessous doivent être écrits sous
/// leur forme déjà normalisée (minuscules, sans accents, sans espaces ni
/// ponctuation) — c'est à cette forme qu'ils sont comparés. Écrire un alias
/// avec une majuscule, un espace ou une apostrophe ne matchera jamais rien.
class MaterielFileParser {
  static const Map<String, List<String>> _headerAliases = {
    'code': ['codemateriel', 'code'],
    'designation': ['designation', 'design'],
    'marque': ['marquetype', 'marque', 'type'],
    'etat': ['etat'],
    'valeur': ['valeur', 'valeurfcfa', 'prix'],
    'presence': ['presence'],
    'service': [
      'serviceoubureaudaffectation',
      'servicedaffectation',
      'bureaudaffectation',
      'serviceaffectation',
      'service',
      'bureau',
    ],
    'utilisateur': [
      'nomdelutilisateur',
      'nomdutilisateur',
      'nomutilisateur',
      'utilisateur',
      'agent',
    ],
  };

  // Mots-clés de secours : si aucun alias exact ne correspond, on accepte
  // tout en-tête normalisé qui CONTIENT l'un de ces mots-clés. Couvre les
  // formulations non prévues ("Affecté à", "Poste utilisateur", etc.).
  static const Map<String, List<String>> _keywordFallbacks = {
    'service': ['service', 'bureau', 'affectation', 'direction'],
    'utilisateur': ['utilisateur', 'agent', 'employe', 'proprietaire'],
  };

  String _normalize(String value) {
    var s = value.toLowerCase().trim();
    const accents = {
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'à': 'a',
      'â': 'a',
      'ô': 'o',
      'î': 'i',
      'ï': 'i',
      'û': 'u',
      'ù': 'u',
      'ç': 'c',
    };
    accents.forEach((from, to) => s = s.replaceAll(from, to));
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Construit la correspondance {champ -> index de colonne} à partir de
  /// la ligne d'en-têtes brute. Essaie d'abord une correspondance exacte
  /// (alias connus), puis une correspondance par mot-clé pour les champs
  /// dont la formulation varie le plus dans les fichiers réels.
  Map<String, int> _mapColumns(List<String> headers) {
    final normalized = headers.map(_normalize).toList();
    final columnIndex = <String, int>{};

    _headerAliases.forEach((field, aliases) {
      for (var i = 0; i < normalized.length; i++) {
        if (aliases.contains(normalized[i])) {
          columnIndex[field] = i;
          break;
        }
      }
    });

    _keywordFallbacks.forEach((field, keywords) {
      if (columnIndex.containsKey(field)) return; // déjà trouvé par alias exact
      for (var i = 0; i < normalized.length; i++) {
        if (keywords.any((k) => normalized[i].contains(k))) {
          columnIndex[field] = i;
          break;
        }
      }
    });

    return columnIndex;
  }

  String _cellToString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<ParseResult> parseFile(String path) async {
    final extension = path.split('.').last.toLowerCase();
    late List<List<dynamic>> rows;

    if (extension == 'csv') {
      rows = _parseCsv(path);
    } else if (extension == 'xlsx' || extension == 'xls') {
      rows = _parseExcel(path);
    } else {
      throw Exception('Format de fichier non supporté : .$extension');
    }

    if (rows.isEmpty) {
      return ParseResult(valides: [], ignorees: [], totalLignes: 0);
    }

    final headers = rows.first.map((h) => h.toString()).toList();
    final columnIndex = _mapColumns(headers);

    if (!columnIndex.containsKey('code')) {
      throw ColonneCodeIntrouvableException();
    }

    final dataRows = rows.skip(1).toList();
    final valides = <MaterielModel>[];
    final ignorees = <SkippedRow>[];

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      final numeroLigne =
          i + 2; // +2 : ligne 1 = en-têtes, index humain à partir de 1

      String cellAt(String field) {
        final idx = columnIndex[field];
        if (idx == null || idx >= row.length) return '';
        return _cellToString(row[idx]);
      }

      final code = cellAt('code');
      final designation = cellAt('designation');

      if (code.isEmpty) {
        ignorees.add(SkippedRow(numeroLigne, 'Code matériel manquant'));
        continue;
      }
      if (designation.isEmpty) {
        ignorees.add(SkippedRow(numeroLigne, 'Désignation manquante'));
        continue;
      }

      valides.add(
        MaterielModel(
          codeMateriel: code,
          designation: designation,
          marqueType: cellAt('marque'),
          etat: cellAt('etat'),
          valeur: double.tryParse(cellAt('valeur').replaceAll(',', '.')),
          presence: cellAt('presence'),
          serviceAffectation: cellAt('service'),
          nomUtilisateur: cellAt('utilisateur'),
        ),
      );
    }

    return ParseResult(
      valides: valides,
      ignorees: ignorees,
      totalLignes: dataRows.length,
    );
  }

  /// Parseur CSV maison : gère les champs entre guillemets, les guillemets
  /// échappés (""), les fins de ligne \n / \r\n, sans dépendance externe.
  List<List<dynamic>> _parseCsv(String path) {
    final content = File(path).readAsStringSync();
    final rows = <List<dynamic>>[];
    var currentRow = <dynamic>[];
    var currentField = StringBuffer();
    var insideQuotes = false;

    void addField() {
      currentRow.add(currentField.toString());
      currentField = StringBuffer();
    }

    void addRow() {
      addField();
      rows.add(currentRow);
      currentRow = <dynamic>[];
    }

    for (var i = 0; i < content.length; i++) {
      final character = content[i];

      if (character == '"') {
        if (insideQuotes && i + 1 < content.length && content[i + 1] == '"') {
          currentField.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (character == ',' && !insideQuotes) {
        addField();
      } else if ((character == '\n' || character == '\r') && !insideQuotes) {
        if (character == '\r' &&
            i + 1 < content.length &&
            content[i + 1] == '\n') {
          i++;
        }
        addRow();
      } else {
        currentField.write(character);
      }
    }

    if (currentField.length > 0 || currentRow.isNotEmpty) {
      addRow();
    }
    return rows;
  }

  List<List<dynamic>> _parseExcel(String path) {
    final bytes = File(path).readAsBytesSync();
    final workbook = excel_pkg.Excel.decodeBytes(bytes);
    final sheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[sheetName]!;

    return sheet.rows
        .map((row) => row.map((cell) => cell?.value ?? '').toList())
        .where((row) => row.any((cell) => cell.toString().trim().isNotEmpty))
        .toList();
  }
}