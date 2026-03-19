import '../core/database/database_helper.dart';
import '../core/project_context.dart';
import '../models/project_model.dart';

class ProjectService {
  static Future<List<ProjectModel>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'projects',
      orderBy: '"order" ASC, createdAt ASC',
    );
    return result.map((e) => ProjectModel.fromMap(e)).toList();
  }

  static Future<ProjectModel?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return ProjectModel.fromMap(result.first);
  }

  static Future<ProjectModel?> getActiveProject() =>
      getById(ProjectContext.getActiveProjectId());

  static Future<String> getActiveCurrencyCode() async {
    final project = await getActiveProject();
    return project?.currencyCode ?? 'BRL';
  }

  static Future<int> insert(String name, String currencyCode) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'projects',
      {
        'name': name,
        'currencyCode': currencyCode,
        'createdAt': DateTime.now().toIso8601String(),
        'order': 0,
      },
    );
  }

  static Future<int> update(int id, String name, String currencyCode) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'projects',
      {'name': name, 'currencyCode': currencyCode},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }
}
