import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class BackupFileManager {
  /// Generate file name in the requested format: Artha_Backup_${today.date(dd-mm-yyyy)}.json
  static String getBackupFileName() {
    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    return 'Artha_Backup_$dateStr.json';
  }

  /// Trigger download/save of backup JSON
  static Future<bool> downloadBackupJson(String jsonContent) async {
    final fileName = getBackupFileName();
    final bytes = Uint8List.fromList(utf8.encode(jsonContent));

    try {
      final uri = await FilePickerPlatform.instance.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'application/json',
      );

      if (kIsWeb) {
        return true;
      }
      return uri != null;
    } catch (e) {
      debugPrint('Error saving backup file: $e');
      return false;
    }
  }

  /// Pick JSON file and return decoded string
  static Future<String?> pickAndReadBackupJson() async {
    try {
      final List<PlatformFile> files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty) {
        final pickedFile = files.first;
        final bytes = await pickedFile.readAsBytes();
        return utf8.decode(bytes);
      }
    } catch (e) {
      debugPrint('Error picking backup file: $e');
    }
    return null;
  }
}
