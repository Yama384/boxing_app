enum GoalRatingValue { none, partial, good, great }

class GoalRating {
  const GoalRating({
    required this.goalId,
    required this.date,
    required this.rating,
    this.note = '',
  });

  final String goalId;
  final DateTime date;
  final GoalRatingValue rating;
  final String note;

  Map<String, dynamic> toJson() => {
        'goalId': goalId,
        'date': date.toIso8601String(),
        'rating': rating.name,
        'note': note,
      };

  factory GoalRating.fromJson(Map<String, dynamic> json) {
    return GoalRating(
      goalId: json['goalId'] as String,
      date: DateTime.parse(json['date'] as String),
      rating: GoalRatingValue.values.byName(json['rating'] as String),
      note: json['note'] as String? ?? '',
    );
  }
}

String goalRatingEmoji(GoalRatingValue value) {
  switch (value) {
    case GoalRatingValue.none:
      return '😞';
    case GoalRatingValue.partial:
      return '😐';
    case GoalRatingValue.good:
      return '🙂';
    case GoalRatingValue.great:
      return '🔥';
  }
}
