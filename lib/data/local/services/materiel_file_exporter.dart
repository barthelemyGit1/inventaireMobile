import 'dart:io';
import 'dart:typed_data';
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

  /// Construit le classeur Excel en mémoire et retourne ses octets bruts.
  /// Ne touche pas le disque — à utiliser avec file_saver pour un
  /// enregistrement direct (Téléchargements sur Android) sans passer par
  /// un fichier temporaire.
  Uint8List buildExcelBytes({
    required List<MaterielModel> materiels,
    required String sheetName,
  }) {
    final workbook = excel_pkg.Excel.createExcel();

    final resolvedSheetName = sheetName.trim().isEmpty ? 'Inventaire' : sheetName.trim();
    final defaultSheetName = workbook.getDefaultSheet()!;
    workbook.rename(defaultSheetName, resolvedSheetName);
    final sheet = workbook[resolvedSheetName];

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
    return Uint8List.fromList(bytes);
  }

  /// Écrit le classeur dans le répertoire temporaire de l'application et
  /// retourne le chemin complet. Conservé pour les cas où un vrai fichier
  /// sur disque est nécessaire (ex. partage via share_plus) plutôt qu'un
  /// enregistrement direct.
  Future<String> exportToFile({
    required List<MaterielModel> materiels,
    required String fileName,
    required String sheetName,
  }) async {
    final bytes = buildExcelBytes(materiels: materiels, sheetName: sheetName);

    final directory = await getTemporaryDirectory();
    final safeName = fileName.trim().isEmpty ? 'inventaire_export' : fileName.trim();
    final path = '${directory.path}/$safeName.xlsx';

    final file = File(path);
    await file.writeAsBytes(bytes);
    return path;
  }
}