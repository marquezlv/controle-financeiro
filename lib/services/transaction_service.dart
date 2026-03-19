import '../core/database/database_helper.dart';
import '../core/project_context.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static Future<List<TransactionModel>> getAll() =>
      getByProject(ProjectContext.getActiveProjectId());

  static Future<List<TransactionModel>> getByProject(int projectId) =>
      DatabaseHelper.instance.getTransactionsByProject(projectId);

  static Future<int> insert(TransactionModel transaction) {
    // Automatically assign to active project if not explicitly set
    if (transaction.projectId == 1) {
      transaction.projectId = ProjectContext.getActiveProjectId();
    }
    return DatabaseHelper.instance.insertTransaction(transaction);
  }

  static Future<int> update(TransactionModel transaction) =>
      DatabaseHelper.instance.updateTransaction(transaction);

  static Future<int> delete(int id) =>
      DatabaseHelper.instance.deleteTransaction(id);

  static Future<int> deleteGroup(String groupId) =>
      DatabaseHelper.instance.deleteTransactionGroup(groupId);
}
