import 'package:sqflite/sqflite.dart';

class MigrationV7 {
  static Future<void> run(Database db) async {
    await db.execute(
      'ALTER TABLE organizations ADD COLUMN installments INTEGER NOT NULL DEFAULT 1',
    );
  }
}
