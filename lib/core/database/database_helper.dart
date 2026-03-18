import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';
import '../../models/organization_model.dart';
import 'database_initializer.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await DatabaseInitializer.initialize('finance.db');
    return _database!;
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransactionGroup(String groupId) async {
    final db = await instance.database;
    return await db.delete('transactions',
        where: 'installmentGroupId = ?', whereArgs: [groupId]);
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;

    final result = await db.rawQuery('''
  SELECT 
    t.*,
    c.name as categoryName,
    c.color as categoryColor
  FROM transactions t
  LEFT JOIN categories c 
  ON c.id = t.categoryId
  ORDER BY t.date DESC
  ''');

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<int> insertOrganization(OrganizationModel organization) async {
    final db = await instance.database;
    return await db.insert('organizations', organization.toMap());
  }

  Future<List<OrganizationModel>> getAllOrganizations() async {
    final db = await database;
    final result = await db.query('organizations', orderBy: 'createdAt DESC');
    return result.map((e) => OrganizationModel.fromMap(e)).toList();
  }

  Future<int> updateOrganization(OrganizationModel organization) async {
    final db = await instance.database;
    return await db.update(
      'organizations',
      organization.toMap(),
      where: 'id = ?',
      whereArgs: [organization.id],
    );
  }

  Future<int> deleteOrganization(int id) async {
    final db = await instance.database;
    return await db.delete('organizations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final db = await database;

    return await db.query(
      'categories',
      where: 'type = ? AND (hidden = 0 OR hidden IS NULL)',
      whereArgs: [type],
    );
  }

  Future<int> insertCategory(String name, String type, int color) async {
    final db = await database;
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

  Future<int> updateCategory(int id, String name, int color) async {
    final db = await database;
    return await db.update(
      'categories',
      {'name': name, 'color': color},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getOrCreateCategory(String name, String type) async {
    final db = await database;

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
