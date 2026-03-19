import 'dart:math';

import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/project_service.dart';
import '../services/transaction_service.dart';
import '../utils/formatters.dart';
import '../widgets/charts/year_bar_chart.dart';
import '../widgets/dialogs/add_transaction_sheet.dart';
import '../widgets/home/home_header.dart';
import '../widgets/month_year_selector.dart';
import '../widgets/shared/amount_card.dart';
import '../widgets/shared/section_title.dart';
import '../widgets/transaction/transaction_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> _transactions = [];
  String _currencyCode = 'BRL';

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;

  bool _showYearView = false;

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

  List<double> _yearIncomeTotals = List.filled(12, 0);
  List<double> _yearExpenseTotals = List.filled(12, 0);

  int get _maxYear {
    final currentYear = DateTime.now().year;
    final maxFromTransactions =
        _transactions.fold<int>(currentYear, (prev, t) => max(prev, t.date.year));
    return max(currentYear, maxFromTransactions);
  }

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final data = await TransactionService.getAll();
    final currencyCode = await ProjectService.getActiveCurrencyCode();

    setState(() {
      _transactions = data;
      _currencyCode = currencyCode;
    });

    _calculateTotals();
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

      if (!_showYearView && isSameYear && transaction.date.month == _selectedMonth) {
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
    final grouped = <String, List<TransactionModel>>{};

    for (var transaction in _getFilteredTransactions()) {
      final dateKey =
          '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}/${transaction.date.year}';

      grouped.putIfAbsent(dateKey, () => []).add(transaction);
    }

    return grouped;
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    if (transaction.installmentGroupId != null) {
      await TransactionService.deleteGroup(transaction.installmentGroupId!);
    } else if (transaction.id != null) {
      await TransactionService.delete(transaction.id!);
    }

    await loadTransactions();
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return AddTransactionSheet(
              scrollController: scrollController,
              transaction: transaction,
              onSaved: () async {
                await loadTransactions();
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              showYearView: _showYearView,
              onMonthTap: () {
                if (_showYearView) {
                  setState(() => _showYearView = false);
                  _calculateTotals();
                }
              },
              onYearTap: () {
                if (!_showYearView) {
                  setState(() => _showYearView = true);
                  _calculateTotals();
                }
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(),
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    const SizedBox(height: 20),
                    _buildIncomeExpenseRow(),
                    if (_showYearView) ...[
                      const SizedBox(height: 20),
                      YearBarChart(
                        incomeTotals: _yearIncomeTotals,
                        expenseTotals: _yearExpenseTotals,
                        monthLabels: _months,
                      ),
                    ],
                    const SizedBox(height: 30),
                    const SectionTitle(title: 'Transações'),
                    const SizedBox(height: 20),
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
      amount: formatCurrencyForCode(_balance, _currencyCode),
      gradient: const LinearGradient(
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
            amount: formatCurrencyForCode(_totalIncome, _currencyCode),
            backgroundColor: Colors.white,
            amountColor: Colors.green,
            amountFontSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AmountCard(
            title: 'Gastos',
            amount: formatCurrencyForCode(_totalExpense, _currencyCode),
            backgroundColor: Colors.white,
            amountColor: Colors.red,
            amountFontSize: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSection() {
    final grouped = _groupTransactionsByDate();

    if (_getFilteredTransactions().isEmpty) {
      return const Center(
        child: Column(
          children: [
            Text(
              'Nenhuma transação ainda',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text(
              'Adicione sua primeira transação',
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
                currencyCode: _currencyCode,
                onTap: () => _editTransaction(item),
                onDelete: () => _deleteTransaction(item),
              );
            }),
          ],
        );
      }).toList(),
    );
  }
}
