import 'dart:math';

import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/organization_model.dart';
import '../models/transaction_model.dart';
import '../utils/formatters.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  _OrganizationScreenState createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final TextEditingController _installmentsController = TextEditingController(text: '2');

  final List<Color> _palette = const [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFFB923C),
  ];

  List<TransactionModel> _transactions = [];
  List<OrganizationModel> _organizations = [];
  double _currentBalance = 0;
  double _reservedTotal = 0;
  int _maxInstallments = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadTransactions();
    await _loadOrganizations();
  }

  Future<void> _loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();
    setState(() {
      _transactions = data;
    });
    _calculateBalance();
  }

  Future<void> _loadOrganizations() async {
    final data = await DatabaseHelper.instance.getAllOrganizations();
    setState(() {
      _organizations = data;
    });
    _calculateReserved();
  }

  void _calculateBalance() {
    double income = 0;
    double expense = 0;
    int maxInstallments = 1;

    for (var t in _transactions) {
      if (t.type == TransactionType.income) {
        income += t.quantity;
      } else {
        expense += t.quantity;
      }

      if (t.totalInstallments != null && t.totalInstallments! > maxInstallments) {
        maxInstallments = t.totalInstallments!;
      }
    }

    setState(() {
      _currentBalance = income - expense;
      _maxInstallments = maxInstallments;
    });
  }

  void _calculateReserved() {
    double reserved = 0;
    for (var org in _organizations) {
      reserved += org.quantity;
    }

    setState(() {
      _reservedTotal = reserved;
    });
  }

  void _openNewProjectionModal() {
    _nameController.clear();
    _valueController.clear();

    Color selectedColor = _palette.first;
    bool isInstallment = false;
    int installments = 2;
    _installmentsController.text = installments.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return _buildCreateModal(
                selectedColor: selectedColor,
                isInstallment: isInstallment,
                installments: installments,
                onColorChanged: (color) => setModalState(() {
                  selectedColor = color;
                }),
                onInstallmentToggle: (value) => setModalState(() {
                  isInstallment = value;
                }),
                onInstallmentsChanged: (value) => setModalState(() {
                  installments = value;
                  _installmentsController.text = value.toString();
                }),
                onCreate: () => _createProjection(selectedColor, installments),
              );
            },
          ),
        );
      },
    );
  }

  void _createProjection(Color selectedColor, int installments) async {
    final name = _nameController.text.trim();
    final value =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;

    if (name.isEmpty || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e valor válidos.')),
      );
      return;
    }

    final org = OrganizationModel(
      name: name,
      quantity: value,
      description: '',
      createdAt: DateTime.now(),
      completed: false,
      color: selectedColor.toARGB32(),
      installments: installments,
    );

    await DatabaseHelper.instance.insertOrganization(org);

    final categoryId = await DatabaseHelper.instance
        .getOrCreateCategory(name, TransactionType.expense.name);
    await DatabaseHelper.instance
        .updateCategory(categoryId, name, selectedColor.toARGB32());

    if (!mounted) return;
    await _loadOrganizations();
    if (!mounted) return;
    Navigator.of(context).pop();
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

  Future<void> _completeAndRegisterExpense(OrganizationModel org) async {
    final categoryId = await DatabaseHelper.instance
        .getOrCreateCategory(org.name, TransactionType.expense.name);

    final now = DateTime.now();
    final totalInstallments = org.installments > 1 ? org.installments : 1;

    if (totalInstallments > 1) {
      final baseValue = org.quantity / totalInstallments;
      final installmentValue = double.parse(baseValue.toStringAsFixed(2));
      final lastInstallmentValue = double.parse(
        (org.quantity - installmentValue * (totalInstallments - 1))
            .toStringAsFixed(2),
      );
      final groupId = '${now.millisecondsSinceEpoch}-${Random().nextInt(9999)}';

      for (var i = 1; i <= totalInstallments; i++) {
        final installmentDate = _addMonths(now, i - 1);
        final amount =
            i == totalInstallments ? lastInstallmentValue : installmentValue;

        await DatabaseHelper.instance.insertTransaction(
          TransactionModel(
            name: org.name,
            quantity: amount,
            description: org.description,
            categoryId: categoryId,
            date: installmentDate,
            type: TransactionType.expense,
            isInstallment: true,
            installmentNumber: i,
            totalInstallments: totalInstallments,
            installmentGroupId: groupId,
          ),
        );
      }
    } else {
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(
          name: org.name,
          quantity: org.quantity,
          description: org.description,
          categoryId: categoryId,
          date: now,
          type: TransactionType.expense,
        ),
      );
    }

    if (org.id != null) {
      await DatabaseHelper.instance.deleteOrganization(org.id!);
    }

    await _loadData();
  }

  void _deleteOrganization(int id) async {
    await DatabaseHelper.instance.deleteOrganization(id);
    await _loadOrganizations();
  }

  String _formatCurrency(double value) {
    return formatCurrency(value);
  }

  @override
  Widget build(BuildContext context) {
    final afterBalance = _currentBalance - _reservedTotal;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCards(afterBalance),
                    const SizedBox(height: 20),
                    _buildNewProjectionButton(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Projeções'),
                    const SizedBox(height: 12),
                    if (_organizations.isEmpty) _buildEmptyState(),
                    ..._organizations.map(
                      (org) => _buildOrganizationCard(org, afterBalance),
                    ),
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF1E4ED8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Projeção',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Planeje e organize suas metas financeiras',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards(double afterBalance) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBalanceItem(
              title: 'Saldo em $_maxInstallments ${_maxInstallments == 1 ? 'mês' : 'meses'}',
              value: _formatCurrency(_currentBalance),
              valueColor: _currentBalance < 0 ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildBalanceItem(
              title: 'Saldo após',
              value: _formatCurrency(afterBalance),
              valueColor: afterBalance < 0 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem({
    IconData? icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF2F6BFF)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNewProjectionButton() {
    return GestureDetector(
      onTap: _openNewProjectionModal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2F6BFF)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Nova Projeção',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 40),
          Icon(Icons.folder_open, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma projeção criada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Crie uma projeção para planejar seus gastos',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationCard(OrganizationModel org, double afterBalance) {
    final color = org.color != null ? Color(org.color!) : _palette.first;
    final reserveValue = org.quantity;
    final months = org.installments > 1 ? org.installments : 1;
    final monthlyValue = reserveValue / months;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha((0.15 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Criado em ${org.createdAt.day.toString().padLeft(2, '0')}/${org.createdAt.month.toString().padLeft(2, '0')}/${org.createdAt.year}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (org.id != null) {
                    _deleteOrganization(org.id!);
                  }
                },
                child: const Icon(Icons.close, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Valor Reservado',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(reserveValue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Por mês',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(monthlyValue),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _completeAndRegisterExpense(org),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text(
              'Concluir e Registrar Gasto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateModal({
    required Color selectedColor,
    required bool isInstallment,
    required int installments,
    required ValueChanged<Color> onColorChanged,
    required ValueChanged<bool> onInstallmentToggle,
    required ValueChanged<int> onInstallmentsChanged,
    required VoidCallback onCreate,
  }) {
    final previewColor = selectedColor;
    final previewName = _nameController.text.trim().isEmpty
        ? 'Nome da Projeção'
        : _nameController.text.trim();
    final previewValue =
        double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
    final perMonthValue =
        previewValue / (isInstallment && installments > 0 ? installments : 1);

    Widget buildSlider(String label, int value, ValueChanged<int> onChanged) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(label),
          ),
          const SizedBox(width: 6),
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
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(value.toString()),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nova Projeção',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Nome da Projeção'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Viagem, Comprar casa, Carro, etc.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Valor a Reservar'),
              const SizedBox(height: 8),
              TextField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Cor da Categoria'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 12),
              buildSlider('R', selectedColor.red, (value) {
                onColorChanged(Color.fromARGB(255, value, selectedColor.green, selectedColor.blue));
              }),
              buildSlider('G', selectedColor.green, (value) {
                onColorChanged(Color.fromARGB(255, selectedColor.red, value, selectedColor.blue));
              }),
              buildSlider('B', selectedColor.blue, (value) {
                onColorChanged(Color.fromARGB(255, selectedColor.red, selectedColor.green, value));
              }),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: isInstallment,
                onChanged: (value) => onInstallmentToggle(value ?? false),
                title: const Text('Parcelado'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (isInstallment) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _installmentsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Meses',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      onInstallmentsChanged(parsed);
                    }
                  },
                ),
              ],
              const SizedBox(height: 20),
              const Text('Preview'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).round()),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: previewColor.withAlpha((0.2 * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: previewColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                previewName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(previewValue),
                                style: TextStyle(color: previewColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isInstallment) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Por mês: ${_formatCurrency(perMonthValue)}',
                        style: TextStyle(color: previewColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Criar Projeção',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

