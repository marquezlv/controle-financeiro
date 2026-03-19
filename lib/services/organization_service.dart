import '../core/database/database_helper.dart';
import '../core/project_context.dart';
import '../models/organization_model.dart';

class OrganizationService {
  static Future<List<OrganizationModel>> getAll() =>
      getByProject(ProjectContext.getActiveProjectId());

  static Future<List<OrganizationModel>> getByProject(int projectId) =>
      DatabaseHelper.instance.getOrganizationsByProject(projectId);

  static Future<int> insert(OrganizationModel organization) =>
      DatabaseHelper.instance.insertOrganization(organization);

  static Future<int> update(OrganizationModel organization) =>
      DatabaseHelper.instance.updateOrganization(organization);

  static Future<int> edit(OrganizationModel organization) =>
      update(organization);

  static Future<int> delete(int id) =>
      DatabaseHelper.instance.deleteOrganization(id);
}
