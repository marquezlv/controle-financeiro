import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/database/database_helper.dart';
import '../utils/formatters.dart';
import '../widgets/amount_card.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/month_year_selector.dart';
import '../widgets/section_title.dart';
import '../widgets/transaction_tile.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ExpenseScreenState createState() => ExpenseScreenState();
}

class ExpenseScreenState extends State<ExpenseScreen> {
  List<TransactionModel> _transactions = [];
  double _totalExpense = 0;

  Map<String, double> _categoryTotals = {};

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();

    setState(() {
      _transactions = data;
    });

    _calculateExpenses();
  }

  Future<void> reload() async {
    await _loadTransactions();
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    if (transaction.installmentGroupId != null) {
      await DatabaseHelper.instance
          .deleteTransactionGroup(transaction.installmentGroupId!);
    } else if (transaction.id != null) {
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
    }

    await _loadTransactions();
  }

  void _calculateExpenses() {
    double total = 0;

    Map<String, double> categoryMap = {};

    for (var transaction in _transactions) {
      if (transaction.type != TransactionType.expense) continue;

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
      _totalExpense = total;
      _categoryTotals = categoryMap;
    });
  }

  List<TransactionModel> _getFilteredExpenses() {
    return _transactions.where((transaction) {
      return transaction.type == TransactionType.expense &&
          transaction.date.month == _selectedMonth &&
          transaction.date.year == _selectedYear;
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate() {
    Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in _getFilteredExpenses()) {
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

                    _buildTotalExpenseCard(),

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
            "Gastos",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 5),

          Text(
            "Veja para onde seu dinheiro está indo",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return MonthYearSelector(
      selectedMonth: _selectedMonth,
      selectedYear: _selectedYear,
      months: _months,
      minYear: DateTime.now().year,
      maxYear: DateTime.now().year + 1,
      useYearPicker: true,
      onMonthChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedMonth = value;
        });
        _calculateExpenses();
      },
      onYearChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedYear = value;
        });
        _calculateExpenses();
      },
    );
  }

  Widget _buildTotalExpenseCard() {
    return AmountCard(
      title: 'Gasto Total',
      amount: formatCurrency(_totalExpense),
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFE53935)],
      ),
    );
  }

  Widget _buildCategorySection() {
    if (_categoryTotals.isEmpty) {
      return Text("Nenhum gasto no período");
    }

    final entries = _categoryTotals.entries.toList();
    final palette = [
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.green,
      Colors.indigo,
      Colors.yellow.shade700,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: SectionTitle(title: "Gastos por Categoria")),

        SizedBox(height: 20),

        Center(
          child: CategoryPieChart(
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

          double percent = (entry.value / _totalExpense) * 100;

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

    if (_getFilteredExpenses().isEmpty) {
      return Text("Nenhum gasto no período");
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
              return TransactionTile(
                transaction: item,
                onDelete: () => _deleteTransaction(item),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}

