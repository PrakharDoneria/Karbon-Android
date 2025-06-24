import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String?> exportHtmlFile(String name, String htmlContent) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$name.html';
      final file = File(filePath);
      await file.writeAsString(htmlContent);
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
