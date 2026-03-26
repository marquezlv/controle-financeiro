import 'package:sqflite/sqflite.dart';

class TransactionsTable {
  static const table = 'transactions';

  static Future<void> create(Database db) async {
    await db.execute('''
CREATE TABLE $table (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  quantity REAL NOT NULL,
  description TEXT,
  categoryId INTEGER,
  projectId INTEGER NOT NULL DEFAULT 1,
  date TEXT NOT NULL,
  type TEXT NOT NULL,
  isInstallment INTEGER NOT NULL DEFAULT 0,
  installmentNumber INTEGER,
  totalInstallments INTEGER,
  installmentGroupId TEXT,
  isRecurring INTEGER NOT NULL DEFAULT 0,
  recurrenceNumber INTEGER,
  totalRecurrences INTEGER,
  recurrenceGroupId TEXT,
  FOREIGN KEY (categoryId) REFERENCES categories (id),
  FOREIGN KEY (projectId) REFERENCES projects (id)
)
''');
  }
}
