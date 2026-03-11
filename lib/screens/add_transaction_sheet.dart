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

      if (categories.isNotEmpty && selectedCategoryId == null) {
        selectedCategoryId = categories.first['id'];
      }
    });
  }

  Future<int?> _showAddCategoryDialog({
    String initialName = '',
    int initialColor = 0xFF2196F3,
    int? categoryId,
  }) async {
    final nameController = TextEditingController(text: initialName);
    int r = (initialColor >> 16) & 0xFF;
    int g = (initialColor >> 8) & 0xFF;
    int b = initialColor & 0xFF;

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nova categoria'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Nome'),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cor'),
                            SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, r, g, b),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildColorSlider('R', r, (value) => setState(() => r = value)),
                  _buildColorSlider('G', g, (value) => setState(() => g = value)),
                  _buildColorSlider('B', b, (value) => setState(() => b = value)),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final navigator = Navigator.of(context);
                final colorValue = (0xFF << 24) | (r << 16) | (g << 8) | b;

                if (categoryId != null) {
                  await DatabaseHelper.instance
                      .updateCategory(categoryId, name, colorValue);
                  navigator.pop(categoryId);
                  return;
                }

                final newId = await DatabaseHelper.instance.insertCategory(
                  name,
                  _type.name,
                  colorValue,
                );
                navigator.pop(newId);
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorSlider(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            label: value.toString(),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(value.toString()),
        ),
      ],
    );
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
                          _type = TransactionType.expense;                        selectedCategoryId = null;                        });

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
                          _type = TransactionType.income;                        selectedCategoryId = null;                        });

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

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: "Categoria",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        ...categories.map((category) {
                          final rawColor = category['color'];
                          final colorValue = rawColor is int
                              ? rawColor
                              : int.tryParse(rawColor?.toString() ?? '')
                                  ?? 0xFF2196F3;

                          final rawId = category['id'];
                          final categoryId = rawId is int
                              ? rawId
                              : int.tryParse(rawId?.toString() ?? '') ?? 0;

                          return DropdownMenuItem<int>(
                            value: categoryId,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(colorValue),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(category['name']),
                              ],
                            ),
                          );
                        }),
                        DropdownMenuItem<int>(
                          value: -1,
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 10),
                              Text('Adicionar categoria'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;

                        if (value == -1) {
                          final newCategoryId = await _showAddCategoryDialog();
                          if (newCategoryId != null) {
                            await loadCategories();
                            setState(() {
                              selectedCategoryId = newCategoryId;
                            });
                          }
                          return;
                        }

                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                  ),
                  if (selectedCategoryId != null)
                    IconButton(
                      icon: Icon(Icons.edit),
                      tooltip: 'Editar categoria',
                      onPressed: () async {
                        final selected = categories.firstWhere(
                          (c) => (c['id'] is int
                              ? c['id']
                              : int.tryParse(c['id']?.toString() ?? '')) ==
                              selectedCategoryId,
                          orElse: () => {},
                        );

                        if (selected.isEmpty) return;

                        final rawColor = selected['color'];
                        final colorValue = rawColor is int
                            ? rawColor
                            : int.tryParse(rawColor?.toString() ?? '') ??
                                0xFF2196F3;
                        final name = selected['name']?.toString() ?? '';

                        final updatedId = await _showAddCategoryDialog(
                          initialName: name,
                          initialColor: colorValue,
                          categoryId: selectedCategoryId,
                        );

                        if (updatedId != null) {
                          await loadCategories();
                          setState(() {
                            selectedCategoryId = updatedId;
                          });
                        }
                      },
                    ),
                ],
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
