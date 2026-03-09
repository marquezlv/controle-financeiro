import 'dart:math';

import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/transaction_model.dart';

class AddTransactionSheet extends StatefulWidget {
  final VoidCallback? onSaved;

  const AddTransactionSheet({super.key, this.onSaved});

  @override
  _AddTransactionSheetState createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  List<Map<String, dynamic>> categories = [];
  TransactionType _type = TransactionType.expense;
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _installmentsController = TextEditingController();
  int? selectedCategoryId;

  // Parcelamento
  bool _isInstallment = false;
  int _installments = 2;
  int _startDay = min(DateTime.now().day, 28);

  Future<void> loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories(_type.name);

    setState(() {
      categories = data;

      if (categories.isNotEmpty) {
        selectedCategoryId = categories.first['id'];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    loadCategories();
    _installmentsController.text = _installments.toString();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  DateTime _addMonths(DateTime date, int months) {
    final year = date.year + ((date.month - 1 + months) ~/ 12);
    final month = ((date.month - 1 + months) % 12) + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = min(date.day, lastDayOfMonth);
    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  Future<void> _save() async {
    if (_valueController.text.isEmpty) return;

    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    if (value == null) return;

    final name = _descController.text.isEmpty ? 'Sem descrição' : _descController.text;
    final categoryId = selectedCategoryId ?? 1;
    final now = DateTime.now();

    DateTime firstDate = DateTime(now.year, now.month, _startDay);
    if (firstDate.isBefore(now)) {
      firstDate = _addMonths(firstDate, 1);
    }

    if (_isInstallment && _installments > 1) {
      final baseValue = value / _installments;
      final installmentValue = double.parse(baseValue.toStringAsFixed(2));
      final lastInstallmentValue = double.parse(
        (value - installmentValue * (_installments - 1)).toStringAsFixed(2),
      );

      final groupId = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

      for (var i = 1; i <= _installments; i++) {
        final installmentDate = _addMonths(firstDate, i - 1);
        final amount = i == _installments ? lastInstallmentValue : installmentValue;

        await DatabaseHelper.instance.insertTransaction(
          TransactionModel(
            name: name,
            quantity: amount,
            description: _descController.text,
            categoryId: categoryId,
            date: installmentDate,
            type: _type,
            isInstallment: true,
            installmentNumber: i,
            totalInstallments: _installments,
            installmentGroupId: groupId,
          ),
        );
      }
    } else {
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(
          name: name,
          quantity: value,
          description: _descController.text,
          categoryId: categoryId,
          date: now,
          type: _type,
        ),
      );
    }

    if (!mounted) return;

    widget.onSaved?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Nova Transação",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              /// Toggle Tipo
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == TransactionType.expense
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _type = TransactionType.expense;
                        });

                        loadCategories();
                      },
                      child: Text(
                        "Gasto",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == TransactionType.income
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _type = TransactionType.income;
                        });

                        loadCategories();
                      },
                      child: Text(
                        "Ganho",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              TextField(
                controller: _valueController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: "Valor"),
              ),

              SizedBox(height: 15),

              DropdownButtonFormField<int>(
                initialValue: selectedCategoryId,
                decoration: InputDecoration(
                  labelText: "Categoria",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category['id'],
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategoryId = value!;
                  });
                },
              ),

              SizedBox(height: 15),

              TextField(
                controller: _descController,
                decoration: InputDecoration(labelText: "Descrição"),
              ),

              SizedBox(height: 15),

              CheckboxListTile(
                value: _isInstallment,
                onChanged: (value) {
                  setState(() {
                    _isInstallment = value ?? false;
                  });
                },
                title: Text('Parcelado'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

              if (_isInstallment) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _installmentsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Meses",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            setState(() {
                              _installments = parsed;
                            });
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _startDay,
                        decoration: InputDecoration(
                          labelText: "Dia de início",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: List.generate(28, (index) => index + 1)
                            .map((day) => DropdownMenuItem<int>(
                                  value: day,
                                  child: Text(day.toString()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _startDay = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 25),
              ],

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == TransactionType.expense
                      ? Colors.red
                      : Colors.green,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: _save,
                child: Text(
                  _type == TransactionType.expense
                      ? "Adicionar Gasto"
                      : "Adicionar Ganho",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
