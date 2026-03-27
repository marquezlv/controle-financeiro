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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Container(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: categoryTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (sequenceLabel != null) ...[
                          const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        formatCurrencyForCode(
                          transaction.quantity,
                          currencyCode,
                        ),
                        style: TextStyle(
                          height: 1.2,
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.grey[700],
                          ),
                          onPressed: onDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (detailText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  detailText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
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

    return '[$sequenceNumber/$sequenceTotal]';
  }
}
