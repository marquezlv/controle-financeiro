import 'package:sqflite/sqflite.dart';
import 'database_initializer.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await DatabaseInitializer.initialize('finance.db');
    return _database!;
  }
}
