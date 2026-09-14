import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:path_provider/path_provider.dart';
import '../models/materiel_model.dart';

/// Colonnes exportées, dans l'ordre — reflète les champs de
/// l'écran "Ajouter/modifier de bien" pour rester cohérent avec l'import.
class MaterielFileExporter {
  static const List<String> headers = [
    'Code matériel',
    'Désignation',
    'Marque/type',
    'Etat',
    'Valeur',
    'Présence',
    'Service ou bureau d\'affectation',
    "Nom de l'utilisateur",
  ];

  /// Construit le classeur Excel et l'écrit dans le répertoire temporaire
  /// de l'application. Retourne le chemin complet du fichier généré.
  Future<String> exportToFile({
    required List<MaterielModel> materiels,
    required String fileName,
    required String sheetName,
  }) async {
    final workbook = excel_pkg.Excel.createExcel();

    final defaultSheetName = workbook.getDefaultSheet()!;
    workbook.rename(defaultSheetName, sheetName.isEmpty ? 'Inventaire' : sheetName);
    final sheet = workbook[sheetName.isEmpty ? 'Inventaire' : sheetName];

    sheet.appendRow(headers.map((h) => excel_pkg.TextCellValue(h)).toList());

    for (final m in materiels) {
      sheet.appendRow([
        excel_pkg.TextCellValue(m.codeMateriel),
        excel_pkg.TextCellValue(m.designation),
        excel_pkg.TextCellValue(m.marqueType),
        excel_pkg.TextCellValue(m.etat),
        m.valeur != null
            ? excel_pkg.DoubleCellValue(m.valeur!)
            : excel_pkg.TextCellValue(''),
        excel_pkg.TextCellValue(m.presence),
        excel_pkg.TextCellValue(m.serviceAffectation),
        excel_pkg.TextCellValue(m.nomUtilisateur),
      ]);
    }

    final bytes = workbook.save();
    if (bytes == null) {
      throw Exception('Échec de la génération du fichier Excel.');
    }

    final directory = await getTemporaryDirectory();
    final safeName = fileName.trim().isEmpty ? 'inventaire_export' : fileName.trim();
    final path = '${directory.path}/$safeName.xlsx';

    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }
}