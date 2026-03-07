enum TransactionType { income, expense }

class TransactionModel {
  int? id;
  String name;
  double quantity;
  String description;
  int categoryId;
  DateTime date;
  TransactionType type;
  String? categoryName;

  TransactionModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.description,
    required this.categoryId,
    required this.date,
    required this.type,
    this.categoryName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'description': description,
      'categoryId': categoryId,
      'date': date.toIso8601String(),
      'type': type.name,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      description: map['description'] ?? '',
      categoryId: map['categoryId'],
      date: DateTime.parse(map['date']),
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      categoryName: map['categoryName'], // 👈 MUITO IMPORTANTE
    );
  }
}
