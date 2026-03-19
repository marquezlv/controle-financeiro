import '../core/database/database_helper.dart';
import '../core/project_context.dart';
import '../models/organization_model.dart';

class OrganizationService {
  static Future<List<OrganizationModel>> getAll() =>
      getByProject(ProjectContext.getActiveProjectId());

  static Future<List<OrganizationModel>> getByProject(int projectId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'organizations',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'createdAt DESC',
    );
    return result.map((e) => OrganizationModel.fromMap(e)).toList();
  }

  static Future<int> insert(OrganizationModel organization) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('organizations', organization.toMap());
  }

  static Future<int> update(OrganizationModel organization) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'organizations',
      organization.toMap(),
      where: 'id = ?',
      whereArgs: [organization.id],
    );
  }

  static Future<int> edit(OrganizationModel organization) =>
      update(organization);

  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('organizations', where: 'id = ?', whereArgs: [id]);
  }
}
