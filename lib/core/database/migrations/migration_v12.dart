import 'package:sqflite/sqflite.dart';

class MigrationV12 {
  static Future<void> run(Database db) async {
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
}
