enum TransactionType { income, expense }

class TransactionModel {
  int? id;
  String name;
  double quantity;
  String description;
  int categoryId;
  int projectId; // Project this transaction belongs to
  DateTime date;
  TransactionType type;

  /// Installment metadata
  bool isInstallment;
  int? installmentNumber;
  int? totalInstallments;
  String? installmentGroupId;

  String? categoryName;
  int? categoryColor;

  TransactionModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.description,
    required this.categoryId,
    this.projectId = 1, // Default to project 1 (Meu Orçamento)
    required this.date,
    required this.type,
    this.isInstallment = false,
    this.installmentNumber,
    this.totalInstallments,
    this.installmentGroupId,
    this.categoryName,
    this.categoryColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'description': description,
      'categoryId': categoryId,
      'projectId': projectId,
      'date': date.toIso8601String(),
      'type': type.name,
      'isInstallment': isInstallment ? 1 : 0,
      'installmentNumber': installmentNumber,
      'totalInstallments': totalInstallments,
      'installmentGroupId': installmentGroupId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      description: map['description'] ?? '',
      categoryId: map['categoryId'],
      projectId: map['projectId'] ?? 1,
      date: DateTime.parse(map['date']),
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      isInstallment: (map['isInstallment'] ?? 0) == 1,
      installmentNumber: map['installmentNumber'] as int?,
      totalInstallments: map['totalInstallments'] as int?,
      installmentGroupId: map['installmentGroupId'] as String?,
      categoryName: map['categoryName'], // 👈 MUITO IMPORTANTE
      categoryColor: map['categoryColor'] as int?,
    );
  }
}
