enum CategoryType { income, expense }

class CategoryModel {
  final int? id;
  final String name;
  final CategoryType type;
  final int order;

  CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'orderIndex': order,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'] == 'income'
          ? CategoryType.income
          : CategoryType.expense,
      order: map['orderIndex'],
    );
  }
}