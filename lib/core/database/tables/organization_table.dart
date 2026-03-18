import 'package:sqflite/sqflite.dart';

class OrganizationsTable {
  static const table = 'organizations';

  static Future<void> create(Database db) async {
    await db.execute('''
CREATE TABLE $table (
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
  }
}
