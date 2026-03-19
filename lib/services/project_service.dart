import '../core/database/database_helper.dart';
import '../core/project_context.dart';
import '../models/project_model.dart';

class ProjectService {
  static Future<List<ProjectModel>> getAll() =>
      DatabaseHelper.instance.getAllProjects();

  static Future<ProjectModel?> getById(int id) =>
      DatabaseHelper.instance.getProjectById(id);

  static Future<ProjectModel?> getActiveProject() =>
      getById(ProjectContext.getActiveProjectId());

  static Future<String> getActiveCurrencyCode() async {
    final project = await getActiveProject();
    return project?.currencyCode ?? 'BRL';
  }

  static Future<int> insert(String name, String currencyCode) =>
      DatabaseHelper.instance.insertProject(name, currencyCode);

  static Future<int> update(int id, String name, String currencyCode) =>
      DatabaseHelper.instance.updateProject(id, name, currencyCode);

  static Future<int> delete(int id) =>
      DatabaseHelper.instance.deleteProject(id);
}
