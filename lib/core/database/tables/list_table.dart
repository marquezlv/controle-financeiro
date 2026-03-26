import 'package:sqflite/sqflite.dart';

class ListTable {
  static const table = 'lists';
  static const itemTable = 'list_items';

  static Future<void> create(Database db) async {
    await db.execute('''
CREATE TABLE $table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  projectId INTEGER NOT NULL DEFAULT 1,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (projectId) REFERENCES projects (id)
)
''');

    await db.execute('''
CREATE TABLE $itemTable (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  listId INTEGER NOT NULL,
  name TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (listId) REFERENCES $table (id) ON DELETE CASCADE
)
''');
  }
}
