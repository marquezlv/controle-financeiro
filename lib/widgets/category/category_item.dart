import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

/// Shared category row item used by both ExpenseCategorySection
/// and IncomeCategorySection.
class CategoryItem extends StatelessWidget {
  final String category;
  final double amount;
  final Color color;

  const CategoryItem({
    super.key,
    required this.category,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(category,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            formatCurrency(amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
