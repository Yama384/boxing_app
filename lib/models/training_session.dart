import '../app_strings.dart';

enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

const List<String> predefinedCategoryKeys = [
  'categoryStrength',
  'categoryBoxing',
  'categorySparring',
  'categoryCardio',
  'categoryTechnique',
  'categoryRest',
];

String weekdayLabel(Weekday day, AppStrings s) {
  switch (day) {
    case Weekday.monday:
      return s('weekdayMonday');
    case Weekday.tuesday:
      return s('weekdayTuesday');
    case Weekday.wednesday:
      return s('weekdayWednesday');
    case Weekday.thursday:
      return s('weekdayThursday');
    case Weekday.friday:
      return s('weekdayFriday');
    case Weekday.saturday:
      return s('weekdaySaturday');
    case Weekday.sunday:
      return s('weekdaySunday');
  }
}

class TrainingSession {
  const TrainingSession({this.categoryKey, this.customCategory})
      : assert(categoryKey != null || customCategory != null);

  final String? categoryKey;
  final String? customCategory;

  bool get isRest => categoryKey == 'categoryRest';

  String displayCategory(AppStrings s) => customCategory ?? s(categoryKey!);

  Map<String, dynamic> toJson() => {
        'categoryKey': categoryKey,
        'customCategory': customCategory,
      };

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
        categoryKey: json['categoryKey'] as String?,
        customCategory: json['customCategory'] as String?,
      );
}
