import 'package:sqflite/sqflite.dart';

import 'migrations/migration_v3.dart';
import 'migrations/migration_v4.dart';
import 'migrations/migration_v5.dart';
import 'migrations/migration_v6.dart';
import 'migrations/migration_v7.dart';
import 'migrations/migration_v8.dart';
import 'migrations/migration_v9.dart';
import 'migrations/migration_v10.dart';
import 'migrations/migration_v11.dart';
import 'migrations/migration_v12.dart';

class DatabaseMigrations {
  static Future<void> ensureRequiredColumns(Database db) async {
    final txInfo = await db.rawQuery("PRAGMA table_info(transactions)");
    final txCols = txInfo.map((r) => r['name'] as String).toSet();

    if (!txCols.contains('isInstallment')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN isInstallment INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!txCols.contains('installmentNumber')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN installmentNumber INTEGER',
      );
    }
    if (!txCols.contains('totalInstallments')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN totalInstallments INTEGER',
      );
    }
    if (!txCols.contains('installmentGroupId')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN installmentGroupId TEXT',
      );
    }
    if (!txCols.contains('isRecurring')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN isRecurring INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!txCols.contains('recurrenceNumber')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN recurrenceNumber INTEGER',
      );
    }
    if (!txCols.contains('totalRecurrences')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN totalRecurrences INTEGER',
      );
    }
    if (!txCols.contains('recurrenceGroupId')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN recurrenceGroupId TEXT',
      );
    }

    final catInfo = await db.rawQuery("PRAGMA table_info(categories)");
    final catCols = catInfo.map((r) => r['name'] as String).toSet();

    if (!catCols.contains('color')) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN color INTEGER NOT NULL DEFAULT 0xFF2196F3',
      );
    }

    // Ensure uniqueness so we can safely upsert default categories.
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_categories_name_type ON categories(name, type)',
    );

    final orgInfo = await db.rawQuery("PRAGMA table_info(organizations)");
    final orgCols = orgInfo.map((r) => r['name'] as String).toSet();

    if (!orgCols.contains('installments')) {
      await db.execute(
        'ALTER TABLE organizations ADD COLUMN installments INTEGER',
      );
    }

    final txProjInfo = await db.rawQuery("PRAGMA table_info(transactions)");
    final txProjCols = txProjInfo.map((r) => r['name'] as String).toSet();

    if (!txProjCols.contains('projectId')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN projectId INTEGER NOT NULL DEFAULT 1',
      );
      // Ensure projects table exists with default project
      final projectInfo = await db.rawQuery("PRAGMA table_info(projects)");
      if (projectInfo.isEmpty) {
        await db.execute('''CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          currencyCode TEXT NOT NULL DEFAULT 'BRL',
          createdAt TEXT NOT NULL,
          "order" INTEGER NOT NULL DEFAULT 0
        )''');
        await db.execute(
          '''INSERT INTO projects (name, currencyCode, createdAt, "order")
          VALUES ('Meu Orçamento', 'BRL', datetime('now'), 0)''',
        );
      }
    }

    await db.execute('''
CREATE TABLE IF NOT EXISTS lists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  projectId INTEGER NOT NULL DEFAULT 1,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (projectId) REFERENCES projects (id)
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS list_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  listId INTEGER NOT NULL,
  name TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (listId) REFERENCES lists (id) ON DELETE CASCADE
)
''');
  }

  static Future<void> upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await MigrationV3.run(db);
    }

    if (oldVersion < 4) {
      await MigrationV4.run(db);
    }

    if (oldVersion < 5) {
      await MigrationV5.run(db);
    }

    if (oldVersion < 6) {
      await MigrationV6.run(db);
    }

    if (oldVersion < 7) {
      await MigrationV7.run(db);
    }

    if (oldVersion < 8) {
      await MigrationV8.run(db);
    }

    if (oldVersion < 9) {
      await MigrationV9.run(db);
    }

    if (oldVersion < 10) {
      await MigrationV10.run(db);
    }

    if (oldVersion < 11) {
      await MigrationV11.run(db);
    }

    if (oldVersion < 12) {
      await MigrationV12.run(db);
    }
  }
}
