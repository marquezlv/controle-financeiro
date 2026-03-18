import 'package:sqflite/sqflite.dart';

class MigrationV3 {
  static Future<void> run(Database db) async {
    await db.execute('ALTER TABLE organizations ADD COLUMN color INTEGER');
  }
}
