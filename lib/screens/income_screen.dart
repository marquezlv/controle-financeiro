import 'dart:math';

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/database/database_helper.dart';
import '../utils/formatters.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  IncomeScreenState createState() => IncomeScreenState();
}

class IncomeScreenState extends State<IncomeScreen> {
  List<TransactionModel> _transactions = [];
  double _totalIncome = 0;

  Map<String, double> _categoryTotals = {};

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();

    setState(() {
      _transactions = data;
    });

    _calculateIncome();
  }

  Future<void> reload() async {
    await _loadTransactions();
  }

  void _calculateIncome() {
    double total = 0;

    Map<String, double> categoryMap = {};

    for (var transaction in _transactions) {
      if (transaction.type != TransactionType.income) continue;

      if (transaction.date.month == _selectedMonth &&
          transaction.date.year == _selectedYear) {
        total += transaction.quantity;

        String category = transaction.categoryName ?? "Outros";

        if (!categoryMap.containsKey(category)) {
          categoryMap[category] = 0;
        }

        categoryMap[category] = categoryMap[category]! + transaction.quantity;
      }
    }

    setState(() {
      _totalIncome = total;
      _categoryTotals = categoryMap;
    });
  }

  List<TransactionModel> _getFilteredIncome() {
    return _transactions.where((transaction) {
      return transaction.type == TransactionType.income &&
          transaction.date.month == _selectedMonth &&
          transaction.date.year == _selectedYear;
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate() {
    Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in _getFilteredIncome()) {
      final dateKey =
          "${transaction.date.day.toString().padLeft(2, '0')}/"
          "${transaction.date.month.toString().padLeft(2, '0')}/"
          "${transaction.date.year}";

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  final List<String> _months = [
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F6),

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(),

                    SizedBox(height: 20),

                    _buildTotalIncomeCard(),

                    SizedBox(height: 25),

                    _buildCategorySection(),

                    SizedBox(height: 30),

                    _buildTransactionSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF1E4ED8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ganhos",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 5),

          Text(
            "Veja de onde seu dinheiro está vindo",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Selecionar Mês", style: TextStyle(fontWeight: FontWeight.w500)),

        SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedMonth,
                items: List.generate(12, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(_months[index]),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value!;
                  });

                  _calculateIncome();
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(width: 10),

            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _selectedYear,
                items: [2025, 2026]
                    .map(
                      (year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value!;
                  });
                  _calculateIncome();
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalIncomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ganhos Totais", style: TextStyle(color: Colors.white70)),

          SizedBox(height: 10),

          Text(
            formatCurrency(_totalIncome),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    if (_categoryTotals.isEmpty) {
      return Text("Nenhum ganho no período");
    }

    final entries = _categoryTotals.entries.toList();
    final palette = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.yellow.shade700,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            "Ganhos por Categoria",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        SizedBox(height: 20),

        Center(
          child: _categoryPieChart(
            values: entries.map((e) => e.value).toList(),
            colors: List.generate(entries.length,
                (index) => palette[index % palette.length]),
          ),
        ),

        SizedBox(height: 20),

        ...entries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final color = palette[index % palette.length];

          double percent = (_totalIncome == 0)
              ? 0
              : (entry.value / _totalIncome) * 100;

          return _categoryItem(entry.key, percent, color);
        }),
      ],
    );
  }

  Widget _categoryItem(String category, double percent, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(16),
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
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10),
              Text(category, style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),

          Text(
            "${percent.toStringAsFixed(1)}%",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection() {
    final grouped = _groupTransactionsByDate();

    if (_getFilteredIncome().isEmpty) {
      return Text("Nenhum ganho no período");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final date = entry.key;
        final transactions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),

            SizedBox(height: 10),

            ...transactions.map((item) {
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    item.categoryName ?? "Categoria",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: item.description.isNotEmpty
                      ? Text(item.description)
                      : null,

                  trailing: Text(
                    formatCurrency(item.quantity),
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }).toList(),
    );
  }

  Widget _categoryPieChart({
    required List<double> values,
    required List<Color> colors,
    double size = 160,
  }) {
    final total = values.fold<double>(0, (prev, val) => prev + val);

    if (total == 0) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Text(
          'Sem dados',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PieChartPainter(values: values, colors: colors),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;

    final total = values.fold<double>(0, (prev, val) => prev + val);
    if (total == 0) return;

    double startAngle = -pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
