import '../core/database/database_helper.dart';

class CategoryService {
  static Future<List<Map<String, dynamic>>> getByType(String type) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'categories',
      where: 'type = ? AND (hidden = 0 OR hidden IS NULL)',
      whereArgs: [type],
    );
  }

  static Future<int> insert(String name, String type, int color) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'categories',
      {
        'name': name,
        'type': type,
        'color': color,
        'hidden': 0,
      },
    );
  }

  static Future<int> update(int id, String name, int color) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'categories',
      {'name': name, 'color': color},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> getOrCreate(String name, String type) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'categories',
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return await db.insert(
      'categories',
      {'name': name, 'type': type, 'hidden': 1},
    );
  }
}
