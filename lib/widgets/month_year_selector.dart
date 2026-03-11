import 'package:flutter/material.dart';

class MonthYearSelector extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final List<String> months;

  final List<int>? years;

  final int? minYear;
  final int? maxYear;

  final bool useYearPicker;

  final bool disableMonth;
  final bool disableYear;
  final ValueChanged<int?>? onMonthChanged;
  final ValueChanged<int?>? onYearChanged;

  const MonthYearSelector({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.months,
    this.years,
    this.minYear,
    this.maxYear,
    this.useYearPicker = false,
    this.disableMonth = false,
    this.disableYear = false,
    this.onMonthChanged,
    this.onYearChanged,
  });

  List<int> get _computedYears {
    if (years != null) return years!;

    final minY = minYear ?? DateTime.now().year;
    final maxY = maxYear ?? minY;
    if (maxY < minY) return [minY];

    return List.generate(maxY - minY + 1, (index) => minY + index);
  }

  @override
  Widget build(BuildContext context) {
    final yearOptions = _computedYears;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mês", style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              GestureDetector(
                onTap: disableMonth
                    ? null
                    : () async {
                        final pickedMonth = await showDialog<int>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Escolha o mês'),
                              content: SizedBox(
                                width: double.maxFinite,
                                height: 320,
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  children: List.generate(12, (index) {
                                    final month = months[index];
                                    final monthAbbrev = month.length <= 3
                                        ? month
                                        : month.substring(0, 3);
                                    final monthValue = index + 1;
                                    final selected = monthValue == selectedMonth;
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: selected
                                            ? Theme.of(context).colorScheme.primary
                                            : null,
                                        foregroundColor: selected
                                            ? Colors.white
                                            : null,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 8,
                                        ),
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context, monthValue);
                                      },
                                      child: Text(
                                        monthAbbrev,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          },
                        );

                        if (pickedMonth != null) {
                          onMonthChanged?.call(pickedMonth);
                        }
                      },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          months[selectedMonth - 1].length <= 3
                              ? months[selectedMonth - 1]
                              : months[selectedMonth - 1].substring(0, 3),
                          style: TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ano", style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              useYearPicker
                  ? GestureDetector(
                      onTap: disableYear
                          ? null
                          : () async {
                              final pickedYear = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Escolha o ano'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 320,
                                      child: YearPicker(
                                        firstDate: DateTime(yearOptions.first),
                                        lastDate: DateTime(yearOptions.last),
                                        selectedDate: DateTime(selectedYear),
                                        onChanged: (date) {
                                          Navigator.pop(context, date.year);
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );

                              if (pickedYear != null) {
                                onYearChanged?.call(pickedYear);
                              }
                            },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedYear.toString(),
                              style: TextStyle(fontSize: 16),
                            ),
                            Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      items: yearOptions
                          .map(
                            (year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: disableYear ? null : onYearChanged,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
