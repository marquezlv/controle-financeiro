import 'package:sqflite/sqflite.dart';

class DatabaseSeed {
  static Future<void> ensureDefaultCategories(Database db) async {
    final defaults = [
      {'name': 'Mercado', 'type': 'expense', 'color': 0xFF42A5F5},
      {'name': 'Transporte', 'type': 'expense', 'color': 0xFFFFB300},
      {'name': 'Lazer', 'type': 'expense', 'color': 0xFFAB47BC},
      {'name': 'Restaurante', 'type': 'expense', 'color': 0xFFE57373},
      {'name': 'Salário', 'type': 'income', 'color': 0xFF66BB6A},
      {'name': 'Freelance', 'type': 'income', 'color': 0xFF26A69A},
    ];

    for (var cat in defaults) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO categories (name, type, color, hidden) VALUES (?, ?, ?, 0)',
        [cat['name'], cat['type'], cat['color']],
      );
    }
  }
}
