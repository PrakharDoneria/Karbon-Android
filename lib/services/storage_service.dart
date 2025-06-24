import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';

class StorageService {
  static const _fileName = 'saved_project.json';

  static Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  static Future<void> saveProject(Project project) async {
    final filePath = await _getFilePath();
    final json = jsonEncode(project.toJson());
    await File(filePath).writeAsString(json);
  }

  static Future<Project?> loadProject() async {
    final filePath = await _getFilePath();
    final file = File(filePath);
    if (await file.exists()) {
      final json = await file.readAsString();
      return Project.fromJson(jsonDecode(json));
    }
    return null;
  }

  static Future<void> deleteProject() async {
    final filePath = await _getFilePath();
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
