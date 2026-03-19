import 'package:sqflite/sqflite.dart';

class MigrationV10 {
  static Future<void> run(Database db) async {
    // Add projectId column to organizations table
    final orgInfo = await db.rawQuery("PRAGMA table_info(organizations)");
    final orgCols = orgInfo.map((r) => r['name'] as String).toSet();

    if (!orgCols.contains('projectId')) {
      await db.execute(
        'ALTER TABLE organizations ADD COLUMN projectId INTEGER NOT NULL DEFAULT 1',
      );
      // Create FK constraint by recreating table (SQLite limitation)
      await db.execute('''
CREATE TABLE organizations_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  quantity REAL NOT NULL,
  description TEXT,
  createdAt TEXT NOT NULL,
  completed INTEGER NOT NULL,
  color INTEGER,
  installments INTEGER,
  projectId INTEGER NOT NULL DEFAULT 1,
  FOREIGN KEY (projectId) REFERENCES projects (id)
)
''');

      // Copy data
      await db.execute('''
INSERT INTO organizations_new
SELECT id, name, quantity, description, createdAt, completed, color, installments, 1
FROM organizations
''');

      // Replace old table
      await db.execute('DROP TABLE organizations');
      await db.execute('ALTER TABLE organizations_new RENAME TO organizations');
    }
  }
}
