import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red : Colors.green;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          transaction.categoryName ?? "Categoria",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: transaction.description.isNotEmpty
            ? Text(transaction.description)
            : null,
        trailing: Text(
          formatCurrency(transaction.quantity),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
