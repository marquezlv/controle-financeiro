import 'package:sqflite/sqflite.dart';

class CategoriesTable {
  static const table = 'categories';
  static Future create(Database db) async {
    await db.execute('''
CREATE TABLE $table (
id INTEGER PRIMARY KEY AUTOINCREMENT,
name TEXT NOT NULL,
type TEXT NOT NULL,
hidden INTEGER NOT NULL DEFAULT 0,
color INTEGER NOT NULL DEFAULT 0xFF2196F3
)
''');
  }
}
