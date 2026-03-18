import 'package:sqflite/sqflite.dart';

class MigrationV4 {
  static Future<void> run(Database db) async {
    await db.execute(
      'ALTER TABLE categories ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0',
    );
  }
}
