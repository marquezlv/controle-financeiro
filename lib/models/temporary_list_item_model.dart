class TemporaryListItemModel {
  final int? id;
  final int listId;
  final String name;
  final bool completed;
  final DateTime createdAt;

  TemporaryListItemModel({
    this.id,
    required this.listId,
    required this.name,
    required this.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'name': name,
      'completed': completed ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TemporaryListItemModel.fromMap(Map<String, dynamic> map) {
    return TemporaryListItemModel(
      id: map['id'] as int?,
      listId: map['listId'] as int,
      name: map['name'] as String? ?? '',
      completed: (map['completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
