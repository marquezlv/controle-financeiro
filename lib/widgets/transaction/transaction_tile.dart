import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String currencyCode;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.currencyCode = 'BRL',
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red : Colors.green;

    String title = transaction.description.isNotEmpty
        ? transaction.description
        : (transaction.categoryName ?? "Categoria");

    if (transaction.isInstallment &&
        transaction.installmentNumber != null &&
        transaction.totalInstallments != null &&
        transaction.totalInstallments! > 1) {
      title =
          "$title [${transaction.installmentNumber}/${transaction.totalInstallments}]";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: transaction.categoryName != null
            ? Text(transaction.categoryName!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatCurrencyForCode(transaction.quantity, currencyCode),
                style:
                    TextStyle(color: color, fontWeight: FontWeight.bold)),
            if (onDelete != null) ...[
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey[700]),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
