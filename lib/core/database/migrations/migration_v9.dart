import 'package:sqflite/sqflite.dart';

class MigrationV9 {
  static Future<void> run(Database db) async {
    // Create projects table
    await db.execute('''
CREATE TABLE projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  currencyCode TEXT NOT NULL DEFAULT 'BRL',
  createdAt TEXT NOT NULL,
  "order" INTEGER NOT NULL DEFAULT 0
)
''');

    // Insert default project
    await db.execute('''
INSERT INTO projects (name, currencyCode, createdAt, "order")
VALUES ('Meu Orçamento', 'BRL', datetime('now'), 0)
''');

    // Create new transactions table with projectId FK
    await db.execute('''
CREATE TABLE transactions_new (
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
  FOREIGN KEY (categoryId) REFERENCES categories (id),
  FOREIGN KEY (projectId) REFERENCES projects (id)
)
''');

    // Copy existing transactions to new table, assigning them to default project (id=1)
    await db.execute('''
INSERT INTO transactions_new (
  id,
  name,
  quantity,
  description,
  categoryId,
  projectId,
  date,
  type,
  isInstallment,
  installmentNumber,
  totalInstallments,
  installmentGroupId
)
SELECT
  id,
  name,
  quantity,
  description,
  categoryId,
  1,
  date,
  type,
  isInstallment,
  installmentNumber,
  totalInstallments,
  installmentGroupId
FROM transactions
''');

    // Drop old transactions table and rename new one
    await db.execute('DROP TABLE transactions');
    await db.execute('ALTER TABLE transactions_new RENAME TO transactions');
  }
}
