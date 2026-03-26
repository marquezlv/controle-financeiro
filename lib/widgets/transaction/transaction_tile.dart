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
    final amountColor = isExpense ? Colors.red : Colors.green;
    final categoryColor = Color(transaction.categoryColor ?? 0xFF2196F3);
    final categoryBrightness = ThemeData.estimateBrightnessForColor(
      categoryColor,
    );
    final categoryTextColor = categoryBrightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final detailText = _buildDetailText();
    final sequenceLabel = _buildSequenceLabel();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            transaction.categoryName ?? 'Categoria',
                            style: TextStyle(
                              color: categoryTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (sequenceLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              sequenceLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (detailText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        detailText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatCurrencyForCode(transaction.quantity, currencyCode),
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(height: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.delete_outline, color: Colors.grey[700]),
                      onPressed: onDelete,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDetailText() {
    final description = transaction.description.trim();
    if (description.isNotEmpty) {
      return description;
    }

    final fallback = transaction.name.trim();
    if (fallback.isEmpty || fallback == 'Sem descrição') {
      return '';
    }

    if (fallback == (transaction.categoryName ?? '').trim()) {
      return '';
    }

    return fallback;
  }

  String? _buildSequenceLabel() {
    final sequenceNumber = transaction.sequenceNumber;
    final sequenceTotal = transaction.sequenceTotal;

    if (sequenceNumber == null || sequenceTotal == null || sequenceTotal <= 1) {
      return null;
    }

    final prefix = transaction.isRecurringEntry ? 'Rec.' : 'Parc.';
    return '$prefix $sequenceNumber/$sequenceTotal';
  }
}
