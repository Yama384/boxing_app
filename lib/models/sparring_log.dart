import '../app_strings.dart';

enum PartnerLevel { beginner, even, advancedCoach }

String partnerLevelLabel(PartnerLevel level, AppStrings s) {
  switch (level) {
    case PartnerLevel.beginner:
      return s('partnerLevelBeginner');
    case PartnerLevel.even:
      return s('partnerLevelEven');
    case PartnerLevel.advancedCoach:
      return s('partnerLevelAdvancedCoach');
  }
}

/// Strukturierte Sparring-Runden-Daten für eine Trainingseinheit -- nur
/// gesetzt, wenn die Session tatsächlich Sparring-Runden enthielt.
class SparringLog {
  const SparringLog({
    this.rounds,
    this.roundLengthMinutes,
    this.partnerLevels = const [],
    this.submissionsFor = 0,
    this.submissionsAgainst = 0,
    this.takedownsFor = 0,
    this.takedownsAgainst = 0,
    this.significantStrikesFor = 0,
    this.significantStrikesAgainst = 0,
  });

  final int? rounds;
  final int? roundLengthMinutes;
  final List<PartnerLevel> partnerLevels;
  final int submissionsFor;
  final int submissionsAgainst;
  final int takedownsFor;
  final int takedownsAgainst;
  final int significantStrikesFor;
  final int significantStrikesAgainst;

  SparringLog copyWith({
    int? rounds,
    int? roundLengthMinutes,
    List<PartnerLevel>? partnerLevels,
    int? submissionsFor,
    int? submissionsAgainst,
    int? takedownsFor,
    int? takedownsAgainst,
    int? significantStrikesFor,
    int? significantStrikesAgainst,
  }) {
    return SparringLog(
      rounds: rounds ?? this.rounds,
      roundLengthMinutes: roundLengthMinutes ?? this.roundLengthMinutes,
      partnerLevels: partnerLevels ?? this.partnerLevels,
      submissionsFor: submissionsFor ?? this.submissionsFor,
      submissionsAgainst: submissionsAgainst ?? this.submissionsAgainst,
      takedownsFor: takedownsFor ?? this.takedownsFor,
      takedownsAgainst: takedownsAgainst ?? this.takedownsAgainst,
      significantStrikesFor: significantStrikesFor ?? this.significantStrikesFor,
      significantStrikesAgainst: significantStrikesAgainst ?? this.significantStrikesAgainst,
    );
  }

  Map<String, dynamic> toJson() => {
        'rounds': rounds,
        'roundLengthMinutes': roundLengthMinutes,
        'partnerLevels': [for (final level in partnerLevels) level.name],
        'submissionsFor': submissionsFor,
        'submissionsAgainst': submissionsAgainst,
        'takedownsFor': takedownsFor,
        'takedownsAgainst': takedownsAgainst,
        'significantStrikesFor': significantStrikesFor,
        'significantStrikesAgainst': significantStrikesAgainst,
      };

  factory SparringLog.fromJson(Map<String, dynamic> json) => SparringLog(
        rounds: json['rounds'] as int?,
        roundLengthMinutes: json['roundLengthMinutes'] as int?,
        partnerLevels: [
          for (final level in json['partnerLevels'] as List<dynamic>? ?? const [])
            PartnerLevel.values.byName(level as String),
        ],
        submissionsFor: json['submissionsFor'] as int? ?? 0,
        submissionsAgainst: json['submissionsAgainst'] as int? ?? 0,
        takedownsFor: json['takedownsFor'] as int? ?? 0,
        takedownsAgainst: json['takedownsAgainst'] as int? ?? 0,
        significantStrikesFor: json['significantStrikesFor'] as int? ?? 0,
        significantStrikesAgainst: json['significantStrikesAgainst'] as int? ?? 0,
      );
}
