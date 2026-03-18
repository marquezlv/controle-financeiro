import 'package:flutter/material.dart';
import '../../utils/formatters.dart';
import '../category/category_item.dart';
import '../charts/category_pie_chart.dart';
import '../shared/section_title.dart';

class ExpenseCategorySection extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final Map<String, int> categoryColors;
  final double total;

  const ExpenseCategorySection({
    super.key,
    required this.categoryTotals,
    required this.categoryColors,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) return const Text('Nenhum gasto no período');

    final entries = categoryTotals.entries.toList();
    final palette = [
      Colors.red, Colors.orange, Colors.purple, Colors.teal,
      Colors.blue, Colors.green, Colors.indigo, Colors.yellow.shade700,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: SectionTitle(title: 'Gastos por Categoria')),
        const SizedBox(height: 20),
        Center(
          child: CategoryPieChart(
            size: 220,
            values: entries.map((e) => e.value).toList(),
            colors: List.generate(entries.length, (i) {
              final colorValue = categoryColors[entries[i].key];
              return colorValue != null
                  ? Color(colorValue)
                  : palette[i % palette.length];
            }),
            labels: entries.map((e) => e.key).toList(),
            centerText: formatCurrency(total),
          ),
        ),
        const SizedBox(height: 20),
        ...entries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final colorValue = categoryColors[entry.key];
          final color = colorValue != null
              ? Color(colorValue)
              : palette[index % palette.length];
          return CategoryItem(
              category: entry.key, amount: entry.value, color: color);
        }),
      ],
    );
  }
}
