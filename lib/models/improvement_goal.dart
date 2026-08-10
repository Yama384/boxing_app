import '../app_strings.dart';

enum GoalPriority { low, medium, high }

enum GoalStatus { active, paused, completed }

enum SkillArea { technique, defense, footwork, condition, mental }

class ImprovementGoal {
  const ImprovementGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.progress = 0,
    this.status = GoalStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final SkillArea category;
  final GoalPriority priority;
  final int progress;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  ImprovementGoal copyWith({
    String? title,
    String? description,
    SkillArea? category,
    GoalPriority? priority,
    int? progress,
    GoalStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return ImprovementGoal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'progress': progress,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory ImprovementGoal.fromJson(Map<String, dynamic> json) {
    return ImprovementGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: SkillArea.values.byName(json['category'] as String),
      priority: GoalPriority.values.byName(json['priority'] as String),
      progress: json['progress'] as int? ?? 0,
      status: GoalStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

String skillAreaLabel(SkillArea area, AppStrings s) {
  switch (area) {
    case SkillArea.technique:
      return s('skillAreaTechnique');
    case SkillArea.defense:
      return s('skillAreaDefense');
    case SkillArea.footwork:
      return s('skillAreaFootwork');
    case SkillArea.condition:
      return s('skillAreaCondition');
    case SkillArea.mental:
      return s('skillAreaMental');
  }
}

String skillAreaEmoji(SkillArea area) {
  switch (area) {
    case SkillArea.technique:
      return '🥊';
    case SkillArea.defense:
      return '🛡';
    case SkillArea.footwork:
      return '👣';
    case SkillArea.condition:
      return '🫁';
    case SkillArea.mental:
      return '🧠';
  }
}

String goalPriorityLabel(GoalPriority priority, AppStrings s) {
  switch (priority) {
    case GoalPriority.low:
      return s('priorityLow');
    case GoalPriority.medium:
      return s('priorityMedium');
    case GoalPriority.high:
      return s('priorityHigh');
  }
}

String goalStatusLabel(GoalStatus status, AppStrings s) {
  switch (status) {
    case GoalStatus.active:
      return s('statusActive');
    case GoalStatus.paused:
      return s('statusPaused');
    case GoalStatus.completed:
      return s('statusCompleted');
  }
}
