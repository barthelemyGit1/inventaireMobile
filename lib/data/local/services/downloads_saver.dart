import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Enregistre un fichier directement dans le dossier public "Téléchargements"
/// de l'appareil, via l'API MediaStore d'Android (aucune boîte de dialogue,
/// aucune permission supplémentaire nécessaire sur Android 10+).
///
/// Remplace file_saver, dont la méthode saveFile() écrit en réalité dans un
/// dossier privé à l'application (Android/data/<package>/files/), invisible
/// pour l'utilisateur — comportement documenté comme une limitation connue
/// du package, pas un bug côté app.
class DownloadsSaver {
  static const _channel = MethodChannel('inventaire_mtdpce/downloads');

  static Future<String> saveToDownloads({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final path = await _channel.invokeMethod<String>('saveToDownloads', {
      'fileName': fileName,
      'bytes': bytes,
      'mimeType': mimeType,
    });
    if (path == null) {
      throw Exception("Échec de l'enregistrement dans Téléchargements.");
    }
    return path;
  }
}