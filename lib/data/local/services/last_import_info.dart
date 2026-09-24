import 'package:shared_preferences/shared_preferences.dart';

/// Petite information persistée localement (pas dans SQLite, pas de valeur
/// métier) : nom et date du dernier fichier importé — affichée sur le
/// tableau de bord ("Dernier import").
class LastImportInfo {
  final String fileName;
  final DateTime date;

  LastImportInfo({required this.fileName, required this.date});
}

class LastImportInfoStore {
  static const _keyFileName = 'last_import_file_name';
  static const _keyDate = 'last_import_date';

  Future<void> save({required String fileName, required DateTime date}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFileName, fileName);
    await prefs.setString(_keyDate, date.toIso8601String());
  }

  Future<LastImportInfo?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final fileName = prefs.getString(_keyFileName);
    final dateString = prefs.getString(_keyDate);
    if (fileName == null || dateString == null) return null;

    final date = DateTime.tryParse(dateString);
    if (date == null) return null;

    return LastImportInfo(fileName: fileName, date: date);
  }
}