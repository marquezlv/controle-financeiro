import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../utils/formatters.dart';
import '../widgets/expense/expense_category_section.dart';
import '../widgets/month_year_selector.dart';
import '../widgets/shared/amount_card.dart';
import '../widgets/transaction/transaction_tile.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ExpenseScreenState createState() => ExpenseScreenState();
}

class ExpenseScreenState extends State<ExpenseScreen> {
  List<TransactionModel> _transactions = [];
  double _totalExpense = 0;

  Map<String, double> _categoryTotals = {};
  final Map<String, int> _categoryColors = {};

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  final List<String> _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await TransactionService.getAll();

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
      await TransactionService.deleteGroup(transaction.installmentGroupId!);
    } else if (transaction.id != null) {
      await TransactionService.delete(transaction.id!);
    }

    await _loadTransactions();
  }

  void _calculateExpenses() {
    double total = 0;
    final categoryMap = <String, double>{};
    _categoryColors.clear();

    for (var transaction in _transactions) {
      if (transaction.type != TransactionType.expense) continue;
      if (transaction.date.month != _selectedMonth ||
          transaction.date.year != _selectedYear) {
        continue;
      }

      total += transaction.quantity;

      final category = transaction.categoryName ?? 'Outros';
      final colorValue = transaction.categoryColor ?? 0xFF2196F3;

      categoryMap[category] = (categoryMap[category] ?? 0) + transaction.quantity;
      _categoryColors.putIfAbsent(category, () => colorValue);
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
    final grouped = <String, List<TransactionModel>>{};

    for (var transaction in _getFilteredExpenses()) {
      final dateKey =
          '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}';

      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(),
                    const SizedBox(height: 20),
                    _buildTotalExpenseCard(),
                    const SizedBox(height: 25),
                    ExpenseCategorySection(
                      categoryTotals: _categoryTotals,
                      categoryColors: _categoryColors,
                      total: _totalExpense,
                    ),
                    const SizedBox(height: 30),
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF1E4ED8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gastos',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Veja para onde seu dinheiro está indo',
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
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFE53935)],
      ),
    );
  }

  Widget _buildTransactionSection() {
    final grouped = _groupTransactionsByDate();

    if (_getFilteredExpenses().isEmpty) {
      return const Text('Nenhum gasto no período');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final date = entry.key;
        final transactions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
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
