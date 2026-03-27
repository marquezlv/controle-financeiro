import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/category_service.dart';
import '../../services/project_service.dart';
import '../../services/transaction_service.dart';
import '../../utils/formatters.dart';
import '../../utils/installment_utils.dart';
import 'add_category_sheet.dart';

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
  // ignore: library_private_types_in_public_api
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

  bool _isInstallment = false;
  bool _isRecurring = false;
  int _installments = 2;
  int _startDay = min(DateTime.now().day, 28);
  String _currencyCode = 'BRL';

  static const int _fixedRecurrenceMonths = 12;

  Future<void> _loadCurrency() async {
    final currencyCode = await ProjectService.getActiveCurrencyCode();
    if (!mounted) return;
    setState(() {
      _currencyCode = currencyCode;
      if (widget.transaction != null) {
        _valueController.text = formatCurrencyForCode(
          widget.transaction!.quantity,
          _currencyCode,
        );
      }
    });
  }

  Future<void> loadCategories() async {
    final data = await CategoryService.getByType(_type.name);
    setState(() {
      categories = data;
      if (categories.isNotEmpty && selectedCategoryId == null) {
        selectedCategoryId = categories.first['id'] as int?;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.transaction;
    if (initial != null) {
      final isRecurringEntry = initial.isRecurringEntry;
      final startDate = (!isRecurringEntry && initial.sequenceGroupId != null)
          ? _resolveSequenceStartDate(initial)
          : initial.date;

      _type = initial.type;
      _valueController.text = formatCurrencyForCode(
        initial.quantity,
        _currencyCode,
      );
      _descController.text = initial.description;
      selectedCategoryId = initial.categoryId;
      _selectedDate = startDate;
      _isRecurring = isRecurringEntry;
      _isInstallment = initial.isInstallment && !isRecurringEntry;
      _installments = initial.totalInstallments ?? 1;
      _startDay = min(startDate.day, 28);
    }
    _installmentsController.text = _installments.toString();
    _loadCurrency();
    loadCategories();
  }

  @override
  void dispose() {
    _valueController.dispose();
    _descController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  DateTime _buildSafeDate({
    required int year,
    required int month,
    required int day,
  }) {
    final lastDayOfMonth = DateUtils.getDaysInMonth(year, month);
    return DateTime(year, month, min(day, lastDayOfMonth));
  }

  DateTime _resolveSequenceStartDate(TransactionModel transaction) {
    final sequenceNumber = transaction.sequenceNumber ?? 1;

    if (sequenceNumber <= 1) {
      return transaction.date;
    }

    return addMonths(transaction.date, -(sequenceNumber - 1));
  }

  DateTime _resolveFirstScheduledDate(DateTime date, {int? day}) {
    final today = DateUtils.dateOnly(DateTime.now());
    var scheduledDate = day == null
        ? DateUtils.dateOnly(date)
        : DateTime(date.year, date.month, day);

    while (DateUtils.dateOnly(scheduledDate).isBefore(today)) {
      scheduledDate = addMonths(scheduledDate, 1);
    }

    return scheduledDate;
  }

  String _buildGroupId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}';
  }

  Future<void> _insertInstallmentTransactions({
    required String name,
    required double value,
    required String description,
    required int categoryId,
    required DateTime firstDate,
    required String groupId,
  }) async {
    double? installmentValue;
    double? lastInstallmentValue;

    if (_type == TransactionType.expense) {
      final baseValue = value / _installments;
      installmentValue = double.parse(baseValue.toStringAsFixed(2));
      lastInstallmentValue = double.parse(
        (value - installmentValue * (_installments - 1)).toStringAsFixed(2),
      );
    }

    for (var i = 1; i <= _installments; i++) {
      final installmentDate = addMonths(firstDate, i - 1);
      final amount = _type == TransactionType.expense
          ? (i == _installments ? lastInstallmentValue! : installmentValue!)
          : value;

      await TransactionService.insert(
        TransactionModel(
          name: name,
          quantity: amount,
          description: description,
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
  }

  Future<void> _insertRecurringTransactions({
    required String name,
    required double value,
    required String description,
    required int categoryId,
    required DateTime firstDate,
  }) async {
    final groupId = _buildGroupId();
    for (var i = 1; i <= _fixedRecurrenceMonths; i++) {
      final recurrenceDate = addMonths(firstDate, i - 1);

      await TransactionService.insert(
        TransactionModel(
          name: name,
          quantity: value,
          description: description,
          categoryId: categoryId,
          date: recurrenceDate,
          type: _type,
          isRecurring: true,
          recurrenceNumber: i,
          totalRecurrences: _fixedRecurrenceMonths,
          recurrenceGroupId: groupId,
        ),
      );
    }
  }

  Future<void> _replaceSequence({
    required TransactionModel existing,
    required String name,
    required double value,
    required String description,
    required int categoryId,
  }) async {
    final groupId = existing.sequenceGroupId;

    if (groupId == null) {
      return;
    }

    await TransactionService.deleteGroup(groupId);

    await _insertInstallmentTransactions(
      name: name,
      value: value,
      description: description,
      categoryId: categoryId,
      firstDate: DateTime(_selectedDate.year, _selectedDate.month, _startDay),
      groupId: groupId,
    );
  }

  Future<int?> _showMonthPickerDialog({
    required BuildContext context,
    required ColorScheme colorScheme,
    required int selectedMonth,
  }) async {
    final months = List.generate(12, (index) => index + 1);

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Selecione o mês'),
          content: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: months.map((month) {
                final isSelected = month == selectedMonth;
                return SizedBox(
                  width: 84,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? colorScheme.primary.withAlpha((0.12 * 255).round())
                          : Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                      foregroundColor: isSelected
                          ? colorScheme.primary
                          : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.of(context).pop(month),
                    child: Text(
                      _capitalize(
                        DateFormat.MMM('pt_BR').format(DateTime(2024, month)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Future<int?> _showYearPickerDialog({
    required BuildContext context,
    required DateTime selectedDate,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Selecione o ano'),
          content: SizedBox(
            width: 320,
            height: 320,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              selectedDate: selectedDate,
              currentDate: DateTime.now(),
              onChanged: (date) => Navigator.of(context).pop(date.year),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickTransactionDate() async {
    final theme = Theme.of(context);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _type == TransactionType.expense
          ? Colors.redAccent
          : Colors.green,
      brightness: Brightness.light,
    );

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        var tempSelectedDate = _selectedDate;
        var displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectMonth() async {
              final month = await _showMonthPickerDialog(
                context: context,
                colorScheme: colorScheme,
                selectedMonth: displayedMonth.month,
              );

              if (month == null) return;

              setDialogState(() {
                displayedMonth = DateTime(displayedMonth.year, month);
                tempSelectedDate = _buildSafeDate(
                  year: displayedMonth.year,
                  month: month,
                  day: tempSelectedDate.day,
                );
              });
            }

            Future<void> selectYear() async {
              final year = await _showYearPickerDialog(
                context: context,
                selectedDate: tempSelectedDate,
              );

              if (year == null) return;

              setDialogState(() {
                displayedMonth = DateTime(year, displayedMonth.month);
                tempSelectedDate = _buildSafeDate(
                  year: year,
                  month: displayedMonth.month,
                  day: tempSelectedDate.day,
                );
              });
            }

            return Theme(
              data: theme.copyWith(colorScheme: colorScheme),
              child: Dialog(
                backgroundColor: Colors.white,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecione a data',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: selectMonth,
                              icon: const Icon(Icons.calendar_view_month),
                              label: Text(
                                _capitalize(
                                  DateFormat.MMMM(
                                    'pt_BR',
                                  ).format(displayedMonth),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: selectYear,
                              icon: const Icon(Icons.event),
                              label: Text('${displayedMonth.year}'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CalendarDatePicker(
                        key: ValueKey(
                          '${displayedMonth.year}-${displayedMonth.month}',
                        ),
                        initialDate: tempSelectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        currentDate: DateTime.now(),
                        onDateChanged: (date) {
                          setDialogState(() {
                            tempSelectedDate = date;
                            displayedMonth = DateTime(date.year, date.month);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).pop(tempSelectedDate),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_isInstallment) {
          _startDay = min(picked.day, 28);
        }
      });
    }
  }

  Future<void> _save() async {
    if (_valueController.text.isEmpty) return;
    final value = parseCurrencyInput(_valueController.text);
    if (value <= 0) return;

    final name = _descController.text.isEmpty
        ? 'Sem descrição'
        : _descController.text;
    final categoryId = selectedCategoryId ?? 1;
    final baseDate = _selectedDate;

    if (isEditing) {
      final existing = widget.transaction!;

      if (_isInstallment && existing.sequenceGroupId != null) {
        await _replaceSequence(
          existing: existing,
          name: name,
          value: value,
          description: _descController.text,
          categoryId: categoryId,
        );
      } else {
        await TransactionService.update(
          TransactionModel(
            id: existing.id,
            name: name,
            quantity: value,
            description: _descController.text,
            categoryId: categoryId,
            date: baseDate,
            type: _type,
            isInstallment: _isInstallment,
            installmentNumber: _isInstallment
                ? existing.installmentNumber
                : null,
            totalInstallments: _isInstallment
                ? existing.totalInstallments
                : null,
            installmentGroupId: _isInstallment
                ? existing.installmentGroupId
                : null,
            isRecurring: _isRecurring,
            recurrenceNumber: _isRecurring ? existing.recurrenceNumber : null,
            totalRecurrences: _isRecurring
                ? (existing.totalRecurrences ?? _fixedRecurrenceMonths)
                : null,
            recurrenceGroupId: null,
          ),
        );
      }
    } else {
      if (_isInstallment && _installments > 1) {
        await _insertInstallmentTransactions(
          name: name,
          value: value,
          description: _descController.text,
          categoryId: categoryId,
          firstDate: _resolveFirstScheduledDate(baseDate, day: _startDay),
          groupId: _buildGroupId(),
        );
      } else if (_isRecurring) {
        await _insertRecurringTransactions(
          name: name,
          value: value,
          description: _descController.text,
          categoryId: categoryId,
          firstDate: _resolveFirstScheduledDate(baseDate),
        );
      } else {
        await TransactionService.insert(
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
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Editar Transação' : 'Nova Transação',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Type toggle
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
                          selectedCategoryId = null;
                        });
                        loadCategories();
                      },
                      child: const Text(
                        'Gasto',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                          _isInstallment = false;
                          _isRecurring = false;
                          selectedCategoryId = null;
                        });
                        loadCategories();
                      },
                      child: const Text(
                        'Ganho',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(currencyCode: _currencyCode),
                ],
                decoration: const InputDecoration(labelText: 'Valor'),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickTransactionDate,
                      child: Text(
                        'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        ...categories.map((category) {
                          final rawColor = category['color'];
                          final colorValue = rawColor is int
                              ? rawColor
                              : int.tryParse(rawColor?.toString() ?? '') ??
                                    0xFF2196F3;
                          final rawId = category['id'];
                          final catId = rawId is int
                              ? rawId
                              : int.tryParse(rawId?.toString() ?? '') ?? 0;
                          return DropdownMenuItem<int>(
                            value: catId,
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
                                const SizedBox(width: 10),
                                Text(category['name'] as String),
                              ],
                            ),
                          );
                        }),
                        DropdownMenuItem<int>(
                          value: -1,
                          child: Row(
                            children: const [
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
                          final newId = await AddCategorySheet.show(
                            context,
                            type: _type.name,
                          );
                          if (newId != null) {
                            await loadCategories();
                            setState(() => selectedCategoryId = newId);
                          }
                          return;
                        }
                        setState(() => selectedCategoryId = value);
                      },
                    ),
                  ),
                  if (selectedCategoryId != null)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Editar categoria',
                      onPressed: () async {
                        final selected = categories.firstWhere((c) {
                          final id = c['id'] is int
                              ? c['id']
                              : int.tryParse(c['id']?.toString() ?? '');
                          return id == selectedCategoryId;
                        }, orElse: () => {});
                        if (selected.isEmpty) return;

                        final rawColor = selected['color'];
                        final colorValue = rawColor is int
                            ? rawColor
                            : int.tryParse(rawColor?.toString() ?? '') ??
                                  0xFF2196F3;
                        final name = selected['name']?.toString() ?? '';

                        final updatedId = await AddCategorySheet.show(
                          context,
                          initialName: name,
                          initialColor: colorValue,
                          categoryId: selectedCategoryId,
                          type: _type.name,
                        );

                        if (updatedId != null) {
                          await loadCategories();
                          setState(() => selectedCategoryId = updatedId);
                        }
                      },
                    ),
                ],
              ),

              const SizedBox(height: 15),

              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),

              const SizedBox(height: 15),

              if (_type == TransactionType.expense) ...[
                CheckboxListTile(
                  value: _isInstallment,
                  onChanged: (value) {
                    setState(() {
                      _isInstallment = value ?? false;
                      if (_isInstallment) {
                        _isRecurring = false;
                      }
                    });
                  },
                  title: const Text('Parcelado'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value ?? false;
                      if (_isRecurring) {
                        _isInstallment = false;
                      }
                    });
                  },
                  title: const Text('Recorrente'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ] else ...[
                CheckboxListTile(
                  value: _isRecurring,
                  onChanged: (value) =>
                      setState(() => _isRecurring = value ?? false),
                  title: const Text('Recorrente'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],

              if (_isInstallment) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _installmentsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Meses',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            setState(() => _installments = parsed);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _startDay,
                        decoration: InputDecoration(
                          labelText: 'Dia de início',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: List.generate(28, (i) => i + 1)
                            .map(
                              (day) => DropdownMenuItem<int>(
                                value: day,
                                child: Text(day.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _startDay = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
              ],

              if (_isRecurring) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Serão criadas 12 transações mensais individuais.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 25),
              ],

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _type == TransactionType.expense
                      ? Colors.red
                      : Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _save,
                child: Text(
                  isEditing
                      ? 'Salvar alterações'
                      : (_type == TransactionType.expense
                            ? 'Adicionar Gasto'
                            : 'Adicionar Ganho'),
                  style: const TextStyle(
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
