import 'improvement_goal.dart';

const Map<SkillArea, List<String>> predefinedSkillKeys = {
  SkillArea.technique: [
    'skillJab',
    'skillCross',
    'skillHook',
    'skillUppercut',
    'skillCombinations',
  ],
  SkillArea.defense: [
    'skillGuard',
    'skillHeadMovement',
    'skillBlocks',
    'skillDistance',
  ],
  SkillArea.footwork: [
    'skillFootwork',
    'skillDistance',
    'skillAngles',
    'skillRingControl',
  ],
  SkillArea.condition: [
    'skillEndurance',
    'skillExplosiveness',
    'skillRecovery',
  ],
  SkillArea.mental: [
    'skillFocus',
    'skillCalm',
    'skillConfidence',
    'skillDiscipline',
  ],
};

class SkillRating {
  const SkillRating({
    required this.area,
    required this.skillKey,
    required this.value,
    required this.date,
  });

  final SkillArea area;
  final String skillKey;
  final double value;
  final DateTime date;

  Map<String, dynamic> toJson() => {
        'area': area.name,
        'skillKey': skillKey,
        'value': value,
        'date': date.toIso8601String(),
      };

  factory SkillRating.fromJson(Map<String, dynamic> json) {
    return SkillRating(
      area: SkillArea.values.byName(json['area'] as String),
      skillKey: json['skillKey'] as String,
      value: (json['value'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }
}
