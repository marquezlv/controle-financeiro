import 'package:sqflite/sqflite.dart';

class MigrationV5 {
  static Future<void> run(Database db) async {
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN isInstallment INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN installmentNumber INTEGER',
    );
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN totalInstallments INTEGER',
    );
    await db.execute(
      'ALTER TABLE transactions ADD COLUMN installmentGroupId TEXT',
    );
  }
}
