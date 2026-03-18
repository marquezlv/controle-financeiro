import 'package:flutter/material.dart';
import '../../models/organization_model.dart';
import '../../utils/formatters.dart';

/// Card displayed for a single organization (projection) entry.
class OrganizationCard extends StatelessWidget {
  final OrganizationModel org;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  const OrganizationCard({
    super.key,
    required this.org,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        org.color != null ? Color(org.color!) : const Color(0xFF3B82F6);
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
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
              GestureDetector(
                onTap: onDelete,
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
                    const Text('Valor Reservado',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(formatCurrency(reserveValue),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Por mês',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(formatCurrency(monthlyValue),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('Concluir e Registrar Gasto',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
