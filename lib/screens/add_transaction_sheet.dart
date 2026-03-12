import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/database/database_helper.dart';
import '../models/transaction_model.dart';
import '../widgets/color_picker.dart';

class AddTransactionSheet extends StatefulWidget {
  final VoidCallback? onSaved;
  final ScrollController? scrollController;
  final TransactionModel? transaction;

  const AddTransactionSheet({
    super.key,
    this.onSaved,
    this.scrollController,
    this.transaction,
  });

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
  DateTime _selectedDate = DateTime.now();

  bool get isEditing => widget.transaction != null;

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
    final hexController = TextEditingController(
      text: '#${initialColor.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );

    int selectedColor = initialColor;


    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            categoryId != null ? 'Editar categoria' : 'Nova categoria',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(labelText: 'Nome'),
                          ),
                          SizedBox(height: 14),
                          ColorPicker(
                            color: Color(selectedColor),
                            onColorChanged: (color) {
                              setState(() {
                                selectedColor = color.toARGB32();
                                final hex = color.toARGB32()
                                    .toRadixString(16)
                                    .padLeft(8, '0')
                                    .substring(2)
                                    .toUpperCase();
                                hexController.text = '#$hex';
                              });
                            },
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: hexController,
                            decoration: InputDecoration(
                              labelText: 'Hex',
                              prefixText: '',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final hex = value.replaceAll('#', '').trim();
                              if (hex.length == 6) {
                                final parsed = int.tryParse(hex, radix: 16);
                                if (parsed != null) {
                                  setState(() {
                                    selectedColor = 0xFF000000 | parsed;
                                  });
                                }
                              }
                            },
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(null),
                                child: Text('Cancelar'),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) return;

                                  final navigator = Navigator.of(context);
                                  final colorValue = selectedColor;

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
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    final initial = widget.transaction;
    if (initial != null) {
      _type = initial.type;
      _valueController.text = initial.quantity.toStringAsFixed(2);
      _descController.text = initial.description;
      selectedCategoryId = initial.categoryId;
      _selectedDate = initial.date;
      _isInstallment = initial.isInstallment;
      _installments = initial.totalInstallments ?? 1;
      _startDay = min(initial.date.day, 28);
    }

    _installmentsController.text = _installments.toString();
    loadCategories();
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

    final baseDate = _selectedDate;

    if (isEditing) {
      final existing = widget.transaction!;
      final updated = TransactionModel(
        id: existing.id,
        name: name,
        quantity: value,
        description: _descController.text,
        categoryId: categoryId,
        date: baseDate,
        type: _type,
        isInstallment: _isInstallment,
        installmentNumber: existing.installmentNumber,
        totalInstallments: existing.totalInstallments,
        installmentGroupId: existing.installmentGroupId,
      );

      await DatabaseHelper.instance.updateTransaction(updated);
    } else {
      final now = DateTime.now();

      DateTime firstDate = DateTime(baseDate.year, baseDate.month, _startDay);
      if (firstDate.isBefore(now)) {
        firstDate = _addMonths(firstDate, 1);
      }

      if (_isInstallment && _installments > 1) {
        double? installmentValue;
        double? lastInstallmentValue;

        if (_type == TransactionType.expense) {
          final baseValue = value / _installments;
          installmentValue = double.parse(baseValue.toStringAsFixed(2));
          lastInstallmentValue = double.parse(
            (value - installmentValue * (_installments - 1)).toStringAsFixed(2),
          );
        }

        final groupId = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';

        for (var i = 1; i <= _installments; i++) {
          final installmentDate = _addMonths(firstDate, i - 1);
          final amount = _type == TransactionType.expense
              ? (i == _installments ? lastInstallmentValue! : installmentValue!)
              : value;

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
            date: baseDate,
            type: _type,
          ),
        );
      }
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
          controller: widget.scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? "Editar Transação" : "Nova Transação",
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
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
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
                title: Text(_type == TransactionType.income ? 'Recorrente' : 'Parcelado'),
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
                  isEditing
                      ? "Salvar alterações"
                      : (_type == TransactionType.expense
                          ? "Adicionar Gasto"
                          : "Adicionar Ganho"),
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
