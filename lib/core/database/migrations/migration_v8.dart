import 'package:sqflite/sqflite.dart';

class MigrationV8 {
  static Future<void> run(Database db) async {
    await db.execute('''
CREATE TABLE organizations_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  quantity REAL NOT NULL,
  description TEXT,
  createdAt TEXT NOT NULL,
  completed INTEGER NOT NULL,
  color INTEGER,
  installments INTEGER
)
''');

    await db.execute('''
INSERT INTO organizations_new (
  id,
  name,
  quantity,
  description,
  createdAt,
  completed,
  color,
  installments
)
SELECT
  id,
  name,
  quantity,
  description,
  createdAt,
  completed,
  color,
  CASE
    WHEN installments IS NULL OR installments <= 1 THEN NULL
    ELSE installments
  END
FROM organizations
''');

    await db.execute('DROP TABLE organizations');
    await db.execute('ALTER TABLE organizations_new RENAME TO organizations');
  }
}
