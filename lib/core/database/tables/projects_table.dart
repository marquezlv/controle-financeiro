import 'package:sqflite/sqflite.dart';

class ProjectsTable {
  static const table = 'projects';

  static Future<void> create(Database db) async {
    await db.execute('''
CREATE TABLE $table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  currencyCode TEXT NOT NULL DEFAULT 'BRL',
  createdAt TEXT NOT NULL,
  "order" INTEGER NOT NULL DEFAULT 0
)
''');
  }
}
