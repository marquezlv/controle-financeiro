import 'package:flutter/material.dart';

class MonthYearSelector extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final List<String> months;
  final List<int> years;
  final bool disableMonth;
  final ValueChanged<int?>? onMonthChanged;
  final ValueChanged<int?>? onYearChanged;

  const MonthYearSelector({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.months,
    required this.years,
    this.disableMonth = false,
    this.onMonthChanged,
    this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Selecionar Mês", style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                items: List.generate(12, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(months[index]),
                  );
                }),
                onChanged: disableMonth ? null : onMonthChanged,
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
                initialValue: selectedYear,
                items: years
                    .map(
                      (year) => DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      ),
                    )
                    .toList(),
                onChanged: onYearChanged,
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
}
