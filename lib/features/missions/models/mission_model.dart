class MissionModel {
  MissionModel({
    required this.id,
    required this.title,
    required this.icon,
    this.xpReward = 15,
    this.isCustom = false,
    this.isCompleted = false,
    this.completedAt,
  });

  final String id;
  final String title;
  final String icon;
  final int xpReward;
  final bool isCustom;
  bool isCompleted;
  DateTime? completedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon,
        'xpReward': xpReward,
        'isCustom': isCustom,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory MissionModel.fromMap(Map<String, dynamic> map) => MissionModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        icon: map['icon'] as String? ?? '✅',
        xpReward: (map['xpReward'] as num?)?.toInt() ?? 15,
        isCustom: map['isCustom'] as bool? ?? false,
        isCompleted: map['isCompleted'] as bool? ?? false,
        completedAt: map['completedAt'] != null
            ? DateTime.tryParse(map['completedAt'] as String)
            : null,
      );
}
