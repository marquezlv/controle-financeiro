import 'package:sqflite/sqflite.dart';

class MigrationV6 {
  static Future<void> run(Database db) async {
    await db.execute(
      'ALTER TABLE categories ADD COLUMN color INTEGER NOT NULL DEFAULT 0xFF2196F3',
    );
  }
}
