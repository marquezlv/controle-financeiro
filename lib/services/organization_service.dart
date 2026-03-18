import '../core/database/database_helper.dart';
import '../models/organization_model.dart';

class OrganizationService {
  static Future<List<OrganizationModel>> getAll() =>
      DatabaseHelper.instance.getAllOrganizations();

  static Future<int> insert(OrganizationModel organization) =>
      DatabaseHelper.instance.insertOrganization(organization);

  static Future<int> update(OrganizationModel organization) =>
      DatabaseHelper.instance.updateOrganization(organization);

  static Future<int> delete(int id) =>
      DatabaseHelper.instance.deleteOrganization(id);
}
