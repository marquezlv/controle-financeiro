import 'dart:math';

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/database/database_helper.dart';
import '../utils/formatters.dart';
import '../widgets/amount_card.dart';
import '../widgets/month_year_selector.dart';
import '../widgets/section_title.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/year_bar_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  bool _showYearView = false;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

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

  int get _maxYear {
    final currentYear = DateTime.now().year;
    final maxFromTransactions = _transactions.fold<int>(
      currentYear,
      (prev, t) => max(prev, t.date.year),
    );
    return max(currentYear, maxFromTransactions);
  }

  List<double> _yearIncomeTotals = List.filled(12, 0);
  List<double> _yearExpenseTotals = List.filled(12, 0);

  List<TransactionModel> _getFilteredTransactions() {
    if (_showYearView) {
      return _transactions.where((transaction) {
        return transaction.date.year == _selectedYear;
      }).toList();
    }

    return _transactions.where((transaction) {
      return transaction.date.month == _selectedMonth &&
          transaction.date.year == _selectedYear;
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupTransactionsByDate() {
    Map<String, List<TransactionModel>> grouped = {};

    for (var transaction in _getFilteredTransactions()) {
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

  void _calculateTotals() {
    double incomeMonth = 0;
    double expenseMonth = 0;

    double incomeYear = 0;
    double expenseYear = 0;

    double balanceIncome = 0;
    double balanceExpense = 0;

    final yearIncomeTotals = List<double>.filled(12, 0);
    final yearExpenseTotals = List<double>.filled(12, 0);

    final now = DateTime.now();

    for (var transaction in _transactions) {
      final isPastOrToday = !transaction.date.isAfter(now);
      if (isPastOrToday) {
        if (transaction.type == TransactionType.income) {
          balanceIncome += transaction.quantity;
        } else {
          balanceExpense += transaction.quantity;
        }
      }

      final isSameYear = transaction.date.year == _selectedYear;
      if (isSameYear) {
        final monthIndex = transaction.date.month - 1;

        if (transaction.type == TransactionType.income) {
          incomeYear += transaction.quantity;
          yearIncomeTotals[monthIndex] += transaction.quantity;
        } else {
          expenseYear += transaction.quantity;
          yearExpenseTotals[monthIndex] += transaction.quantity;
        }
      }

      if (!_showYearView && isSameYear &&
          transaction.date.month == _selectedMonth) {
        if (transaction.type == TransactionType.income) {
          incomeMonth += transaction.quantity;
        } else {
          expenseMonth += transaction.quantity;
        }
      }
    }

    setState(() {
      _yearIncomeTotals = yearIncomeTotals;
      _yearExpenseTotals = yearExpenseTotals;
      _balance = balanceIncome - balanceExpense;

      if (_showYearView) {
        _totalIncome = incomeYear;
        _totalExpense = expenseYear;
      } else {
        _totalIncome = incomeMonth;
        _totalExpense = expenseMonth;
      }
    });
  }

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();

    setState(() {
      _transactions = data;
    });

    _calculateTotals();
  }

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  List<TransactionModel> _transactions = [];
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
                    _buildBalanceCard(),
                    SizedBox(height: 20),
                    _buildIncomeExpenseRow(),
                    if (_showYearView) ...[
                      SizedBox(height: 20),
                      YearBarChart(
                        incomeTotals: _yearIncomeTotals,
                        expenseTotals: _yearExpenseTotals,
                        monthLabels: _months,
                      ),
                    ],
                    SizedBox(height: 30),
                    SectionTitle(title: 'Transações'),
                    SizedBox(height: 20),
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
            'Minhas Finanças',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Controle seus gastos e ganhos',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderModeButton(
                label: 'Mês',
                selected: !_showYearView,
                onTap: () {
                  if (_showYearView) {
                    setState(() => _showYearView = false);
                    _calculateTotals();
                  }
                },
              ),
              SizedBox(width: 10),
              _buildHeaderModeButton(
                label: 'Ano',
                selected: _showYearView,
                onTap: () {
                  if (!_showYearView) {
                    setState(() => _showYearView = true);
                    _calculateTotals();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final backgroundColor = selected ? Colors.white : Colors.transparent;
    final textColor = selected ? Colors.blue : Colors.white;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 76)),

          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return MonthYearSelector(
      selectedMonth: _selectedMonth,
      selectedYear: _selectedYear,
      months: _months,
      minYear: DateTime.now().year,
      maxYear: _maxYear,
      useYearPicker: true,
      disableMonth: _showYearView,
      onMonthChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedMonth = value;
        });
        _calculateTotals();
      },
      onYearChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedYear = value;
        });
        _calculateTotals();
      },
    );
  }

  Widget _buildBalanceCard() {
    return AmountCard(
      title: 'Saldo Total',
      amount: formatCurrency(_balance),
      gradient: LinearGradient(
        colors: [Color(0xFF2F6BFF), Color(0xFF1E4ED8)],
      ),
    );
  }

  Widget _buildIncomeExpenseRow() {
    return Row(
      children: [
        Expanded(
          child: AmountCard(
            title: 'Ganhos',
            amount: formatCurrency(_totalIncome),
            backgroundColor: Colors.white,
            amountColor: Colors.green,
            amountFontSize: 20,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: AmountCard(
            title: 'Gastos',
            amount: formatCurrency(_totalExpense),
            backgroundColor: Colors.white,
            amountColor: Colors.red,
            amountFontSize: 20,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    if (transaction.installmentGroupId != null) {
      await DatabaseHelper.instance
          .deleteTransactionGroup(transaction.installmentGroupId!);
    } else if (transaction.id != null) {
      await DatabaseHelper.instance.deleteTransaction(transaction.id!);
    }

    await loadTransactions();
  }

  Widget _buildTransactionSection() {
    final grouped = _groupTransactionsByDate();

    if (_getFilteredTransactions().isEmpty) {
      return Center(
        child: Column(
          children: [
            Text(
              "Nenhuma transação ainda",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text(
              "Adicione sua primeira transação",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
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
