class OrganizationModel {
  final int? id;
  final String name;
  final double quantity;
  final String description;
  final DateTime createdAt;
  final bool completed;

  OrganizationModel({
    this.id,
    required this.name,
    required this.quantity,
    required this.description,
    required this.createdAt,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completed': completed ? 1 : 0,
    };
  }

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    return OrganizationModel(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'],
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      completed: map['completed'] == 1,
    );
  }
}