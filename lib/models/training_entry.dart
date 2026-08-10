enum TrainingType {
  technique,
  sparring,
  boxing,
  muayThai,
  kickboxing,
  mma,
  strength,
  cardio,
  other,
}

enum TrainingIntensity { light, medium, hard, veryHard }

enum Mood { frustrated, neutral, good, motivated, onFire }

class TrainingEntry {
  const TrainingEntry({
    required this.id,
    required this.date,
    required this.trainingType,
    required this.intensity,
    required this.rating,
    this.mood,
    this.whatWentWell = '',
    this.whatWentBad = '',
    this.improvement = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final TrainingType trainingType;
  final TrainingIntensity intensity;
  final int rating;
  final Mood? mood;
  final String whatWentWell;
  final String whatWentBad;
  final String improvement;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainingEntry copyWith({
    DateTime? date,
    TrainingType? trainingType,
    TrainingIntensity? intensity,
    int? rating,
    Mood? mood,
    String? whatWentWell,
    String? whatWentBad,
    String? improvement,
    DateTime? updatedAt,
  }) {
    return TrainingEntry(
      id: id,
      date: date ?? this.date,
      trainingType: trainingType ?? this.trainingType,
      intensity: intensity ?? this.intensity,
      rating: rating ?? this.rating,
      mood: mood ?? this.mood,
      whatWentWell: whatWentWell ?? this.whatWentWell,
      whatWentBad: whatWentBad ?? this.whatWentBad,
      improvement: improvement ?? this.improvement,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'trainingType': trainingType.name,
        'intensity': intensity.name,
        'rating': rating,
        'mood': mood?.name,
        'whatWentWell': whatWentWell,
        'whatWentBad': whatWentBad,
        'improvement': improvement,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TrainingEntry.fromJson(Map<String, dynamic> json) {
    return TrainingEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      trainingType: TrainingType.values.byName(json['trainingType'] as String),
      intensity: TrainingIntensity.values.byName(json['intensity'] as String),
      rating: json['rating'] as int,
      mood: json['mood'] != null ? Mood.values.byName(json['mood'] as String) : null,
      whatWentWell: json['whatWentWell'] as String? ?? '',
      whatWentBad: json['whatWentBad'] as String? ?? '',
      improvement: json['improvement'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
