import '../core/database/database_helper.dart';

class CategoryService {
  static Future<List<Map<String, dynamic>>> getByType(String type) =>
      DatabaseHelper.instance.getCategories(type);

  static Future<int> insert(String name, String type, int color) =>
      DatabaseHelper.instance.insertCategory(name, type, color);

  static Future<int> update(int id, String name, int color) =>
      DatabaseHelper.instance.updateCategory(id, name, color);

  static Future<int> getOrCreate(String name, String type) =>
      DatabaseHelper.instance.getOrCreateCategory(name, type);
}
