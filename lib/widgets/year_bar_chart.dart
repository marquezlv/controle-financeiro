import 'package:flutter/material.dart';

class YearBarChart extends StatelessWidget {
  final List<double> incomeTotals;
  final List<double> expenseTotals;
  final List<String> monthLabels;
  final String title;

  const YearBarChart({
    super.key,
    required this.incomeTotals,
    required this.expenseTotals,
    required this.monthLabels,
    this.title = 'Resumo anual',
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      ...incomeTotals,
      ...expenseTotals,
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
            title,
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
                        final income = incomeTotals[index];
                        final expense = expenseTotals[index];

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
                                monthLabels[index].substring(0, 3),
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
}
