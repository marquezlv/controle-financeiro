import '../core/database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static Future<List<TransactionModel>> getAll() =>
      DatabaseHelper.instance.getAllTransactions();

  static Future<int> insert(TransactionModel transaction) =>
      DatabaseHelper.instance.insertTransaction(transaction);

  static Future<int> update(TransactionModel transaction) =>
      DatabaseHelper.instance.updateTransaction(transaction);

  static Future<int> delete(int id) =>
      DatabaseHelper.instance.deleteTransaction(id);

  static Future<int> deleteGroup(String groupId) =>
      DatabaseHelper.instance.deleteTransactionGroup(groupId);
}
