import '../core/database/database_helper.dart';
import '../core/project_context.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static Future<List<TransactionModel>> getAll() =>
      getByProject(ProjectContext.getActiveProjectId());

  static Future<List<TransactionModel>> getByProject(int projectId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''
  SELECT 
    t.*,
    c.name as categoryName,
    c.color as categoryColor
  FROM transactions t
  LEFT JOIN categories c 
  ON c.id = t.categoryId
  WHERE t.projectId = ?
  ORDER BY t.date DESC
  ''',
      [projectId],
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  static Future<int> insert(TransactionModel transaction) async {
    if (transaction.projectId == 1) {
      transaction.projectId = ProjectContext.getActiveProjectId();
    }
    final db = await DatabaseHelper.instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  static Future<int> update(TransactionModel transaction) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> deleteGroup(String groupId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'transactions',
      where: 'installmentGroupId = ? OR recurrenceGroupId = ?',
      whereArgs: [groupId, groupId],
    );
  }
}
