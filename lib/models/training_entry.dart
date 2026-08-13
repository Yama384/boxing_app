import '../app_strings.dart';
import 'pain_entry.dart';
import 'sparring_log.dart';

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

/// Feinere Einordnung der Einheit als [TrainingType] (der primär die
/// Disziplin beschreibt) -- steuert im Formular, welche Schritte/Felder
/// überhaupt angezeigt werden (z.B. kein Sparring-Log bei S&C-Sessions).
enum SessionType { techniqueDrilling, sparring, competitionPrep, strengthConditioning, openMat, seminar }

String sessionTypeLabel(SessionType type, AppStrings s) {
  switch (type) {
    case SessionType.techniqueDrilling:
      return s('sessionTypeTechniqueDrilling');
    case SessionType.sparring:
      return s('sessionTypeSparring');
    case SessionType.competitionPrep:
      return s('sessionTypeCompetitionPrep');
    case SessionType.strengthConditioning:
      return s('sessionTypeStrengthConditioning');
    case SessionType.openMat:
      return s('sessionTypeOpenMat');
    case SessionType.seminar:
      return s('sessionTypeSeminar');
  }
}

class TrainingEntry {
  const TrainingEntry({
    required this.id,
    required this.date,
    required this.trainingType,
    required this.intensity,
    required this.rating,
    this.mood,
    this.goal = '',
    this.durationMinutes,
    this.whatWentWell = '',
    this.whatWentBad = '',
    this.improvement = '',
    required this.createdAt,
    required this.updatedAt,
    this.sessionType,
    this.additionalSports = const [],
    this.rpe,
    this.energyLevelPre,
    this.focusLevelPre,
    this.sleepQuality,
    this.painEntries = const [],
    this.techniquesPracticed = const [],
    this.techniqueSuccessRating,
    this.sparringLog,
    this.keyTakeaway,
  });

  final String id;
  final DateTime date;
  final TrainingType trainingType;
  final TrainingIntensity intensity;
  final int rating;
  final Mood? mood;

  /// Trainingsziel für diese Einheit (z.B. "Jab verbessern") -- getrennt von
  /// den langfristigen ImprovementGoal-Objekten.
  final String goal;
  final int? durationMinutes;
  final String whatWentWell;
  final String whatWentBad;
  final String improvement;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Session-Typ laut Kampfsport-Logbuch-Datenmodell -- optional, ältere
  /// Einträge haben hier `null` und werden im Formular wie "alle Schritte
  /// anzeigen" behandelt.
  final SessionType? sessionType;

  /// Sportarten zusätzlich zu [trainingType], z.B. bei Cross-Training-
  /// Sessions (Hauptsportart MMA, zusätzlich BJJ und Wrestling geübt).
  final List<String> additionalSports;

  final int? rpe;
  final int? energyLevelPre;
  final int? focusLevelPre;
  final int? sleepQuality;
  final List<PainEntry> painEntries;
  final List<String> techniquesPracticed;
  final int? techniqueSuccessRating;
  final SparringLog? sparringLog;

  /// Kurzer "Aha-Moment" des Tages, ein Satz.
  final String? keyTakeaway;

  TrainingEntry copyWith({
    DateTime? date,
    TrainingType? trainingType,
    TrainingIntensity? intensity,
    int? rating,
    Mood? mood,
    String? goal,
    int? durationMinutes,
    String? whatWentWell,
    String? whatWentBad,
    String? improvement,
    DateTime? updatedAt,
    SessionType? sessionType,
    List<String>? additionalSports,
    int? rpe,
    int? energyLevelPre,
    int? focusLevelPre,
    int? sleepQuality,
    List<PainEntry>? painEntries,
    List<String>? techniquesPracticed,
    int? techniqueSuccessRating,
    SparringLog? sparringLog,
    String? keyTakeaway,
  }) {
    return TrainingEntry(
      id: id,
      date: date ?? this.date,
      trainingType: trainingType ?? this.trainingType,
      intensity: intensity ?? this.intensity,
      rating: rating ?? this.rating,
      mood: mood ?? this.mood,
      goal: goal ?? this.goal,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      whatWentWell: whatWentWell ?? this.whatWentWell,
      whatWentBad: whatWentBad ?? this.whatWentBad,
      improvement: improvement ?? this.improvement,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionType: sessionType ?? this.sessionType,
      additionalSports: additionalSports ?? this.additionalSports,
      rpe: rpe ?? this.rpe,
      energyLevelPre: energyLevelPre ?? this.energyLevelPre,
      focusLevelPre: focusLevelPre ?? this.focusLevelPre,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      painEntries: painEntries ?? this.painEntries,
      techniquesPracticed: techniquesPracticed ?? this.techniquesPracticed,
      techniqueSuccessRating: techniqueSuccessRating ?? this.techniqueSuccessRating,
      sparringLog: sparringLog ?? this.sparringLog,
      keyTakeaway: keyTakeaway ?? this.keyTakeaway,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'trainingType': trainingType.name,
        'intensity': intensity.name,
        'rating': rating,
        'mood': mood?.name,
        'goal': goal,
        'durationMinutes': durationMinutes,
        'whatWentWell': whatWentWell,
        'whatWentBad': whatWentBad,
        'improvement': improvement,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'sessionType': sessionType?.name,
        'additionalSports': additionalSports,
        'rpe': rpe,
        'energyLevelPre': energyLevelPre,
        'focusLevelPre': focusLevelPre,
        'sleepQuality': sleepQuality,
        'painEntries': [for (final p in painEntries) p.toJson()],
        'techniquesPracticed': techniquesPracticed,
        'techniqueSuccessRating': techniqueSuccessRating,
        'sparringLog': sparringLog?.toJson(),
        'keyTakeaway': keyTakeaway,
      };

  factory TrainingEntry.fromJson(Map<String, dynamic> json) {
    return TrainingEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      trainingType: TrainingType.values.byName(json['trainingType'] as String),
      intensity: TrainingIntensity.values.byName(json['intensity'] as String),
      rating: json['rating'] as int,
      mood: json['mood'] != null ? Mood.values.byName(json['mood'] as String) : null,
      goal: json['goal'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int?,
      whatWentWell: json['whatWentWell'] as String? ?? '',
      whatWentBad: json['whatWentBad'] as String? ?? '',
      improvement: json['improvement'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      sessionType: json['sessionType'] != null ? SessionType.values.byName(json['sessionType'] as String) : null,
      additionalSports: [
        for (final sport in json['additionalSports'] as List<dynamic>? ?? const []) sport as String,
      ],
      rpe: json['rpe'] as int?,
      energyLevelPre: json['energyLevelPre'] as int?,
      focusLevelPre: json['focusLevelPre'] as int?,
      sleepQuality: json['sleepQuality'] as int?,
      painEntries: [
        for (final item in json['painEntries'] as List<dynamic>? ?? const [])
          PainEntry.fromJson(item as Map<String, dynamic>),
      ],
      techniquesPracticed: [
        for (final t in json['techniquesPracticed'] as List<dynamic>? ?? const []) t as String,
      ],
      techniqueSuccessRating: json['techniqueSuccessRating'] as int?,
      sparringLog:
          json['sparringLog'] != null ? SparringLog.fromJson(json['sparringLog'] as Map<String, dynamic>) : null,
      keyTakeaway: json['keyTakeaway'] as String?,
    );
  }
}
