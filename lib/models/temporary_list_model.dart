class TemporaryListModel {
  final int? id;
  final String name;
  final int projectId;
  final DateTime createdAt;

  TemporaryListModel({
    this.id,
    required this.name,
    required this.projectId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'projectId': projectId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TemporaryListModel.fromMap(Map<String, dynamic> map) {
    return TemporaryListModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      projectId: map['projectId'] as int? ?? 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
