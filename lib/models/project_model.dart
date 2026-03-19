class ProjectModel {
  final int? id;
  final String name;
  final String currencyCode;
  final DateTime createdAt;
  final int order;

  ProjectModel({
    this.id,
    required this.name,
    this.currencyCode = 'BRL',
    required this.createdAt,
    this.order = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currencyCode': currencyCode,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'],
      currencyCode: map['currencyCode'] ?? 'BRL',
      createdAt: DateTime.parse(map['createdAt']),
      order: map['order'] ?? 0,
    );
  }

  @override
  String toString() => 'ProjectModel(id: $id, name: $name, currencyCode: $currencyCode)';
}
