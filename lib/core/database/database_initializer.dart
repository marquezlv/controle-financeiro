import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'database_migrations.dart';
import 'database_seed.dart';
import 'tables/categories_table.dart';
import 'tables/organization_table.dart';
import 'tables/transactions_table.dart';

class DatabaseInitializer {
  static const int version = 7;

  static Future<Database> initialize(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: version,
      onCreate: _createDB,
      onUpgrade: DatabaseMigrations.upgradeDB,
      onOpen: (db) async {
        await DatabaseMigrations.ensureRequiredColumns(db);
        await DatabaseSeed.ensureDefaultCategories(db);
      },
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await CategoriesTable.create(db);
    await TransactionsTable.create(db);
    await OrganizationsTable.create(db);
    await DatabaseSeed.ensureDefaultCategories(db);
  }
}
