import 'dart:math';

import 'package:flutter/material.dart';
import '../models/organization_model.dart';
import '../models/transaction_model.dart';
import '../services/category_service.dart';
import '../services/organization_service.dart';
import '../services/transaction_service.dart';
import '../utils/formatters.dart';
import '../utils/installment_utils.dart';
import '../widgets/organization/create_organization_modal.dart';
import '../widgets/organization/organization_card.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
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

  Future<void> _loadData() async {
    await _loadTransactions();
    await _loadOrganizations();
  }

  Future<void> _loadTransactions() async {
    final data = await TransactionService.getAll();
    setState(() {
      _transactions = data;
    });
    _calculateBalance();
  }

  Future<void> _loadOrganizations() async {
    final data = await OrganizationService.getAll();
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

  Future<void> _completeAndRegisterExpense(OrganizationModel org) async {
    final categoryId = await CategoryService.getOrCreate(
      org.name,
      TransactionType.expense.name,
    );

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
        final installmentDate = addMonths(now, i - 1);
        final amount =
            i == totalInstallments ? lastInstallmentValue : installmentValue;

        await TransactionService.insert(
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
      await TransactionService.insert(
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
      await OrganizationService.delete(org.id!);
    }

    await _loadData();
  }

  Future<void> _deleteOrganization(int id) async {
    await OrganizationService.delete(id);
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
                      (org) => OrganizationCard(
                        org: org,
                        onDelete: () {
                          if (org.id != null) {
                            _deleteOrganization(org.id!);
                          }
                        },
                        onComplete: () => _completeAndRegisterExpense(org),
                      ),
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
      onTap: () {
        CreateOrganizationModal.show(
          context,
          onCreated: () {
            _loadOrganizations();
          },
        );
      },
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
}
