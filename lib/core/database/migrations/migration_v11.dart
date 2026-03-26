import 'package:sqflite/sqflite.dart';

class MigrationV11 {
  static Future<void> run(Database db) async {
    final txInfo = await db.rawQuery("PRAGMA table_info(transactions)");
    final txCols = txInfo.map((row) => row['name'] as String).toSet();

    if (!txCols.contains('isRecurring')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN isRecurring INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!txCols.contains('recurrenceNumber')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN recurrenceNumber INTEGER',
      );
    }
    if (!txCols.contains('totalRecurrences')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN totalRecurrences INTEGER',
      );
    }
    if (!txCols.contains('recurrenceGroupId')) {
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN recurrenceGroupId TEXT',
      );
    }
  }
}
