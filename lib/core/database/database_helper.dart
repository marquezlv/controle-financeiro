import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/transaction_model.dart';
import '../../models/organization_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE organizations ADD COLUMN color INTEGER');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE categories ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    hidden INTEGER NOT NULL DEFAULT 0
  )
  ''');

    await db.execute('''
  CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    quantity REAL NOT NULL,
    description TEXT,
    categoryId INTEGER,
    date TEXT NOT NULL,
    type TEXT NOT NULL,
    FOREIGN KEY (categoryId) REFERENCES categories (id)
  )
  ''');

    await db.execute('''
  CREATE TABLE organizations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    quantity REAL NOT NULL,
    description TEXT,
    createdAt TEXT NOT NULL,
    completed INTEGER NOT NULL,
    color INTEGER
  )
  ''');

    // categorias padrão
    await db.insert('categories', {'name': 'Mercado', 'type': 'expense'});
    await db.insert('categories', {'name': 'Transporte', 'type': 'expense'});
    await db.insert('categories', {'name': 'Lazer', 'type': 'expense'});
    await db.insert('categories', {'name': 'Restaurante', 'type': 'expense'});

    await db.insert('categories', {'name': 'Salário', 'type': 'income'});
    await db.insert('categories', {'name': 'Freelance', 'type': 'income'});
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;

    final result = await db.rawQuery('''
  SELECT 
    t.*,
    c.name as categoryName
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
