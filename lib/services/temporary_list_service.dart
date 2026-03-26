import '../core/database/database_helper.dart';
import '../core/project_context.dart';
import '../models/temporary_list_item_model.dart';
import '../models/temporary_list_model.dart';

class TemporaryListService {
  static Future<List<TemporaryListModel>> getAllLists() async {
    final db = await DatabaseHelper.instance.database;
    final projectId = ProjectContext.getActiveProjectId();
    final rows = await db.query(
      'lists',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(TemporaryListModel.fromMap).toList();
  }

  static Future<int> createList(String? rawName) async {
    final db = await DatabaseHelper.instance.database;
    final projectId = ProjectContext.getActiveProjectId();
    final name = await _resolveListName(rawName, projectId: projectId);

    return db.insert('lists', {
      'name': name,
      'projectId': projectId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> deleteList(int listId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('list_items', where: 'listId = ?', whereArgs: [listId]);
    return db.delete('lists', where: 'id = ?', whereArgs: [listId]);
  }

  static Future<List<TemporaryListItemModel>> getItems(int listId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'list_items',
      where: 'listId = ?',
      whereArgs: [listId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(TemporaryListItemModel.fromMap).toList();
  }

  static Future<int> addItem(int listId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Item name is required');
    }

    final db = await DatabaseHelper.instance.database;
    return db.insert('list_items', {
      'listId': listId,
      'name': trimmed,
      'completed': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<int> setItemCompleted(int itemId, bool completed) async {
    final db = await DatabaseHelper.instance.database;
    return db.update(
      'list_items',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  static Future<int> deleteItem(int itemId) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('list_items', where: 'id = ?', whereArgs: [itemId]);
  }

  static Future<String> _resolveListName(
    String? rawName, {
    required int projectId,
  }) async {
    final trimmed = rawName?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM lists WHERE projectId = ?',
      [projectId],
    );
    final count = (result.first['total'] as int? ?? 0) + 1;
    return 'List $count';
  }
}
