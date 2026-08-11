import '../app_strings.dart';

enum BodyZone {
  head,
  neck,
  shoulderLeft,
  shoulderRight,
  elbowLeft,
  elbowRight,
  wristLeft,
  wristRight,
  ribs,
  upperBack,
  lowerBack,
  hipLeft,
  hipRight,
  kneeLeft,
  kneeRight,
  ankleLeft,
  ankleRight,
  footLeft,
  footRight,
  other,
}

String bodyZoneLabel(BodyZone zone, AppStrings s) {
  switch (zone) {
    case BodyZone.head:
      return s('bodyZoneHead');
    case BodyZone.neck:
      return s('bodyZoneNeck');
    case BodyZone.shoulderLeft:
      return s('bodyZoneShoulderLeft');
    case BodyZone.shoulderRight:
      return s('bodyZoneShoulderRight');
    case BodyZone.elbowLeft:
      return s('bodyZoneElbowLeft');
    case BodyZone.elbowRight:
      return s('bodyZoneElbowRight');
    case BodyZone.wristLeft:
      return s('bodyZoneWristLeft');
    case BodyZone.wristRight:
      return s('bodyZoneWristRight');
    case BodyZone.ribs:
      return s('bodyZoneRibs');
    case BodyZone.upperBack:
      return s('bodyZoneUpperBack');
    case BodyZone.lowerBack:
      return s('bodyZoneLowerBack');
    case BodyZone.hipLeft:
      return s('bodyZoneHipLeft');
    case BodyZone.hipRight:
      return s('bodyZoneHipRight');
    case BodyZone.kneeLeft:
      return s('bodyZoneKneeLeft');
    case BodyZone.kneeRight:
      return s('bodyZoneKneeRight');
    case BodyZone.ankleLeft:
      return s('bodyZoneAnkleLeft');
    case BodyZone.ankleRight:
      return s('bodyZoneAnkleRight');
    case BodyZone.footLeft:
      return s('bodyZoneFootLeft');
    case BodyZone.footRight:
      return s('bodyZoneFootRight');
    case BodyZone.other:
      return s('bodyZoneOther');
  }
}

/// Ein gemeldetes Schmerz-/Beschwerdemuster für eine Körperzone in einer
/// Trainingseinheit -- Intensität 1-5, siehe Kampfsport-Logbuch-Datenmodell.
class PainEntry {
  const PainEntry({required this.bodyZone, required this.intensity, this.note = ''});

  final BodyZone bodyZone;
  final int intensity;
  final String note;

  Map<String, dynamic> toJson() => {
        'bodyZone': bodyZone.name,
        'intensity': intensity,
        'note': note,
      };

  factory PainEntry.fromJson(Map<String, dynamic> json) => PainEntry(
        bodyZone: BodyZone.values.byName(json['bodyZone'] as String),
        intensity: json['intensity'] as int,
        note: json['note'] as String? ?? '',
      );
}
