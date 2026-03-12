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
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await _ensureRequiredColumns(db);
        await _ensureDefaultCategories(db);
      },
    );
  }

  Future<void> _ensureRequiredColumns(Database db) async {
    final txInfo = await db.rawQuery("PRAGMA table_info(transactions)");
    final txCols = txInfo.map((r) => r['name'] as String).toSet();

    if (!txCols.contains('isInstallment')) {
      await db.execute('ALTER TABLE transactions ADD COLUMN isInstallment INTEGER NOT NULL DEFAULT 0');
    }
    if (!txCols.contains('installmentNumber')) {
      await db.execute('ALTER TABLE transactions ADD COLUMN installmentNumber INTEGER');
    }
    if (!txCols.contains('totalInstallments')) {
      await db.execute('ALTER TABLE transactions ADD COLUMN totalInstallments INTEGER');
    }
    if (!txCols.contains('installmentGroupId')) {
      await db.execute('ALTER TABLE transactions ADD COLUMN installmentGroupId TEXT');
    }

    final catInfo = await db.rawQuery("PRAGMA table_info(categories)");
    final catCols = catInfo.map((r) => r['name'] as String).toSet();

    if (!catCols.contains('color')) {
      await db.execute('ALTER TABLE categories ADD COLUMN color INTEGER NOT NULL DEFAULT 0xFF2196F3');
    }

    // Ensure uniqueness so we can safely upsert default categories.
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_name_type ON categories(name, type)',
    );

    final orgInfo = await db.rawQuery("PRAGMA table_info(organizations)");
    final orgCols = orgInfo.map((r) => r['name'] as String).toSet();

    if (!orgCols.contains('installments')) {
      await db.execute('ALTER TABLE organizations ADD COLUMN installments INTEGER NOT NULL DEFAULT 1');
    }
  }

  Future<void> _ensureDefaultCategories(Database db) async {
    // colors chosen to be distinguishable
    final defaults = [
      {'name': 'Mercado', 'type': 'expense', 'color': 0xFF42A5F5},
      {'name': 'Transporte', 'type': 'expense', 'color': 0xFFFFB300},
      {'name': 'Lazer', 'type': 'expense', 'color': 0xFFAB47BC},
      {'name': 'Restaurante', 'type': 'expense', 'color': 0xFFE57373},
      {'name': 'Salário', 'type': 'income', 'color': 0xFF66BB6A},
      {'name': 'Freelance', 'type': 'income', 'color': 0xFF26A69A},
    ];

    for (var cat in defaults) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO categories (name, type, color, hidden) VALUES (?, ?, ?, 0)',
        [cat['name'], cat['type'], cat['color']],
      );
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE organizations ADD COLUMN color INTEGER');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE categories ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE transactions ADD COLUMN isInstallment INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE transactions ADD COLUMN installmentNumber INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN totalInstallments INTEGER');
      await db.execute('ALTER TABLE transactions ADD COLUMN installmentGroupId TEXT');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE categories ADD COLUMN color INTEGER NOT NULL DEFAULT 0xFF2196F3');
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE organizations ADD COLUMN installments INTEGER NOT NULL DEFAULT 1');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    hidden INTEGER NOT NULL DEFAULT 0,
    color INTEGER NOT NULL DEFAULT 0xFF2196F3
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
    isInstallment INTEGER NOT NULL DEFAULT 0,
    installmentNumber INTEGER,
    totalInstallments INTEGER,
    installmentGroupId TEXT,
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
    color INTEGER,
    installments INTEGER NOT NULL DEFAULT 1
  )
  ''');

    // categorias padrão
    await db.insert('categories', {
      'name': 'Mercado',
      'type': 'expense',
      'color': 0xFF2196F3, // azul
    });
    await db.insert('categories', {
      'name': 'Transporte',
      'type': 'expense',
      'color': 0xFFFFC107, // amarelo
    });
    await db.insert('categories', {
      'name': 'Lazer',
      'type': 'expense',
      'color': 0xFF9C27B0, // roxo
    });
    await db.insert('categories', {
      'name': 'Restaurante',
      'type': 'expense',
      'color': 0xFFF44336, // vermelho
    });

    await db.insert('categories', {
      'name': 'Salário',
      'type': 'income',
      'color': 0xFF4CAF50, // verde
    });
    await db.insert('categories', {
      'name': 'Freelance',
      'type': 'income',
      'color': 0xFF009688, // teal
    });
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
