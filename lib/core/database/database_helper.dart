import 'package:sqflite/sqflite.dart';
import '../../models/transaction_model.dart';
import '../../models/organization_model.dart';
import '../../models/project_model.dart';
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

  Future<List<OrganizationModel>> getOrganizationsByProject(int projectId) async {
    final db = await database;
    final result = await db.query(
      'organizations',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'createdAt DESC',
    );
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

  // Project methods
  Future<int> insertProject(String name, String currencyCode) async {
    final db = await database;
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

  Future<List<ProjectModel>> getAllProjects() async {
    final db = await database;
    final result = await db.query('projects', orderBy: '"order" ASC, createdAt ASC');
    return result.map((e) => ProjectModel.fromMap(e)).toList();
  }

  Future<ProjectModel?> getProjectById(int id) async {
    final db = await database;
    final result = await db.query('projects', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) return null;
    return ProjectModel.fromMap(result.first);
  }

  Future<int> updateProject(int id, String name, String currencyCode) async {
    final db = await database;
    return await db.update(
      'projects',
      {'name': name, 'currencyCode': currencyCode},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getTransactionsByProject(int projectId) async {
    final db = await database;

    final result = await db.rawQuery('''
  SELECT 
    t.*,
    c.name as categoryName,
    c.color as categoryColor
  FROM transactions t
  LEFT JOIN categories c 
  ON c.id = t.categoryId
  WHERE t.projectId = ?
  ORDER BY t.date DESC
  ''', [projectId]);

    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }
}
