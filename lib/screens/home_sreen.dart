import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../core/database/database_helper.dart';
import '../utils/formatters.dart';

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

    final yearIncomeTotals = List<double>.filled(12, 0);
    final yearExpenseTotals = List<double>.filled(12, 0);

    for (var transaction in _transactions) {
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

      if (_showYearView) {
        _totalIncome = incomeYear;
        _totalExpense = expenseYear;
        _balance = incomeYear - expenseYear;
      } else {
        _totalIncome = incomeMonth;
        _totalExpense = expenseMonth;
        _balance = incomeMonth - expenseMonth;
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
                      _buildYearChart(),
                    ],
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
            border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                onChanged: _showYearView
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMonth = value!;
                        });

                        _calculateTotals();
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
                items: [2024, 2025, 2026]
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

                  _calculateTotals();
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

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF1E4ED8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Saldo Total", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 10),
          Text(
            formatCurrency(_balance),
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

  Widget _buildIncomeExpenseRow() {
    return Row(
      children: [
        Expanded(
          child: _smallCard(
            "Ganhos",
            formatCurrency(_totalIncome),
            Colors.green,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _smallCard(
            "Gastos",
            formatCurrency(_totalExpense),
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildYearChart() {
    final maxValue = [
      ..._yearIncomeTotals,
      ..._yearExpenseTotals,
    ].fold<double>(0, (prev, val) => val > prev ? val : prev);

    if (maxValue == 0) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            'Sem dados para o ano selecionado',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final availableHeight = MediaQuery.of(context).size.height * 0.25;
    final chartHeight = availableHeight.clamp(160.0, 220.0).toDouble();
    final barMaxHeight = chartHeight - 30;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo anual',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y axis labels
                Container(
                  width: 40,
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        maxValue.toStringAsFixed(0),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        (maxValue * 0.66).toStringAsFixed(0),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        (maxValue * 0.33).toStringAsFixed(0),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        '0',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(12, (index) {
                        final income = _yearIncomeTotals[index];
                        final expense = _yearExpenseTotals[index];

                        final double incomeHeight =
                            maxValue > 0 ? (income / maxValue) * barMaxHeight : 0.0;
                        final double expenseHeight =
                            maxValue > 0 ? (expense / maxValue) * barMaxHeight : 0.0;

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 10,
                                    height: incomeHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Container(
                                    width: 10,
                                    height: expenseHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                _months[index].substring(0, 3),
                                style: TextStyle(fontSize: 10, color: Colors.black87),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection() {
    final grouped = _groupTransactionsByDate();

    if (_getFilteredTransactions().isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transações",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Center(
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
          ),
        ],
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
                      color: item.type == TransactionType.expense
                          ? Colors.red
                          : Colors.green,
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
}
