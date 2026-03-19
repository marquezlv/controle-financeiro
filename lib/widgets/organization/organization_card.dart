import 'package:flutter/material.dart';
import '../../models/organization_model.dart';
import '../../utils/formatters.dart';

/// Card displayed for a single organization (projection) entry.
class OrganizationCard extends StatelessWidget {
  final OrganizationModel org;
  final double balanceAfterMonths;
  final String currencyCode;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final VoidCallback? onEdit;

  const OrganizationCard({
    super.key,
    required this.org,
    required this.balanceAfterMonths,
    required this.currencyCode,
    required this.onDelete,
    required this.onComplete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = org.color != null
        ? Color(org.color!)
        : const Color(0xFF3B82F6);
    final reserveValue = org.quantity;
    final isInstallment = (org.installments ?? 0) > 1;
    final months = org.installments ?? 1;
    final monthlyValue = isInstallment
        ? double.parse((reserveValue / months).toStringAsFixed(2))
        : reserveValue;
    final afterPaymentValue = isInstallment
        ? balanceAfterMonths - monthlyValue
        : balanceAfterMonths - reserveValue;
    const titleStyle = TextStyle(
      color: Colors.grey,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
    const valueStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
      height: 1.15,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                            'Criado em '
                            '${org.createdAt.day.toString().padLeft(2, '0')}/'
                            '${org.createdAt.month.toString().padLeft(2, '0')}/'
                            '${org.createdAt.year}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoColumn(
                        title: 'Valor Reservado',
                        value: formatCurrencyForCode(
                          reserveValue,
                          currencyCode,
                        ),
                        titleStyle: titleStyle,
                        valueStyle: valueStyle.copyWith(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoColumn(
                        title: isInstallment ? 'Por mês' : 'Saldo após',
                        value: formatCurrencyForCode(
                          isInstallment ? monthlyValue : afterPaymentValue,
                          currencyCode,
                        ),
                        titleStyle: titleStyle,
                        valueStyle: valueStyle.copyWith(
                          color: isInstallment ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                    if (isInstallment) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoColumn(
                          title: 'Saldo após',
                          value: formatCurrencyForCode(
                            afterPaymentValue,
                            currencyCode,
                          ),
                          titleStyle: titleStyle,
                          valueStyle: valueStyle.copyWith(color: Colors.green),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onComplete,
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
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn({
    required String title,
    required String value,
    required TextStyle titleStyle,
    required TextStyle valueStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: titleStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 20,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: valueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
