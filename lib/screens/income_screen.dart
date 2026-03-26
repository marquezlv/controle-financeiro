import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/project_service.dart';
import '../services/transaction_service.dart';
import '../utils/formatters.dart';
import '../widgets/shared/amount_card.dart';
import '../widgets/month_year_selector.dart';
import '../widgets/transaction/transaction_tile.dart';
import '../widgets/income/income_category_section.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  IncomeScreenState createState() => IncomeScreenState();
}

class IncomeScreenState extends State<IncomeScreen> {
  List<TransactionModel> _transactions = [];
  double _totalIncome = 0;
  String _currencyCode = 'BRL';

  Map<String, double> _categoryTotals = {};
  final Map<String, int> _categoryColors =
      {}; // store the color for each category name

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Future<void> _loadTransactions() async {
    final data = await TransactionService.getAll();
    final currencyCode = await ProjectService.getActiveCurrencyCode();

    setState(() {
      _transactions = data;
      _currencyCode = currencyCode;
    });

    _calculateIncome();
  }

  Future<void> reload() async {
    await _loadTransactions();
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    if (transaction.sequenceGroupId != null) {
      await TransactionService.deleteGroup(transaction.sequenceGroupId!);
    } else if (transaction.id != null) {
      await TransactionService.delete(transaction.id!);
    }

    await _loadTransactions();
  }

  void _calculateIncome() {
    double total = 0;

    Map<String, double> categoryMap = {};
    _categoryColors.clear();

    for (var transaction in _transactions) {
      if (transaction.type != TransactionType.income) continue;

      if (transaction.date.month == _selectedMonth &&
          transaction.date.year == _selectedYear) {
        total += transaction.quantity;

        String category = transaction.categoryName ?? "Outros";
        final colorValue = transaction.categoryColor ?? 0xFF2196F3;

        if (!categoryMap.containsKey(category)) {
          categoryMap[category] = 0;
          _categoryColors[category] = colorValue;
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

                    IncomeCategorySection(
                      categoryTotals: _categoryTotals,
                      categoryColors: _categoryColors,
                      total: _totalIncome,
                      currencyCode: _currencyCode,
                    ),

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
        _calculateIncome();
      },
      onYearChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedYear = value;
        });
        _calculateIncome();
      },
    );
  }

  Widget _buildTotalIncomeCard() {
    return AmountCard(
      title: 'Ganhos Totais',
      amount: formatCurrencyForCode(_totalIncome, _currencyCode),
      gradient: LinearGradient(colors: [Color(0xFF00C853), Color(0xFF00E676)]),
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
              return TransactionTile(
                transaction: item,
                currencyCode: _currencyCode,
                onDelete: () => _deleteTransaction(item),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}
