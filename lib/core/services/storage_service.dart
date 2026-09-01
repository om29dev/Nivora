import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/config/app_config.dart';
import '../models/project.dart';

class StorageService {
  Directory? _baseDir;

  Future<Directory> getBaseDirectory() async {
    if (_baseDir != null) return _baseDir!;
    final appDocDir = await getApplicationDocumentsDirectory();
    final nivoraDir = Directory(p.join(appDocDir.path, 'Nivora'));
    if (!await nivoraDir.exists()) {
      await nivoraDir.create(recursive: true);
    }
    _baseDir = nivoraDir;
    return nivoraDir;
  }

  Future<Directory> getProjectsDirectory() async {
    final base = await getBaseDirectory();
    final projectsDir = Directory(p.join(base.path, AppConfig.projectsDirName));
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir;
  }

  Future<Directory> getIndexesDirectory() async {
    final base = await getBaseDirectory();
    final indexesDir = Directory(p.join(base.path, AppConfig.indexesDirName));
    if (!await indexesDir.exists()) {
      await indexesDir.create(recursive: true);
    }
    return indexesDir;
  }

  Future<List<Project>> getRecentProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(AppConfig.prefRecentProjects) ?? [];

    final projects = <Project>[];
    for (final jsonStr in jsonList) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        projects.add(Project.fromJson(map));
      } catch (_) {}
    }
    return projects;
  }

  Future<void> saveProject(Project project) async {
    final projects = await getRecentProjects();
    final existingIndex = projects.indexWhere((p) => p.id == project.id);
    if (existingIndex >= 0) {
      projects[existingIndex] = project;
    } else {
      projects.insert(0, project);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = projects.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(AppConfig.prefRecentProjects, encoded);
  }

  Future<void> deleteProject(String projectId) async {
    final projects = await getRecentProjects();
    final project = projects.firstWhere((p) => p.id == projectId, orElse: () => projects.first);

    // Delete filesystem folder if exists
    try {
      final dir = Directory(project.path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}

    projects.removeWhere((p) => p.id == projectId);
    final prefs = await SharedPreferences.getInstance();
    final encoded = projects.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList(AppConfig.prefRecentProjects, encoded);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConfig.prefOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.prefOnboardingCompleted, completed);
  }
}
